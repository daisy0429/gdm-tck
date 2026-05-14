#!/usr/bin/env bash
# GDM 测试环境自动部署脚本
# 用法:
#   ./scripts/deploy/deploy.sh [OPTIONS]
#
# 选项:
#   -u, --url <URL>       指定安装包下载链接（完整URL）
#   -m, --mode <MODE>     部署模式: standalone, cluster, all (默认: all)
#   -s, --skip-download   跳过下载，使用服务器上已有的安装包
#   -p, --pkg-path <PATH> 指定远程服务器上已有的安装包路径
#   --no-stop             不停止已有服务（默认会先停止）
#   --no-verify           跳过环境可用性验证
#   -h, --help            显示帮助信息

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载模块
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/config.sh"
source "${SCRIPT_DIR}/lib/ssh.sh"
source "${SCRIPT_DIR}/lib/download.sh"
source "${SCRIPT_DIR}/lib/install.sh"
source "${SCRIPT_DIR}/lib/service.sh"
source "${SCRIPT_DIR}/lib/health.sh"

# ---- 参数解析 ----
DOWNLOAD_URL=""
SKIP_DOWNLOAD=false
REMOTE_PKG_PATH=""
STOP_EXISTING=true
DO_VERIFY=true

print_usage() {
    cat <<EOF
GDM 测试环境自动部署脚本

用法:
  $0 [OPTIONS]

选项:
  -u, --url <URL>       指定安装包下载链接（完整URL）
  -m, --mode <MODE>     部署模式: standalone, cluster, all (默认: all)
  -s, --skip-download   跳过下载，使用服务器上已有的安装包
  -p, --pkg-path <PATH> 指定远程服务器上已有的安装包路径
  --no-stop             不停止已有服务
  --no-verify           跳过环境可用性验证
  -h, --help            显示帮助信息

示例:
  # 一键部署（需指定下载URL）
  $0 -u 'http://repo.mengtu.cn/generic/f029Zz227Rbd/gdm-v0.1.0.preview-linux-amd64-2.17.tar.gz?version=v0.1.0.preview-20260514.52'

  # 仅部署单机版
  $0 -u '<URL>' -m standalone

  # 使用服务器上已有的安装包
  $0 -s -p '/ssd/workspace/gdm-v0.1.0.preview-linux-amd64-2.17.tar.gz'

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--url)
                DOWNLOAD_URL="$2"
                shift 2
                ;;
            -m|--mode)
                DEPLOY_MODE="$2"
                shift 2
                ;;
            -s|--skip-download)
                SKIP_DOWNLOAD=true
                shift
                ;;
            -p|--pkg-path)
                REMOTE_PKG_PATH="$2"
                shift 2
                ;;
            --no-stop)
                STOP_EXISTING=false
                shift
                ;;
            --no-verify)
                DO_VERIFY=false
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

# 验证参数
validate_args() {
    if [ "$SKIP_DOWNLOAD" = false ] && [ -z "$DOWNLOAD_URL" ]; then
        log_error "必须指定下载链接 (-u) 或使用 --skip-download"
        print_usage
        exit 1
    fi

    if [ "$SKIP_DOWNLOAD" = true ] && [ -z "$REMOTE_PKG_PATH" ]; then
        log_error "使用 --skip-download 时必须指定 -p <远程安装包路径>"
        exit 1
    fi

    case "$DEPLOY_MODE" in
        standalone|cluster|all) ;;
        *)
            log_error "无效的部署模式: ${DEPLOY_MODE}，可选: standalone, cluster, all"
            exit 1
            ;;
    esac
}

# ---- 主流程 ----
main() {
    parse_args "$@"
    validate_args

    log_separator
    log_info "GDM 测试环境部署"
    log_info "目标服务器: ${REMOTE_USER}@${REMOTE_HOST}"
    log_info "工作目录: ${REMOTE_WORK_DIR}"
    log_info "部署模式: ${DEPLOY_MODE}"
    log_separator

    # 1. 前置检查
    check_sshpass
    check_ssh_connection

    # 2. 下载安装包
    local pkg_filename
    local pkg_remote_path

    if [ "$SKIP_DOWNLOAD" = true ]; then
        pkg_remote_path="$REMOTE_PKG_PATH"
        pkg_filename=$(basename "$pkg_remote_path")
        log_info "使用已有安装包: ${pkg_remote_path}"
    else
        pkg_filename=$(extract_filename_from_url "$DOWNLOAD_URL")
        pkg_remote_path="${REMOTE_WORK_DIR}/${pkg_filename}"

        ssh_exec "mkdir -p '${REMOTE_WORK_DIR}'"
        download_package_by_url "$DOWNLOAD_URL" "$pkg_remote_path"
    fi

    # 3. 创建部署目录
    local version_tag
    version_tag=$(extract_version_tag "$pkg_filename")
    local base_dir
    base_dir=$(create_deploy_dirs "$version_tag")

    log_info "部署目录: ${base_dir}"

    # 4. 停止已有服务
    if [ "$STOP_EXISTING" = true ]; then
        stop_all_services
    fi

    # 5. 安装
    if [[ "$DEPLOY_MODE" == "standalone" || "$DEPLOY_MODE" == "all" ]]; then
        install_standalone "$base_dir" "$pkg_remote_path"
    fi

    if [[ "$DEPLOY_MODE" == "cluster" || "$DEPLOY_MODE" == "all" ]]; then
        install_cluster "$base_dir" "$pkg_remote_path"
    fi

    # 6. 上传配置文件
    upload_configs "$base_dir"

    # 7. 启动服务
    if [[ "$DEPLOY_MODE" == "standalone" || "$DEPLOY_MODE" == "all" ]]; then
        start_standalone "$base_dir"
    fi

    if [[ "$DEPLOY_MODE" == "cluster" || "$DEPLOY_MODE" == "all" ]]; then
        start_cluster "$base_dir"
    fi

    # 8. 验证环境可用性
    if [ "$DO_VERIFY" = true ]; then
        log_step "等待服务启动..."
        sleep 5

        local verify_result=0
        if [[ "$DEPLOY_MODE" == "standalone" || "$DEPLOY_MODE" == "all" ]]; then
            verify_standalone || verify_result=1
        fi

        if [[ "$DEPLOY_MODE" == "cluster" || "$DEPLOY_MODE" == "all" ]]; then
            verify_cluster || verify_result=1
        fi

        print_health_summary "$DEPLOY_MODE"

        if [ $verify_result -ne 0 ]; then
            log_error "部分服务未通过健康检查，请检查日志"
            show_tmux_status
            exit 1
        fi
    fi

    # 9. 完成
    log_separator
    log_info "部署完成"
    show_tmux_status
    log_separator

    echo ""
    echo "部署信息:"
    echo "  版本: ${version_tag}"
    echo "  目录: ${base_dir}"
    if [[ "$DEPLOY_MODE" == "standalone" || "$DEPLOY_MODE" == "all" ]]; then
        echo "  单机版 Bolt: bolt://${REMOTE_HOST}:${STANDALONE_BOLT_PORT}"
    fi
    if [[ "$DEPLOY_MODE" == "cluster" || "$DEPLOY_MODE" == "all" ]]; then
        for i in "${!CLUSTER_BOLT_PORTS[@]}"; do
            echo "  集群 node$((i+1)) Bolt: bolt://${REMOTE_HOST}:${CLUSTER_BOLT_PORTS[$i]}"
        done
    fi
}

main "$@"
