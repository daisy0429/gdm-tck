#!/usr/bin/env bash
# 安装包下载模块
# 负责从仓库下载 GDM 安装包到远程服务器

# 在远程服务器上下载安装包
# 参数: $1 - 下载链接(完整URL), $2 - 远程保存路径
download_package_by_url() {
    local url="$1"
    local output_path="$2"

    log_info "下载安装包: ${url}"
    log_info "保存路径: ${output_path}"

    ssh_exec "curl -fL -u '${REPO_USER}:${REPO_PASSWORD}' '${url}' -o '${output_path}'"
    if [ $? -ne 0 ]; then
        log_error "安装包下载失败"
        return 1
    fi

    log_info "安装包下载完成"
}

# 从包文件名中提取版本标识（用于创建目录名）
# 参数: $1 - 包文件名 (如 gdm-v0.1.0.preview-linux-amd64-2.17.tar.gz)
# 输出: 版本标识 (如 gdm-v0.1.0.preview-linux-amd64-2.17)
extract_version_tag() {
    local filename="$1"
    echo "${filename%.tar.gz}"
}

# 从下载 URL 中提取文件名
# 参数: $1 - 完整下载URL
extract_filename_from_url() {
    local url="$1"
    local path_part="${url%%\?*}"
    basename "$path_part"
}
