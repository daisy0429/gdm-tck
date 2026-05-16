#!/usr/bin/env bash
# 安装模块
# 负责解压安装包、创建目录结构、上传配置文件

# 在远程服务器上创建部署目录结构
# 如果同名目录已存在，自动追加后缀 -2, -3, ...
# 参数: $1 - 版本标识 (如 gdm-v0.1.0.preview-linux-amd64-2.17)
create_deploy_dirs() {
    local version_tag="$1"
    local base_dir="${REMOTE_WORK_DIR}/${version_tag}"

    # 检查远程目录是否已存在，若存在则追加递增后缀
    local suffix=1
    while ssh_exec "test -d '${base_dir}'" 2>/dev/null; do
        suffix=$((suffix + 1))
        base_dir="${REMOTE_WORK_DIR}/${version_tag}-${suffix}"
    done

    log_info "创建部署目录: ${base_dir}"

    ssh_exec "mkdir -p '${base_dir}/standalone' '${base_dir}/cluster/node1' '${base_dir}/cluster/node2' '${base_dir}/cluster/node3'"
    if [ $? -ne 0 ]; then
        log_error "创建部署目录失败"
        return 1
    fi

    echo "${base_dir}"
}

# 解压安装包到指定目录，并将 tar 包产生的子目录内容提升到目标目录
# 参数: $1 - 安装包路径, $2 - 目标目录
extract_package() {
    local pkg_path="$1"
    local target_dir="$2"

    log_info "解压安装包到: ${target_dir}"
    ssh_exec "tar -xzf '${pkg_path}' -C '${target_dir}'"
    if [ $? -ne 0 ]; then
        log_error "解压安装包失败"
        return 1
    fi

    local subdir
    subdir=$(ssh_exec "ls -1 '${target_dir}' | head -1")
    if [ -n "$subdir" ] && ssh_exec "test -d '${target_dir}/${subdir}/bin'"; then
        log_info "提升目录: ${subdir}/ -> ."
        ssh_exec "mv '${target_dir}/${subdir}'/* '${target_dir}/' && rmdir '${target_dir}/${subdir}'"
        if [ $? -ne 0 ]; then
            log_error "提升目录失败"
            return 1
        fi
    fi
}

# 安装单机版
# 参数: $1 - 部署基础目录, $2 - 安装包路径
install_standalone() {
    local base_dir="$1"
    local pkg_path="$2"
    local standalone_dir="${base_dir}/standalone"

    log_step "安装单机版到: ${standalone_dir}"

    extract_package "$pkg_path" "$standalone_dir"

    # 查找解压后的二进制文件并确认
    local binary_check
    binary_check=$(ssh_exec "find '${standalone_dir}' -name '${GDM_BINARY_NAME}' -type f | head -1")
    if [ -z "$binary_check" ]; then
        log_error "未找到 GDM 二进制文件: ${GDM_BINARY_NAME}"
        return 1
    fi

    log_info "二进制文件: ${binary_check}"
    ssh_exec "chmod +x '${binary_check}'"
}

# 安装集群版
# 参数: $1 - 部署基础目录, $2 - 安装包路径
install_cluster() {
    local base_dir="$1"
    local pkg_path="$2"

    log_step "安装集群版到: ${base_dir}/cluster"

    local nodes=("node1" "node2" "node3")
    for node in "${nodes[@]}"; do
        local node_dir="${base_dir}/cluster/${node}"
        extract_package "$pkg_path" "$node_dir"

        local binary_check
        binary_check=$(ssh_exec "find '${node_dir}' -name '${GDM_BINARY_NAME}' -type f | head -1")
        if [ -z "$binary_check" ]; then
            log_error "未找到 ${node} 的 GDM 二进制文件"
            return 1
        fi
        ssh_exec "chmod +x '${binary_check}'"
        log_info "${node} 安装完成"
    done
}

# 上传配置文件
# 参数: $1 - 部署基础目录
upload_configs() {
    local base_dir="$1"

    log_step "上传配置文件"

    # 上传单机配置
    if [[ "$DEPLOY_MODE" == "standalone" || "$DEPLOY_MODE" == "all" ]]; then
        local standalone_dir="${base_dir}/standalone"
        scp_upload "${LOCAL_CONFIG_DIR}/${STANDALONE_CONFIG}" "${standalone_dir}/config/${STANDALONE_CONFIG}"
        log_info "单机配置已上传: ${STANDALONE_CONFIG}"
    fi

    # 上传集群配置
    if [[ "$DEPLOY_MODE" == "cluster" || "$DEPLOY_MODE" == "all" ]]; then
        for i in "${!CLUSTER_CONFIGS[@]}"; do
            local config="${CLUSTER_CONFIGS[$i]}"
            local node_dir="${base_dir}/cluster/node$((i+1))"
            scp_upload "${LOCAL_CONFIG_DIR}/${config}" "${node_dir}/config/${config}"
            log_info "集群配置已上传: ${config} -> node$((i+1))"
        done
    fi
}
