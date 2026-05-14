#!/usr/bin/env bash
# GDM 环境可用性检查脚本（独立使用）
# 用法:
#   ./scripts/deploy/check_health.sh [OPTIONS]
#
# 选项:
#   -m, --mode <MODE>   检查模式: standalone, cluster, all (默认: all)
#   -w, --wait          等待服务就绪（带超时）
#   -h, --help          显示帮助信息

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 加载模块
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/ssh.sh"
source "${SCRIPT_DIR}/lib/health.sh"

# ---- 参数 ----
CHECK_MODE="${DEPLOY_MODE:-all}"
WAIT_MODE=false

print_usage() {
    cat <<EOF
GDM 环境可用性检查脚本

用法:
  $0 [OPTIONS]

选项:
  -m, --mode <MODE>   检查模式: standalone, cluster, all (默认: all)
  -w, --wait          等待服务就绪（带超时, 默认 ${HEALTH_CHECK_TIMEOUT}s）
  -h, --help          显示帮助信息

示例:
  # 快速检查所有服务
  $0

  # 仅检查单机版
  $0 -m standalone

  # 等待集群就绪
  $0 -m cluster -w

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--mode)
                CHECK_MODE="$2"
                shift 2
                ;;
            -w|--wait)
                WAIT_MODE=true
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
}

# 快速检查（不等待）
quick_check() {
    local mode="$1"
    local result=0

    if [[ "$mode" == "standalone" || "$mode" == "all" ]]; then
        log_info "检查单机版..."
        if check_health_endpoint "$STANDALONE_METRICS_ADDR"; then
            log_info "单机版: healthy"
        else
            log_warn "单机版: unhealthy"
            result=1
        fi

        if check_bolt_port "$REMOTE_HOST" "$STANDALONE_BOLT_PORT"; then
            log_info "单机版 Bolt: reachable"
        else
            log_warn "单机版 Bolt: unreachable"
            result=1
        fi
    fi

    if [[ "$mode" == "cluster" || "$mode" == "all" ]]; then
        log_info "检查集群版..."
        for i in "${!TMUX_CLUSTER_SESSIONS[@]}"; do
            local node="${TMUX_CLUSTER_SESSIONS[$i]}"
            local metrics_addr="${CLUSTER_METRICS_ADDRS[$i]}"
            local bolt_port="${CLUSTER_BOLT_PORTS[$i]}"

            if check_health_endpoint "$metrics_addr"; then
                log_info "${node}: healthy"
            else
                log_warn "${node}: unhealthy"
                result=1
            fi

            if check_bolt_port "$REMOTE_HOST" "$bolt_port"; then
                log_info "${node} Bolt: reachable"
            else
                log_warn "${node} Bolt: unreachable"
                result=1
            fi
        done
    fi

    return $result
}

# ---- 主流程 ----
main() {
    parse_args "$@"

    log_separator
    log_info "GDM 环境可用性检查"
    log_info "目标服务器: ${REMOTE_USER}@${REMOTE_HOST}"
    log_info "检查模式: ${CHECK_MODE}"
    log_separator

    # 前置检查
    check_sshpass
    check_ssh_connection

    local result=0

    if [ "$WAIT_MODE" = true ]; then
        # 等待模式
        if [[ "$CHECK_MODE" == "standalone" || "$CHECK_MODE" == "all" ]]; then
            verify_standalone || result=1
        fi
        if [[ "$CHECK_MODE" == "cluster" || "$CHECK_MODE" == "all" ]]; then
            verify_cluster || result=1
        fi
    else
        # 快速检查模式
        quick_check "$CHECK_MODE" || result=1
    fi

    # 打印摘要
    print_health_summary "$CHECK_MODE"

    # 显示 tmux 状态
    show_tmux_status

    if [ $result -ne 0 ]; then
        log_error "环境检查未全部通过"
        exit 1
    fi

    log_info "环境检查全部通过"
}

main "$@"
