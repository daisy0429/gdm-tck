#!/usr/bin/env bash
# 服务管理模块
# 负责通过 tmux 启动/停止 GDM 服务

# 停止指定 tmux 会话
# 参数: $1 - 会话名称
stop_tmux_session() {
    local session_name="$1"

    log_info "停止 tmux 会话: ${session_name}"
    ssh_exec "tmux kill-session -t '${session_name}' 2>/dev/null || true"
}

# 停止已有服务（按部署模式）
# 参数: $1 - 部署模式: standalone, cluster, all
stop_services() {
    local mode="$1"

    log_step "停止已有服务 (模式: ${mode})"

    if [[ "$mode" == "standalone" || "$mode" == "all" ]]; then
        stop_tmux_session "$TMUX_STANDALONE_SESSION"
    fi

    if [[ "$mode" == "cluster" || "$mode" == "all" ]]; then
        for session in "${TMUX_CLUSTER_SESSIONS[@]}"; do
            stop_tmux_session "$session"
        done
    fi

    sleep 2
    log_info "相关服务已停止"
}

# 启动单机版服务
# 参数: $1 - 部署基础目录
start_standalone() {
    local base_dir="$1"
    local standalone_dir="${base_dir}/standalone"

    log_step "启动单机版服务"

    # 查找二进制文件
    local binary_path
    binary_path=$(ssh_exec "find '${standalone_dir}' -name '${GDM_BINARY_NAME}' -type f | head -1")
    if [ -z "$binary_path" ]; then
        log_error "未找到 GDM 二进制文件"
        return 1
    fi

    local config_path="${standalone_dir}/config/${STANDALONE_CONFIG}"

    ssh_exec "tmux new-session -d -s '${TMUX_STANDALONE_SESSION}' 'cd ${standalone_dir} && GDM_USER=${GDM_USER} GDM_INITIAL_PASSWORD=${GDM_INITIAL_PASSWORD} bin/${GDM_BINARY_NAME} --config ${config_path}'"
    if [ $? -ne 0 ]; then
        log_error "启动单机版失败"
        return 1
    fi

    log_info "单机版已启动 (tmux: ${TMUX_STANDALONE_SESSION})"
}

# 启动集群版服务
# 参数: $1 - 部署基础目录
start_cluster() {
    local base_dir="$1"

    log_step "启动集群版服务"

    for i in "${!TMUX_CLUSTER_SESSIONS[@]}"; do
        local session="${TMUX_CLUSTER_SESSIONS[$i]}"
        local node_dir="${base_dir}/cluster/${session}"
        local config="${CLUSTER_CONFIGS[$i]}"

        # 查找二进制文件
        local binary_path
        binary_path=$(ssh_exec "find '${node_dir}' -name '${GDM_BINARY_NAME}' -type f | head -1")
        if [ -z "$binary_path" ]; then
            log_error "未找到 ${session} 的 GDM 二进制文件"
            return 1
        fi

        local config_path="${node_dir}/config/${config}"

        ssh_exec "tmux new-session -d -s '${session}' 'cd ${node_dir} && GDM_USER=${GDM_USER} GDM_INITIAL_PASSWORD=${GDM_INITIAL_PASSWORD} bin/${GDM_BINARY_NAME} --config ${config_path}'"
        if [ $? -ne 0 ]; then
            log_error "启动 ${session} 失败"
            return 1
        fi

        log_info "${session} 已启动 (tmux: ${session})"
    done
}

# 查看 tmux 会话状态
show_tmux_status() {
    log_info "当前 tmux 会话:"
    ssh_exec "tmux list-sessions 2>/dev/null || echo '无活跃会话'"
}
