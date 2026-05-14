#!/usr/bin/env bash
# 日志工具模块
# 提供统一的日志输出格式

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%H:%M:%S') $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%H:%M:%S') $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') $*" >&2
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $(date '+%H:%M:%S') $*"
}

# 打印分隔线
log_separator() {
    echo "================================================================"
}
