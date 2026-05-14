#!/usr/bin/env bash
# 部署配置模块
# 统一管理所有部署相关的配置参数，禁止硬编码

# ---- 远程服务器配置 ----
REMOTE_HOST="${GDM_DEPLOY_HOST:-10.86.11.245}"
REMOTE_USER="${GDM_DEPLOY_USER:-root}"
REMOTE_PASSWORD="${GDM_DEPLOY_PASSWORD:-stmt@2026}"
REMOTE_WORK_DIR="${GDM_DEPLOY_WORK_DIR:-/ssd/workspace}"

# ---- 安装包仓库配置 ----
REPO_BASE_URL="${GDM_REPO_URL:-http://repo.mengtu.cn}"
REPO_USER="${GDM_REPO_USER:-dengpingping}"
REPO_PASSWORD="${GDM_REPO_PASSWORD:-dengpingping@123456}"
REPO_ID="${GDM_REPO_ID:-f029Zz227Rbd}"

# ---- 安装包筛选条件 ----
PKG_ARCH="${GDM_PKG_ARCH:-amd64}"
PKG_GLIBC="${GDM_PKG_GLIBC:-2.17}"
PKG_PROJECT="${GDM_PKG_PROJECT:-gdm}"

# ---- 部署模式 ----
# standalone: 单机部署
# cluster: 集群部署
# all: 同时部署单机和集群
DEPLOY_MODE="${GDM_DEPLOY_MODE:-standalone}"

# ---- 本地配置文件路径（相对于 scripts/deploy/ 目录）----
LOCAL_CONFIG_DIR="${SCRIPT_DIR}/config"
STANDALONE_CONFIG="standalone.toml"
CLUSTER_CONFIGS=("node1.toml" "node2.toml" "node3.toml")

# ---- GDM 二进制相关 ----
GDM_BINARY_NAME="gdm"

# ---- GDM 启动账号密码 ----
GDM_USER="${GDM_DEPLOY_GDM_USER:-admin}"
GDM_INITIAL_PASSWORD="${GDM_DEPLOY_GDM_PASSWORD:-admin123}"

# ---- tmux 会话名称 ----
TMUX_STANDALONE_SESSION="standalone"
TMUX_CLUSTER_SESSIONS=("node1" "node2" "node3")

# ---- 健康检查配置 ----
HEALTH_CHECK_TIMEOUT="${GDM_HEALTH_TIMEOUT:-60}"
HEALTH_CHECK_INTERVAL="${GDM_HEALTH_INTERVAL:-3}"
HEALTH_CHECK_RETRIES="${GDM_HEALTH_RETRIES:-20}"

# ---- Bolt 端口（用于连通性验证）----
STANDALONE_BOLT_PORT="${GDM_STANDALONE_BOLT_PORT:-7690}"
CLUSTER_BOLT_PORTS=("${GDM_CLUSTER_BOLT_PORT1:-7687}" "${GDM_CLUSTER_BOLT_PORT2:-7688}" "${GDM_CLUSTER_BOLT_PORT3:-7689}")

# ---- Metrics 端口（用于健康检查）----
STANDALONE_METRICS_ADDR="${GDM_STANDALONE_METRICS:-10.86.11.245:9095}"
CLUSTER_METRICS_ADDRS=("${GDM_CLUSTER_METRICS1:-10.86.11.245:9090}" "${GDM_CLUSTER_METRICS2:-10.86.11.245:9091}" "${GDM_CLUSTER_METRICS3:-10.86.11.245:9092}")

# ---- SSH 相关 ----
SSH_TIMEOUT="${GDM_SSH_TIMEOUT:-10}"
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=${SSH_TIMEOUT} -o LogLevel=ERROR"
