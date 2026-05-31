#!/usr/bin/env bash
# 服务管理模块
# 负责通过 tmux 启动/停止 GDM 服务，包括集群 bootstrap token 管理

# 远程 token 文件路径
CLUSTER_TOKEN_FILE="/tmp/.gdm-cluster-token-$(date +%s)"

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

# 清理集群节点的持久化数据（首次 bootstrap 前调用）
# distributed 模式下，data_dir 和 log_dir 中存储了 cluster identity。
# 如果残留了旧数据，bootstrap token 会校验失败。
# 参数: $1 - 部署基础目录
cleanup_cluster_data() {
    local base_dir="$1"

    log_info "清理集群节点持久化数据"

    for i in "${!TMUX_CLUSTER_SESSIONS[@]}"; do
        local session="${TMUX_CLUSTER_SESSIONS[$i]}"
        local node_dir="${base_dir}/cluster/${session}"

        ssh_exec "rm -rf '${node_dir}/data' '${node_dir}/log' '${node_dir}/logs' '${node_dir}/audit' '${node_dir}/derived' 2>/dev/null"
    done

    log_info "集群数据已清理"
}

# 检查集群是否已有持久化的 cluster identity
# 返回 0 表示已有 identity（可复用），1 表示全新部署
# 判据：bootstrap 完成后会在 data/ 下生成 node.toml（含 cluster_uuid 等身份信息），
# 同时 log/raft-log/gdm_central_raft/ 下有 Raft metadata 存储。
# 两者同时存在才认为 identity 完整。
# 参数: $1 - 部署基础目录
cluster_has_identity() {
    local base_dir="$1"
    local node_dir="${base_dir}/cluster/node1"

    ssh_exec "test -f '${node_dir}/data/node.toml' -a -d '${node_dir}/log/raft-log/gdm_central_raft'" 2>/dev/null
}

# 生成集群 bootstrap token（使用 gdm-admin cluster init）
# Token 写入远程文件 $CLUSTER_TOKEN_FILE
# 参数: $1 - 部署基础目录
generate_cluster_token() {
    local base_dir="$1"
    local node_dir="${base_dir}/cluster/node1"
    local admin_bin="${node_dir}/bin/gdm-admin"

    log_info "生成集群 bootstrap token"

    local token
    token=$(ssh_exec "${admin_bin} cluster init 2>&1 | grep '^BS' | tr -d '\\n'")
    if [ -z "$token" ]; then
        log_error "生成 bootstrap token 失败"
        return 1
    fi

    ssh_exec "echo -n '${token}' > '${CLUSTER_TOKEN_FILE}' && chmod 600 '${CLUSTER_TOKEN_FILE}'"

    log_info "Bootstrap token 已写入远程 ${CLUSTER_TOKEN_FILE}"
}

# 启动单机版服务
# 参数: $1 - 部署基础目录
start_standalone() {
    local base_dir="$1"
    local standalone_dir="${base_dir}/standalone"

    log_step "启动单机版服务"

    local binary_path
    binary_path=$(ssh_exec "find '${standalone_dir}' -name '${GDM_BINARY_NAME}' -type f | head -1")
    if [ -z "$binary_path" ]; then
        log_error "未找到 GDM 二进制文件"
        return 1
    fi

    local config_path="${standalone_dir}/config/${STANDALONE_CONFIG}"

    ssh_exec "tmux new-session -d -s '${TMUX_STANDALONE_SESSION}' \"bash -c 'cd ${standalone_dir} && GDM_USER=${GDM_USER} GDM_INITIAL_PASSWORD=${GDM_INITIAL_PASSWORD} bin/${GDM_BINARY_NAME} --config ${config_path} 2>&1 | tee startup.log'\""
    if [ $? -ne 0 ]; then
        log_error "启动单机版失败"
        return 1
    fi

    log_info "单机版已启动 (tmux: ${TMUX_STANDALONE_SESSION})"
}

# 启动集群版服务
# 流程：
#   1. 如果无 cluster identity（全新部署），清理残留数据
#   2. 始终生成 bootstrap token 并传递给各节点
#      - 全新部署：token 用于 bootstrap（节点互相验证身份）
#      - 已有 identity：token 被安全忽略（GDM 检测到已有 identity 直接跳过）
#   3. 同时启动所有节点（Raft 需要 quorum）
# 参数: $1 - 部署基础目录
start_cluster() {
    local base_dir="$1"

    log_step "启动集群版服务"

    local is_new_cluster=false
    if ! cluster_has_identity "$base_dir"; then
        is_new_cluster=true
        log_info "检测到全新集群部署，清理残留数据"
        cleanup_cluster_data "$base_dir"
    else
        log_info "检测到已有集群 identity"
    fi

    generate_cluster_token "$base_dir" || return 1

    for i in "${!TMUX_CLUSTER_SESSIONS[@]}"; do
        local session="${TMUX_CLUSTER_SESSIONS[$i]}"
        local node_dir="${base_dir}/cluster/${session}"
        local config="${CLUSTER_CONFIGS[$i]}"

        local binary_path
        binary_path=$(ssh_exec "find '${node_dir}' -name '${GDM_BINARY_NAME}' -type f | head -1")
        if [ -z "$binary_path" ]; then
            log_error "未找到 ${session} 的 GDM 二进制文件"
            return 1
        fi

        local config_path="${node_dir}/config/${config}"

        ssh_exec "tmux new-session -d -s '${session}' \"bash -c 'cd ${node_dir} && GDM_USER=${GDM_USER} GDM_INITIAL_PASSWORD=${GDM_INITIAL_PASSWORD} bin/${GDM_BINARY_NAME} --config ${config_path} --token-file ${CLUSTER_TOKEN_FILE} 2>&1 | tee startup.log'\""
        if [ $? -ne 0 ]; then
            log_error "启动 ${session} 失败"
            return 1
        fi

        log_info "${session} 已启动 (tmux: ${session}, new_cluster: ${is_new_cluster})"
    done
}

# 查看 tmux 会话状态
show_tmux_status() {
    log_info "当前 tmux 会话:"
    ssh_exec "tmux list-sessions 2>/dev/null || echo '无活跃会话'"
}
