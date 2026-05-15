# GDM TCK 用户手册

## 目录
- [项目简介](#项目简介)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [运行测试](#运行测试)
  - [运行所有测试](#运行所有测试)
  - [运行特定测试套件](#运行特定测试套件)
  - [按功能目录运行](#按功能目录运行)
  - [并行执行](#并行执行)
  - [生成测试报告](#生成测试报告)
- [测试结果分析](#测试结果分析)
- [常见问题](#常见问题)

## 项目简介

GDM TCK (Technology Compatibility Kit) 是一个基于 Python + pytest-bdd 的 BDD 测试框架，用于测试 GDM 图数据库产品的兼容性。本手册将指导您如何执行测试用例。

## 环境要求

- Python 3.11 或更高版本
- uv 包管理器（推荐）或 pip
- GDM 图数据库实例（正在运行）

## 快速开始

### 1. 安装依赖
```bash
# 使用 uv 安装依赖（推荐）
uv sync

# 或使用 pip
pip install -e .
```

### 2. 配置数据库连接
编辑 `config/default.toml` 文件，配置您的 GDM 数据库连接信息：

```toml
[server]
backend = "gdm"                        # 数据库类型
mode = "standalone"                    # 运行模式：standalone 或 distributed
bolt_uri = "bolt://your-host:7690"     # 您的 GDM Bolt 端点
username = "your-username"             # 数据库用户名
password = "your-password"             # 数据库密码
database = "default"                   # 目标数据库名称
```

或者使用环境变量覆盖配置：
```bash
export GDM_TCK_SERVER__BOLT_URI="bolt://your-host:7690"
export GDM_TCK_SERVER__USERNAME="your-username"
export GDM_TCK_SERVER__PASSWORD="your-password"
```

### 3. 验证测试框架
```bash
# 收集测试用例（不执行）
uv run pytest tests/ --co
```

### 4. 运行测试
```bash
# 运行所有 TCK 测试
uv run pytest tests/tck/ --alluredir=allure-results
```

## 配置说明

### 配置文件
所有配置都存储在 `config/default.toml` 文件中。主要配置项：

- `server.bolt_uri` - GDM Bolt 端点地址
- `server.username` / `server.password` - 数据库认证信息
- `server.database` - 目标数据库名称
- `server.mode` - 运行模式：standalone（单机）或 distributed（分布式）

### 环境变量覆盖
您可以使用环境变量覆盖任何配置项，格式为 `GDM_TCK_` 前缀 + 配置路径（双下划线表示嵌套）：
```bash
export GDM_TCK_SERVER__BOLT_URI="bolt://localhost:7687"
export GDM_TCK_SERVER__USERNAME="neo4j"
export GDM_TCK_SERVER__PASSWORD="password"
```

### 使用额外配置文件
```bash
export GDM_TCK_CONFIG=config/ci.toml
```

## 运行测试

### 运行所有测试
```bash
# 运行所有 TCK 测试
uv run pytest tests/tck/ --alluredir=allure-results

# 使用脚本运行
./scripts/run_suite.sh tck
```

### 运行特定测试套件
使用 `run_suite.sh` 脚本可以运行预定义的测试套件：

```bash
# 运行 clauses 测试套件
./scripts/run_suite.sh clauses

# 运行 expressions 测试套件
./scripts/run_suite.sh expressions

# 运行 DDL 测试套件
./scripts/run_suite.sh ddl

# 运行 DML 测试套件
./scripts/run_suite.sh dml

# 运行索引测试套件
./scripts/run_suite.sh index

# 运行约束测试套件
./scripts/run_suite.sh constraint

# 运行国家标准测试套件
./scripts/run_suite.sh national_std

# 运行容量测试套件
./scripts/run_suite.sh capacity

# 运行功能测试
./scripts/run_suite.sh functional

# 运行性能测试
./scripts/run_suite.sh performance

# 运行所有测试
./scripts/run_suite.sh all
```

### 按功能目录运行
您可以使用 `--features` 选项指定 `features/` 目录下的子路径来运行特定测试：

```bash
# 运行 0-original 目录下的所有测试
uv run pytest tests/tck/ --features=0-original

# 运行 0-original/clauses/match 目录下的测试
uv run pytest tests/tck/ --features=0-original/clauses/match

# 运行 1-metadata/Concurrent 目录下的测试
uv run pytest tests/tck/ --features=1-metadata/Concurrent

# 使用脚本运行
./scripts/run_suite.sh --features 0-original/clauses/match
```

### 并行执行
使用 pytest-xdist 插件可以并行执行测试：

```bash
# 使用 4 个 worker 并行执行
uv run pytest tests/tck/ -n 4

# 结合 --features 选项
uv run pytest tests/tck/ --features=0-original -n 4

# 使用脚本并行执行
./scripts/run_suite.sh --features 0-original -- -n 4
```

### 过滤测试
使用 pytest 的 `-k` 选项可以过滤测试：

```bash
# 排除标记为 ignore 的测试
uv run pytest tests/tck/ -k "not ignore"

# 运行包含特定关键字的测试
uv run pytest tests/tck/ -k "match"
```

### 生成测试报告
```bash
# 生成 Allure 报告
./scripts/generate_report.sh
```

## 测试结果分析

### 测试输出
测试执行时会显示以下信息：
- `PASSED` - 测试通过
- `FAILED` - 测试失败
- `SKIPPED` - 测试被跳过
- `ERROR` - 测试执行出错

### 查看详细结果
1. **控制台输出**：测试执行时会实时显示结果
2. **Allure 报告**：生成详细的 HTML 报告
   ```bash
   ./scripts/generate_report.sh
   ```
3. **测试结果目录**：`allure-results/` 目录包含原始测试结果数据

### 分析失败原因
测试失败通常有以下原因：
1. **数据库连接问题**：检查 GDM 服务是否正在运行，配置是否正确
2. **功能不兼容**：GDM 可能尚未实现某些 Cypher 功能
3. **测试数据问题**：测试需要特定的数据状态
4. **环境问题**：Python 版本、依赖包版本不匹配

## 常见问题

### 1. 如何确认 GDM 服务正在运行？

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


### 2. 测试执行超时怎么办？
- 检查数据库连接是否正常
- 查看 `config/default.toml` 中的超时设置
- 增加 `server.timeouts.connect_secs` 和 `server.timeouts.query_secs` 的值

### 3. 如何跳过某些测试？
- 使用 pytest 的 `-k` 选项过滤
- 在 `.feature` 文件中添加 `@ignore` 标签
- 修改 `config/default.toml` 中的 `test.tags` 配置

### 4. 如何查看测试覆盖率？
```bash
# 安装 pytest-cov
pip install pytest-cov

# 运行测试并生成覆盖率报告
uv run pytest tests/tck/ --cov=src/gdm_tck --cov-report=html
```

### 5. 如何添加新的测试用例？
1. 在 `features/` 目录下创建或修改 `.feature` 文件
2. 如果需要新的步骤定义，在 `steps/` 目录下添加相应的 Python 文件
3. 测试框架会自动发现新的测试用例

### 6. 分布式模式如何配置？
在 `config/default.toml` 中设置：
```toml
[server]
mode = "distributed"
bolt_uris = ["bolt://node1:7690", "bolt://node2:7690", "bolt://node3:7690"]
```
