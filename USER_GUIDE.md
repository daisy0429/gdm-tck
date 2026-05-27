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
  - [运行指定图库后端的测试](#运行指定图库后端的测试)
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
# 运行所有 TCK 测试并生成 Allure 报告
uv run pytest tests/tck/ --alluredir=reports/allure-results

# 运行指定测试用例目录下的测试
uv run pytest tests/tck/ --features=0-opencypher/expressions/aggregation --alluredir=reports/allure-results
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
uv run pytest tests/tck/ --alluredir=reports/allure-results

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
# 运行 0-opencypher 目录下的所有测试
uv run pytest tests/tck/ --features=0-opencypher

# 运行 0-opencypher/expressions/aggregation 目录下的测试
uv run pytest tests/tck/ --features=0-opencypher/expressions/aggregation


# 运行 1-metadata/Concurrent 目录下的测试
uv run pytest tests/tck/ --features=1-metadata/Concurrent

# 运行指定feature文件
GDM_TCK_CONFIG=config/neo4j.toml uv run pytest tests/tck/ --features=3-Index/SecondaryIndex/01_index_node_create.feature -p no:warnings

# 运行任意指定的单个或多个feature文件夹。在 test_quick.py 中指定，文件右键运行（可使用pycharm测试运行器查看到文件树和执行结果详情）
tests/tck/test_quick.py

# 使用脚本运行
./scripts/run_suite.sh --features 0-opencypher/clauses/match
```

### 运行指定图库后端的测试

GDM TCK 支持对多种 Bolt 兼容图库运行测试，通过 `server.backend` 配置项切换后端。当前支持的后端：

| Backend | 说明 | Agent 补丁 |
|---------|------|-----------|
| `gdm` | GDM 图数据库（默认） | 自动 patch，接受 `GDM/` 前缀 |
| `neo4j` | Neo4j | 无需 patch，使用原生驱动 |
| `gdmbase` | GdmBase | 自动 patch，接受 `GdmBase/` 前缀 |

> **原理**：Neo4j Python 驱动默认仅接受 Neo4j 自身的 server agent 标识。GDM 等非 Neo4j 图库返回各自的 agent 前缀（如 `GDM/`），框架会自动 monkey-patch 驱动以兼容。`neo4j` 后端不会触发 patch，保持原生行为。


以下三种方式优先级：环境变量 > 指定配置文件 > default.toml。

#### 方式一：使用预置配置文件（推荐）

项目内置了各后端的配置文件，通过 `GDM_TCK_CONFIG` 环境变量指定：

```bash
# 基于 GDM 运行（默认）
uv run pytest tests/tck/ --alluredir=reports/allure-results

# 基于 Neo4j 运行
GDM_TCK_CONFIG=neo4j.toml uv run pytest tests/tck/ --alluredir=reports/allure-results
GDM_TCK_CONFIG=neo4j.toml uv run pytest tests/tck/ --features=4-Constraint/debug.feature -p no:warnings
```

内置配置文件一览：

| 文件 | 用途 |
|------|------|
| `config/default.toml` | GDM 默认配置 |
| `config/neo4j.toml` | Neo4j 后端配置 |
| `config/distributed.toml` | 分布式模式配置覆盖 |
| `config/ci.toml` | CI 环境配置覆盖 |

#### 方式二：通过环境变量覆盖

无需修改配置文件，直接通过环境变量切换后端和连接信息：
环境变量优先级高于配置文件。

```bash
# 基于 GDM 运行
GDM_TCK_SERVER__BACKEND=gdm \
GDM_TCK_SERVER__BOLT_URI=bolt://your-gdm-host:7690 \
GDM_TCK_SERVER__USERNAME=admin \
GDM_TCK_SERVER__PASSWORD=admin123 \
uv run pytest tests/tck/ --alluredir=reports/allure-results

# 基于 Neo4j 运行
GDM_TCK_SERVER__BACKEND=neo4j \
GDM_TCK_SERVER__BOLT_URI=bolt://your-neo4j-host:7687 \
GDM_TCK_SERVER__USERNAME=neo4j \
GDM_TCK_SERVER__PASSWORD=your-password \
GDM_TCK_SERVER__DATABASE=neo4j \
uv run pytest tests/tck/ --alluredir=reports/allure-results
```

#### 方式三：修改配置文件

编辑 `config/default.toml`，修改 `server.backend` 及相关连接参数：

```toml
# 切换到 Neo4j
[server]
backend = "neo4j"
bolt_uri = "bolt://localhost:7687"
username = "neo4j"
password = "your-password"
database = "neo4j"

# 切换回 GDM
[server]
backend = "gdm"
bolt_uri = "bolt://localhost:7690"
username = "admin"
password = "admin123"
database = "default"
```

#### 注意事项

- 切换后端后，请确保目标图库服务正在运行且连接信息正确
- 不同后端的默认端口不同：Neo4j 通常使用 `7687`
- 不同后端的默认数据库名称不同：GDM 使用 `default`，Neo4j 使用 `neo4j`
- 如果使用未注册的后端标识（非 `gdm`/`neo4j`/`gdmbase`），框架会发出警告且不应用 agent 补丁；若该图库使用非标准 agent 前缀，需在 `src/gdm_tck/connection/agent_patch.py` 的 `BACKEND_AGENT_PREFIXES` 中注册

### 并行执行
使用 pytest-xdist 插件可以并行执行测试：

```bash
# 使用 4 个 worker 并行执行
uv run pytest tests/tck/ -n 4

# 结合 --features 选项
uv run pytest tests/tck/ --features=0-opencypher -n 4

# 使用脚本并行执行
./scripts/run_suite.sh --features 0-opencypher -- -n 4
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
# 运行测试并收集allure数据，生成allure报告
GDM_TCK_CONFIG=config/neo4j.toml uv run pytest tests/tck/ --features=0-opencypher/expressions/aggregation --alluredir=reports/allure-results
./scripts/generate_report.sh reports/allure-results reports/allure-report
（generate_report.sh 默认读取 allure-results 目录）

# 运行测试并收集 Allure 数据
uv run pytest tests/tck/ --alluredir=reports/allure-results

# 生成 HTML 报告
allure generate reports/allure-results -o reports/allure-report --clean

# 在浏览器中查看报告
allure open reports/allure-report

# 或使用一键脚本
bash scripts/run_suite.sh
bash scripts/generate_report.sh
```
### 其他常用命令参考 

```
# 设置超时（每个用例 30 秒）
uv run pytest tests/tck/ --timeout=30

# 跳过带 @ignore 标记的用例
uv run pytest tests/tck/ -m "not ignore"

# 失败后立即停止
uv run pytest tests/tck/ -x

# 仅重跑上次失败的用例
uv run pytest tests/tck/ --lf

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
