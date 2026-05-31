#!/usr/bin/env bash
# GDM 环境管理脚本 — 对已有部署执行 start/stop/restart/status/logs/destroy
#
# 用法:
#   ./scripts/deploy/manage.sh <COMMAND> [OPTIONS]
#
# 命令:
#   start     启动服务（自动检测是否需要 bootstrap token）
#   stop      停止服务
#   restart   停止再启动
#   status    查看 tmux 会话 + 健康检查
#   logs      查看节点日志（tail -f）
#   destroy   停止服务并清理数据目录
#
# 选项:
#   -d, --dir <DIR>       指定远程部署目录（自动检测最新目录）
#   -m, --mode <MODE>     管理模式: standalone, cluster, all (默认: all)
#   -n, --node <NODE>     仅操作指定节点（如 node1, node2, node3, standalone）
#   --force-clean         start 时强制清理数据（重新 bootstrap）
#   -h, --help            显示帮助信息

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/ssh.sh"
source "${SCRIPT_DIR}/lib/service.sh"
source "${SCRIPT_DIR}/lib/health.sh"

# ---- 参数 ----
MANAGE_MODE="all"
MANAGE_DIR=""
MANAGE_NODE=""
FORCE_CLEAN=false
MANAGE_COMMAND=""

print_usage() {
    cat <<EOF
GDM 环境管理脚本 — 管理已有部署的启动/停止/重启/状态/日志/销毁

用法:
  $0 <COMMAND> [OPTIONS]

命令:
  start       启动服务（自动检测是否需要 bootstrap token）
  stop        停止服务
  restart     停止再启动
  status      查看 tmux 会话 + 健康检查 + 端口监听
  logs        查看节点日志（tail -f，Ctrl-C 退出）
  destroy     停止服务并清理数据目录

选项:
  -d, --dir <DIR>       指定远程部署目录（默认自动检测最新版本目录）
  -m, --mode <MODE>     管理范围: standalone, cluster, all (默认: all)
  -n, --node <NODE>     仅操作指定节点 (standalone, node1, node2, node3)
  --force-clean         start 时强制清理数据（集群重新 bootstrap）
  -h, --help            显示帮助信息

示例:
  # 启动所有服务（自动检测最新部署目录）
  $0 start

  # 仅启动集群
  $0 start -m cluster

  # 指定目录启动
  $0 start -d /ssd/workspace/gdm-v0.1.0.preview-3

  # 仅操作 node1
  $0 restart -n node1

  # 查看状态
  $0 status

  # 查看 node2 日志
  $0 logs -n node2

  # 停止并清理集群数据
  $0 destroy -m cluster

  # 强制重新 bootstrap 集群
  $0 start -m cluster --force-clean

环境变量:
  GDM_DEPLOY_HOST       远程服务器地址 (默认: 10.86.11.245)
  GDM_DEPLOY_DIR        远程部署目录 (优先级高于自动检测)

EOF
}

parse_args() {
    if [[ $# -lt 1 ]]; then
        log_error "请指定命令: start, stop, restart, status, logs, destroy"
        print_usage
        exit 1
    fi

    MANAGE_COMMAND="$1"
    shift

    case "$MANAGE_COMMAND" in
        start|stop|restart|status|logs|destroy) ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            log_error "未知命令: ${MANAGE_COMMAND}"
            print_usage
            exit 1
            ;;
    esac

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dir)
                MANAGE_DIR="$2"
                shift 2
                ;;
            -m|--mode)
                MANAGE_MODE="$2"
                shift 2
                ;;
            -n|--node)
                MANAGE_NODE="$2"
                shift 2
                ;;
            --force-clean)
                FORCE_CLEAN=true
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    case "$MANAGE_MODE" in
        standalone|cluster|all) ;;
        *)
            log_error "无效模式: ${MANAGE_MODE}，可选: standalone, cluster, all"
            exit 1
            ;;
    esac
}

# ---- 自动检测最新部署目录 ----
# 规则：查找 ${REMOTE_WORK_DIR} 下最新的 gdm-* 目录
auto_detect_base_dir() {
    local detected
    detected=$(ssh_exec "ls -1dt ${REMOTE_WORK_DIR}/gdm-* 2>/dev/null | head -1")
    if [ -z "$detected" ]; then
        log_error "未在 ${REMOTE_WORK_DIR} 下找到 gdm-* 部署目录，请用 -d 指定"
        exit 1
    fi
    echo "$detected"
}

