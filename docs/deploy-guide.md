# GDM 测试环境部署手册

## 概述

本套脚本用于从本地 MacOS 通过 SSH 远程部署 GDM 测试环境到目标服务器，支持单机版和集群版的自动部署及环境可用性验证。

## 前置条件

### 本地环境要求

1. **sshpass** - 用于 SSH 密码认证

```bash
brew install hudochenkov/sshpass/sshpass
```

2. **curl** - 系统自带

### 目标服务器

- 地址: `10.86.11.245`
- 用户: `root`
- 工作目录: `/ssd/workspace`

## 目录结构

```
scripts/deploy/
├── deploy.sh           # 主部署脚本（一键部署入口）
├── check_health.sh     # 独立环境可用性检查脚本
└── lib/
    ├── config.sh       # 配置参数模块
    ├── log.sh          # 日志输出模块
    ├── ssh.sh          # SSH 工具模块
    ├── download.sh     # 安装包下载模块
    ├── install.sh      # 安装/解压模块
    ├── service.sh      # 服务管理模块（tmux）
    └── health.sh       # 健康检查模块
```

## 使用方法

### 一键部署（指定下载链接）

```bash
./scripts/deploy/deploy.sh -u '<安装包下载链接>'
```

完整示例:

```bash
./scripts/deploy/deploy.sh -u 'http://repo.mengtu.cn/generic/f029Zz227Rbd/gdm-v0.1.0.preview-linux-amd64-2.17.tar.gz?version=v0.1.0.preview-20260514.52'
```

### 指定部署模式

```bash
# 仅部署单机版
./scripts/deploy/deploy.sh -u '<URL>' -m standalone

# 仅部署集群版
./scripts/deploy/deploy.sh -u '<URL>' -m cluster

# 同时部署单机和集群（默认）
./scripts/deploy/deploy.sh -u '<URL>' -m all
```

### 使用已有安装包

当服务器上已有安装包时，跳过下载步骤:

```bash
./scripts/deploy/deploy.sh -s -p '/ssd/workspace/gdm-v0.1.0.preview-linux-amd64-2.17.tar.gz'
```
使用已有安装包，指定部署方式
./scripts/deploy/deploy.sh -s -p '/ssd/workspace/gdm-v0.1.0.preview-linux-amd64-2.17.tar.gz' -m cluster


### 跳过环境验证

```bash
./scripts/deploy/deploy.sh -u '<URL>' --no-verify
```

### 不停止已有服务

```bash
./scripts/deploy/deploy.sh -u '<URL>' --no-stop
```

## 环境可用性检查

独立检查当前已部署环境的可用性:

```bash
# 快速检查所有服务
./scripts/deploy/check_health.sh

# 仅检查单机版
./scripts/deploy/check_health.sh -m standalone

# 仅检查集群版
./scripts/deploy/check_health.sh -m cluster

# 等待服务就绪（带超时）
./scripts/deploy/check_health.sh -m all -w
```

## 参数说明

### deploy.sh 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-u, --url <URL>` | 安装包下载链接（完整URL） | 无（必填） |
| `-m, --mode <MODE>` | 部署模式: standalone, cluster, all | all |
| `-s, --skip-download` | 跳过下载步骤 | false |
| `-p, --pkg-path <PATH>` | 远程服务器安装包路径 | 无 |
| `--no-stop` | 不停止已有服务 | false |
| `--no-verify` | 跳过环境可用性验证 | false |
| `-h, --help` | 显示帮助信息 | - |

### check_health.sh 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-m, --mode <MODE>` | 检查模式: standalone, cluster, all | all |
| `-w, --wait` | 等待服务就绪（带超时） | false |
| `-h, --help` | 显示帮助信息 | - |

## 环境变量覆盖

所有配置参数均可通过环境变量覆盖:

| 环境变量 | 说明 | 默认值 |
|----------|------|--------|
| `GDM_DEPLOY_HOST` | 目标服务器地址 | 10.86.11.245 |
| `GDM_DEPLOY_USER` | SSH 用户名 | root |
| `GDM_DEPLOY_PASSWORD` | SSH 密码 | stmt@2026 |
| `GDM_DEPLOY_WORK_DIR` | 远程工作目录 | /ssd/workspace |
| `GDM_REPO_USER` | 仓库用户名 | dengpingping |
| `GDM_REPO_PASSWORD` | 仓库密码 | dengpingping@123456 |
| `GDM_DEPLOY_MODE` | 部署模式 | all |
| `GDM_HEALTH_TIMEOUT` | 健康检查超时(秒) | 60 |
| `GDM_HEALTH_INTERVAL` | 检查间隔(秒) | 3 |
| `GDM_STANDALONE_BOLT_PORT` | 单机 Bolt 端口 | 7690 |
| `GDM_SSH_TIMEOUT` | SSH 连接超时(秒) | 10 |

## 部署流程说明

脚本执行的完整流程:

1. **前置检查** - 验证 sshpass 安装、SSH 连接
2. **下载安装包** - 在远程服务器上使用 curl 下载（或跳过）
3. **创建目录结构** - 根据包名创建 `<版本标识>/standalone/` 和 `<版本标识>/cluster/node1|2|3/`
4. **停止已有服务** - kill 掉已有的 tmux 会话
5. **解压安装** - 将安装包解压到各节点目录
6. **上传配置文件** - 将本地 `config/gdmconfig/` 下的配置文件上传到对应目录
7. **启动服务** - 通过 tmux 启动各节点 GDM 进程
8. **验证可用性** - 轮询 HTTP 健康端点和 Bolt 端口

## 部署后的目录结构（远程服务器）

```
/ssd/workspace/
└── gdm-v0.1.0.preview-linux-amd64-2.17/    # 版本标识目录
    ├── standalone/                           # 单机版
    │   ├── gdm                              # 二进制文件（解压后）
    │   └── standalone.toml                  # 配置文件
    └── cluster/                             # 集群版
        ├── node1/
        │   ├── gdm
        │   └── node1.toml
        ├── node2/
        │   ├── gdm
        │   └── node2.toml
        └── node3/
            ├── gdm
            └── node3.toml
```

## tmux 会话

| 会话名称 | 用途 |
|----------|------|
| standalone | 单机版 GDM 进程 |
| node1 | 集群节点 1 |
| node2 | 集群节点 2 |
| node3 | 集群节点 3 |

手动查看日志:
```bash
# 通过 SSH 进入服务器后
tmux attach -t standalone
tmux attach -t node1
```

## 常见问题

### sshpass 未安装

```
[ERROR] 未安装 sshpass，请先安装: brew install hudochenkov/sshpass/sshpass
```

解决: `brew install hudochenkov/sshpass/sshpass`

### SSH 连接失败

检查:
- 服务器 IP 和端口是否正确
- 密码是否正确
- 网络是否可达

### 健康检查超时

可能原因:
- GDM 启动较慢，可增大超时: `GDM_HEALTH_TIMEOUT=120`
- 配置文件有误，查看 tmux 日志
- 端口冲突

### 安装包解压后找不到二进制文件

检查:
- 下载的安装包是否正确（架构、glibc 版本）
- 安装包是否损坏（重新下载）
