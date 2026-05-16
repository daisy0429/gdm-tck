#!/usr/bin/env bash
# SSH 工具模块
# 封装 SSH/SCP 远程操作，统一错误处理

# 执行远程命令
# 参数: $@ - 要执行的远程命令
ssh_exec() {
    sshpass -p "${REMOTE_PASSWORD}" \
        ssh ${SSH_OPTIONS} "${REMOTE_USER}@${REMOTE_HOST}" "$@"
}

# 上传文件到远程服务器
# 参数: $1 - 本地文件路径, $2 - 远程目标路径
scp_upload() {
    local local_path="$1"
    local remote_path="$2"
    sshpass -p "${REMOTE_PASSWORD}" \
        scp ${SSH_OPTIONS} "$local_path" "${REMOTE_USER}@${REMOTE_HOST}:${remote_path}"
}

# 上传目录到远程服务器
# 参数: $1 - 本地目录路径, $2 - 远程目标路径
scp_upload_dir() {
    local local_path="$1"
    local remote_path="$2"
    sshpass -p "${REMOTE_PASSWORD}" \
        scp -r ${SSH_OPTIONS} "$local_path" "${REMOTE_USER}@${REMOTE_HOST}:${remote_path}"
}

# 检查远程连接是否正常
check_ssh_connection() {
    log_info "检查 SSH 连接: ${REMOTE_USER}@${REMOTE_HOST}"
    if ssh_exec "echo ok" >/dev/null 2>&1; then
        log_info "SSH 连接正常"
        return 0
    else
        log_error "SSH 连接失败: ${REMOTE_USER}@${REMOTE_HOST}"
        return 1
    fi
}

# 检查本地是否安装了 sshpass
check_sshpass() {
    if ! command -v sshpass &>/dev/null; then
        log_error "未安装 sshpass，请先安装: brew install hudochenkov/sshpass/sshpass"
        return 1
    fi
}