# ---- 单节点启动 ----
# 参数: $1=node_name (standalone|node1|node2|node3), $2=base_dir
do_start_node() {
    local node="$1"
    local base_dir="$2"

    if [ "$node" = "standalone" ]; then
        start_standalone "$base_dir"
    else
        local node_idx
        case "$node" in
            node1) node_idx=0 ;;
            node2) node_idx=1 ;;
            node3) node_idx=2 ;;
            *) log_error "未知节点: ${node}"; return 1 ;;
        esac

        local session="${TMUX_CLUSTER_SESSIONS[$node_idx]}"
        local config="${CLUSTER_CONFIGS[$node_idx]}"
        local node_dir="${base_dir}/cluster/${session}"

        local need_token=false
        if ! cluster_has_identity "$base_dir"; then
            need_token=true
            log_warn "集群尚未 bootstrap，单节点启动可能无法就绪（建议使用 start -m cluster 启动全部节点）"
            cleanup_cluster_data "$base_dir"
            generate_cluster_token "$base_dir" || return 1
        fi

        local token_arg=""
        if [ "$need_token" = true ]; then
            token_arg="--token-file ${CLUSTER_TOKEN_FILE}"
        fi

        ssh_exec "tmux new-session -d -s '${session}' \"bash -c 'cd ${node_dir} && GDM_USER=${GDM_USER} GDM_INITIAL_PASSWORD=${GDM_INITIAL_PASSWORD} bin/${GDM_BINARY_NAME} --config config/${config} ${token_arg} 2>&1 | tee startup.log'\""
        log_info "${session} 已启动 (tmux: ${session})"
    fi
}

# ---- 单节点停止 ----
do_stop_node() {
    local node="$1"
    if [ "$node" = "standalone" ]; then
        stop_tmux_session "$TMUX_STANDALONE_SESSION"
    else
        stop_tmux_session "$node"
    fi
}

# ---- 子命令实现 ----

cmd_start() {
    local base_dir="$1"

    if [ -n "$MANAGE_NODE" ]; then
        log_step "启动节点: ${MANAGE_NODE}"
        do_start_node "$MANAGE_NODE" "$base_dir"
        return
    fi

    if [[ "$MANAGE_MODE" == "standalone" || "$MANAGE_MODE" == "all" ]]; then
        start_standalone "$base_dir"
    fi

    if [[ "$MANAGE_MODE" == "cluster" || "$MANAGE_MODE" == "all" ]]; then
        if [ "$FORCE_CLEAN" = true ]; then
            cleanup_cluster_data "$base_dir"
        fi
        start_cluster "$base_dir"
    fi
}

cmd_stop() {
    local base_dir="$1"

    if [ -n "$MANAGE_NODE" ]; then
        log_step "停止节点: ${MANAGE_NODE}"
        do_stop_node "$MANAGE_NODE"
        sleep 1
        return
    fi

    stop_services "$MANAGE_MODE"
}

cmd_restart() {
    local base_dir="$1"

    log_step "重启服务"
    cmd_stop "$base_dir"
    sleep 3
    cmd_start "$base_dir"
}

cmd_status() {
    local base_dir="$1"

    log_step "服务状态"
    log_info "部署目录: ${base_dir}"
    echo ""

    # tmux 会话状态
    echo "=== tmux 会话 ==="
    ssh_exec "tmux list-sessions 2>/dev/null || echo '  无活跃会话'"
    echo ""

    # 进程状态
    echo "=== GDM 进程 ==="
    ssh_exec "ps aux | grep 'bin/${GDM_BINARY_NAME}' | grep -v grep | awk '{print \"  pid=\" \$2 \" cmd=\" \$11 \" \" \$12 \" \" \$13}' || echo '  无 GDM 进程'"
    echo ""

    # 端口监听
    echo "=== 端口监听 ==="
    local all_ports=()
    if [[ "$MANAGE_MODE" == "standalone" || "$MANAGE_MODE" == "all" ]]; then
        all_ports+=("${STANDALONE_BOLT_PORT}")
    fi
    if [[ "$MANAGE_MODE" == "cluster" || "$MANAGE_MODE" == "all" ]]; then
        all_ports+=("${CLUSTER_BOLT_PORTS[@]}")
    fi
    for port in "${all_ports[@]}"; do
        local listener
        listener=$(ssh_exec "ss -tlnp 2>/dev/null | grep ':${port} ' | head -1")
        if [ -n "$listener" ]; then
            echo "  :${port} -> LISTENING"
        else
            echo "  :${port} -> NOT LISTENING"
        fi
    done
    echo ""

    # 健康检查
    print_health_summary "$MANAGE_MODE"
}

cmd_logs() {
    local base_dir="$1"

    local node="$MANAGE_NODE"
    if [ -z "$node" ]; then
        log_error "logs 命令需要指定 -n <节点名> (standalone, node1, node2, node3)"
        exit 1
    fi

    local log_path=""
    if [ "$node" = "standalone" ]; then
        log_path="${base_dir}/standalone/startup.log"
    else
        log_path="${base_dir}/cluster/${node}/startup.log"
    fi

    log_info "跟踪日志: ${log_path} (Ctrl-C 退出)"
    ssh_exec "tail -n 100 -f '${log_path}' 2>/dev/null || echo '日志文件不存在'"
}

cmd_destroy() {
    local base_dir="$1"

    log_warn "即将停止服务并清理数据: ${base_dir}"

    if [ -z "$MANAGE_NODE" ]; then
        log_warn "这将清理 ${MANAGE_MODE} 模式下的所有数据"
    else
        log_warn "这将清理节点 ${MANAGE_NODE} 的数据"
    fi

    # 安全确认
    echo -n "确认继续？(y/N) "
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "已取消"
        return 0
    fi

    # 停止服务
    cmd_stop "$base_dir"

    # 清理数据
    if [ -n "$MANAGE_NODE" ]; then
        if [ "$MANAGE_NODE" = "standalone" ]; then
            local dir="${base_dir}/standalone"
            ssh_exec "rm -rf '${dir}/data' '${dir}/log' '${dir}/logs' '${dir}/audit' '${dir}/derived'"
        else
            local dir="${base_dir}/cluster/${MANAGE_NODE}"
            ssh_exec "rm -rf '${dir}/data' '${dir}/log' '${dir}/logs' '${dir}/audit' '${dir}/derived'"
        fi
        log_info "节点 ${MANAGE_NODE} 数据已清理"
    else
        if [[ "$MANAGE_MODE" == "standalone" || "$MANAGE_MODE" == "all" ]]; then
            local dir="${base_dir}/standalone"
            ssh_exec "rm -rf '${dir}/data' '${dir}/log' '${dir}/logs' '${dir}/audit' '${dir}/derived'"
            log_info "单机版数据已清理"
        fi
        if [[ "$MANAGE_MODE" == "cluster" || "$MANAGE_MODE" == "all" ]]; then
            cleanup_cluster_data "$base_dir"
        fi
    fi

    log_info "destroy 完成"
}

# ---- 主流程 ----
main() {
    parse_args "$@"

    # 解析部署目录
    local base_dir="$MANAGE_DIR"
    if [ -z "$base_dir" ]; then
        base_dir=$(auto_detect_base_dir)
    fi

    log_separator
    log_info "GDM 环境管理"
    log_info "目标服务器: ${REMOTE_USER}@${REMOTE_HOST}"
    log_info "部署目录: ${base_dir}"
    log_info "命令: ${MANAGE_COMMAND}"
    if [ -n "$MANAGE_NODE" ]; then
        log_info "目标节点: ${MANAGE_NODE}"
    else
        log_info "管理范围: ${MANAGE_MODE}"
    fi
    log_separator

    # 前置检查
    check_sshpass
    check_ssh_connection

    case "$MANAGE_COMMAND" in
        start)    cmd_start "$base_dir" ;;
        stop)     cmd_stop "$base_dir" ;;
        restart)  cmd_restart "$base_dir" ;;
        status)   cmd_status "$base_dir" ;;
        logs)     cmd_logs "$base_dir" ;;
        destroy)  cmd_destroy "$base_dir" ;;
    esac
}

main "$@"
