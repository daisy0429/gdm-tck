# GDM TCK 用户手册

## 目录

- [1. 项目简介](#1-项目简介)
- [2. 项目结构](#2-项目结构)
- [3. 环境要求](#3-环境要求)
- [4. 快速开始](#4-快速开始)
- [5. 配置详解](#5-配置详解)
  - [5.1 配置文件](#51-配置文件)
  - [5.2 环境变量覆盖](#52-环境变量覆盖)
  - [5.3 多后端切换](#53-多后端切换)
  - [5.4 分布式模式](#54-分布式模式)
- [6. 运行测试](#6-运行测试)
  - [6.1 运行全部测试](#61-运行全部测试)
  - [6.2 按功能目录运行](#62-按功能目录运行)
  - [6.3 运行预定义套件](#63-运行预定义套件)
  - [6.4 在 IDE 中调试运行](#64-在-ide-中调试运行)
  - [6.5 过滤与跳过测试](#65-过滤与跳过测试)
  - [6.6 并行执行](#66-并行执行)
  - [6.7 其他常用选项](#67-其他常用选项)
- [7. 测试报告](#7-测试报告)
- [8. 环境部署](#8-环境部署)
- [9. 测试用例目录总览](#9-测试用例目录总览)
- [10. 编写新测试](#10-编写新测试)
- [11. 常见问题与故障排查](#11-常见问题与故障排查)

---

## 1. 项目简介

GDM TCK (Technology Compatibility Kit) 是基于 **Python + pytest-bdd** 的 BDD 测试框架，用于验证 GDM 图数据库产品的兼容性。框架通过 Bolt 协议连接图数据库，执行 `.feature` 文件中定义的 Gherkin 场景，并自动验证查询结果。

核心能力：

- **多后端支持** — 同一套测试可运行在 GDM、Neo4j、GdmBase 等不同图库上
- **BDD 驱动** — 以 Gherkin `.feature` 文件描述测试场景，步骤定义自动关联
- **22+ 功能类别** — 覆盖 OpenCypher、DML、DDL、索引、约束、事务、安全、字符集、导入导出、备份恢复、GQL、图计算、CLI、Admin、作业、UDF、分布式、可观测性、容量等
- **Allure 报告** — 自动生成可视化 HTML 测试报告

---

## 2. 项目结构

```
gdm-tck/
├── config/                  # 配置文件
│   ├── default.toml         # 默认配置（GDM 后端）
│   ├── neo4j.toml           # Neo4j 后端配置
│   ├── distributed.toml     # 分布式模式配置覆盖
│   └── ci.toml              # CI 环境配置覆盖
├── features/                # BDD 特征文件（Gherkin .feature）
│   ├── 0-opencypher/        #   OpenCypher 标准兼容
│   ├── 1-metadata/          #   元数据管理
│   ├── 2-DML/               #   数据操作语言
│   ├── 3-Index/             #   索引
│   ├── 4-Constraint/        #   约束
│   ├── 5-Transaction/       #   事务
│   ├── 6-Security/          #   安全/RBAC
│   ├── 7-Charset/           #   字符集
│   ├── 8-ImportExport/      #   导入导出
│   ├── 9-BackupRestore/     #   备份恢复
│   ├── 10-GQL/              #   GQL 语言
│   ├── 11-GraphComputing/   #   图计算
│   ├── 12-GDMCLI/           #   gdm-cli 工具
│   ├── 13-GDMAdmin/         #   gdm-admin 工具
│   ├── 14-Job/              #   作业管理
│   ├── 15-ServerProgramming/#   UDF / 存储过程
│   ├── 16-Distributed/      #   分布式能力
│   ├── 17-Observability/    #   可观测性
│   ├── 18-Capacity/         #   容量/规模上限
│   ├── 20-LDBC/             #   LDBC 标准
│   └── 21-movie/            #   Movie 综合示例
├── steps/                   # BDD 步骤定义（Python）
├── tests/                   # pytest 入口
│   ├── tck/                 #   TCK BDD 测试入口
│   │   ├── conftest.py
│   │   ├── test_quick.py    #     IDE 快捷调试入口
│   │   └── test_index.py ...
│   ├── functional/          #   功能测试
│   └── performance/         #   性能测试
├── scripts/                 # 辅助脚本
│   ├── run_suite.sh         #   测试套件运行
│   ├── generate_report.sh   #   Allure 报告生成
│   └── deploy/              #   环境部署
│       ├── deploy.sh        #     自动部署
│       └── check_health.sh  #     健康检查
├── src/gdm_tck/             # 框架核心代码
│   ├── config.py            #   配置加载
│   ├── state.py             #   场景状态容器
│   ├── exceptions.py        #   自定义异常
│   ├── connection/          #   连接管理（Bolt / gRPC）
│   ├── result/              #   结果解析与比较
│   ├── reporting/           #   报告钩子
│   ├── concurrent/          #   并发执行器
│   └── server/              #   服务生命周期 / 健康检查
├── pyproject.toml           # 项目元数据与依赖
└── USER_GUIDE.md            # 本文件
```

---

## 3. 环境要求

| 依赖 | 版本要求 | 说明 |
|------|---------|------|
| Python | >= 3.11 | 使用 `python3 --version` 确认 |
| uv | 最新版 | 推荐的包管理器，[安装指南](https://docs.astral.sh/uv/) |
| GDM / Neo4j | 运行中 | 需要可访问的 Bolt 端点 |
| Allure | 可选 | 生成 HTML 报告，`brew install allure` (macOS) |

> **注意**：也可以使用 `pip` 代替 `uv`，但本文档所有示例均以 `uv` 为主。使用 `pip` 时将 `uv run` 替换为直接运行命令即可（需先 `pip install -e .`）。

---

## 4. 快速开始

### 步骤一：安装依赖

```bash
# 使用 uv（推荐）
uv sync

# 或使用 pip
pip install -e .
```

### 步骤二：配置数据库连接

编辑 `config/default.toml`，填入实际的连接信息：

```toml
[server]
backend = "gdm"
bolt_uri = "bolt://your-host:7690"
username = "your-username"
password = "your-password"
database = "default"
```

> 也可以不改文件，直接通过环境变量覆盖（见 [5.2 节](#52-环境变量覆盖)）。

### 步骤三：验证框架就绪

```bash
# 收集测试用例（不执行），确认框架能正确发现所有 feature
uv run pytest tests/tck/ --co -q
```

### 步骤四：运行测试

```bash
# 运行全部 TCK 测试
uv run pytest tests/tck/ --alluredir=allure-results

# 运行指定功能的测试
uv run pytest tests/tck/ --features=0-opencypher/clauses/match
```

---

## 5. 配置详解

### 5.1 配置文件

所有配置存储在 `config/` 目录下的 TOML 文件中。主配置文件为 `config/default.toml`：

```toml
# config/default.toml

[server]
backend = "gdm"                        # 后端类型: gdm | neo4j | gdmbase
mode = "standalone"                    # 运行模式: standalone | distributed
bolt_uri = "bolt://10.86.11.245:7690"  # Bolt 端点
bolt_uris = []                         # 分布式模式下的多节点 URI
username = "admin"
password = "admin123"
database = "default"

[server.timeouts]
connect_secs = 30.0                    # 连接超时（秒）
query_secs = 60.0                      # 查询超时（秒）
ready_secs = 300.0                     # 服务就绪等待超时（秒）
retry_interval_secs = 5.0              # 重试间隔
max_retries = 10                       # 最大重试次数

[server.pool]
max_size = 100                         # 连接池大小

[server.metrics]
url = "http://10.86.11.245:9095"       # 指标端点

[grpc]
enabled = false                        # 是否启用 gRPC 连接
address = "10.86.11.245:9830"          # gRPC 地址

[test]
tags = "not ignore"                    # 默认标签过滤表达式
parallel_workers = 1                   # 默认并行 worker 数
feature_base_path = "features"         # feature 文件根目录

[report]
allure_results_dir = "allure-results"  # Allure 原始数据目录

[performance]
default_workers = 4                    # 性能测试默认并发数
default_duration_secs = 30             # 性能测试默认持续时间
```

**内置配置文件一览：**

| 文件 | 用途 |
|------|------|
| `config/default.toml` | GDM 默认配置（基础配置） |
| `config/neo4j.toml` | Neo4j 后端完整配置 |
| `config/distributed.toml` | 分布式模式覆盖（仅覆盖差异项） |
| `config/ci.toml` | CI 环境覆盖（更长超时、多 worker） |

> **配置覆盖规则**：覆盖文件只需包含与 `default.toml` 不同的项，框架会自动深合并。见 [5.3 节](#53-多后端切换)和 [5.4 节](#54-分布式模式)。

### 5.2 环境变量覆盖

任何配置项都可以通过环境变量覆盖。命名规则为 `GDM_TCK_` 前缀 + 配置路径（双下划线 `__` 表示嵌套），值类型自动推断（整数、浮点、布尔、逗号分隔列表）。

```bash
# 基本连接配置
export GDM_TCK_SERVER__BOLT_URI="bolt://localhost:7690"
export GDM_TCK_SERVER__USERNAME="admin"
export GDM_TCK_SERVER__PASSWORD="admin123"
export GDM_TCK_SERVER__DATABASE="default"

# 超时配置
export GDM_TCK_SERVER__TIMEOUTS__QUERY_SECS="120"

# 报告目录
export GDM_TCK_REPORT__ALLURE_RESULTS_DIR="/tmp/allure-results"
```

**优先级（从高到低）**：

1. 环境变量 (`GDM_TCK_*`)
2. 指定配置文件 (`GDM_TCK_CONFIG` 环境变量)
3. `config/default.toml`

### 5.3 多后端切换

GDM TCK 支持对多种 Bolt 兼容图库运行同一套测试，通过 `server.backend` 配置项切换。

**支持的后端：**

| Backend | 说明 | Agent 补丁 |
|---------|------|-----------|
| `gdm` | GDM 图数据库（默认） | 自动 patch，接受 `GDM/` 前缀 |
| `neo4j` | Neo4j | 无需 patch，使用原生驱动 |
| `gdmbase` | GdmBase | 自动 patch，接受 `GdmBase/` 前缀 |

> **原理**：Neo4j Python 驱动默认仅接受 Neo4j 自身的 server agent 标识。GDM 等非 Neo4j 图库返回各自的 agent 前缀（如 `GDM/`），框架会自动 monkey-patch 驱动以兼容。`neo4j` 后端不触发 patch，保持原生行为。如需注册新后端，编辑 `src/gdm_tck/connection/agent_patch.py` 中的 `BACKEND_AGENT_PREFIXES`。

#### 方式一：使用预置配置文件（推荐）

通过 `GDM_TCK_CONFIG` 环境变量指定配置文件（相对于 `config/` 目录）：

```bash
# 基于 GDM 运行（默认，无需额外配置）
uv run pytest tests/tck/ --alluredir=allure-results

# 基于 Neo4j 运行
GDM_TCK_CONFIG=neo4j.toml uv run pytest tests/tck/ --alluredir=allure-results
```

#### 方式二：通过环境变量覆盖

无需修改任何文件，直接通过环境变量切换：

```bash
# 基于 Neo4j 运行
GDM_TCK_SERVER__BACKEND=neo4j \
GDM_TCK_SERVER__BOLT_URI=bolt://your-neo4j-host:7687 \
GDM_TCK_SERVER__USERNAME=neo4j \
GDM_TCK_SERVER__PASSWORD=your-password \
GDM_TCK_SERVER__DATABASE=neo4j \
uv run pytest tests/tck/ --alluredir=allure-results
```

#### 方式三：修改配置文件

直接编辑 `config/default.toml` 中的 `server.backend` 及相关连接参数。

**注意事项：**

- 切换后端后确保目标图库服务正在运行且连接信息正确
- 不同后端的默认端口可能不同：GDM 通常为 `7690`，Neo4j 通常为 `7687`
- 不同后端的默认数据库名称不同：GDM 使用 `default`，Neo4j 使用 `neo4j`
- 使用未注册的后端标识时，框架会发出警告且不应用 agent 补丁

### 5.4 分布式模式

编辑 `config/default.toml` 或使用覆盖配置切换到分布式模式：

```toml
[server]
mode = "distributed"
bolt_uris = ["bolt://node1:7690", "bolt://node2:7690", "bolt://node3:7690"]
```

或使用预置覆盖文件：

```bash
GDM_TCK_CONFIG=distributed.toml uv run pytest tests/tck/ --alluredir=allure-results
```

也可以通过环境变量覆盖：

```bash
export GDM_TCK_SERVER__MODE="distributed"
export GDM_TCK_SERVER__BOLT_URIS="bolt://node1:7690,bolt://node2:7690,bolt://node3:7690"
```

> **注意**：分布式模式下 `bolt_uris` 必须非空，否则配置验证会报错。

---

## 6. 运行测试

### 6.1 运行全部测试

```bash
# 运行全部 TCK 测试
uv run pytest tests/tck/ --alluredir=allure-results

# 使用脚本运行
./scripts/run_suite.sh tck

# 运行项目所有测试（含功能测试、性能测试）
uv run pytest tests/ --alluredir=allure-results
./scripts/run_suite.sh all
```

### 6.2 按功能目录运行

使用 `--features` 选项指定 `features/` 目录下的子路径：

```bash
# 运行 0-opencypher 下所有测试
uv run pytest tests/tck/ --features=0-opencypher

# 运行具体子目录
uv run pytest tests/tck/ --features=0-opencypher/expressions/aggregation

# 运行 1-metadata 下的并发测试
uv run pytest tests/tck/ --features=1-metadata/Concurrent

# 运行指定 .feature 文件
uv run pytest tests/tck/ --features=3-Index/SecondaryIndex/01_index_node_create.feature

# 结合配置文件与报告
GDM_TCK_CONFIG=neo4j.toml uv run pytest tests/tck/ \
    --features=4-Constraint/debug.feature -p no:warnings \
    --alluredir=allure-results

# 使用脚本（通过 -- 分隔脚本参数与 pytest 参数）
./scripts/run_suite.sh --features 0-opencypher/clauses/match
```

### 6.3 运行预定义套件

使用 `run_suite.sh` 脚本运行预定义的测试套件：

```bash
./scripts/run_suite.sh <套件名>
```

**可用的套件名：**

| 套件名 | 说明 | 对应测试入口 |
|--------|------|-------------|
| `tck` | 全部 TCK 测试 | `tests/tck/` |
| `clauses` | Cypher 子句测试 | `tests/tck/test_clauses.py` |
| `expressions` | Cypher 表达式测试 | `tests/tck/test_expressions.py` |
| `ddl` | DDL 测试 | `tests/tck/test_ddl.py` |
| `dml` | DML 测试 | `tests/tck/test_dml.py` |
| `index` | 索引测试 | `tests/tck/test_index.py` |
| `constraint` | 约束测试 | `tests/tck/test_constraint.py` |
| `national_std` | 国家标准测试 | `tests/tck/test_national_std.py` |
| `capacity` | 容量测试 | `tests/tck/test_capacity.py` |
| `functional` | 功能测试 | `tests/functional/` |
| `performance` | 性能测试 | `tests/performance/` |
| `all` | 全部测试 | `tests/` |

示例：

```bash
# 运行约束测试套件
./scripts/run_suite.sh constraint

# 运行全部测试
./scripts/run_suite.sh all
```

### 6.4 在 IDE 中调试运行

`tests/tck/test_quick.py` 是为 IDE 调试设计的快捷入口。修改其中的 `_QUICK_RUN_PATHS` 列表来指定要运行的 feature 路径：

```python
# tests/tck/test_quick.py
_QUICK_RUN_PATHS: list[str] = [
    "0-opencypher",
    # "4-Constraint",
    # "3-Index/SecondaryIndex",
]
```

然后在 IDE（如 PyCharm）中右键运行该文件，即可在 IDE 测试运行器中查看文件树和执行结果详情。

> **提示**：如需切换后端，在 IDE 运行配置中添加环境变量：
> - Neo4j: `GDM_TCK_SERVER__BACKEND=neo4j;GDM_TCK_SERVER__BOLT_URI=bolt://host:7687;GDM_TCK_SERVER__USERNAME=neo4j;GDM_TCK_SERVER__PASSWORD=xxx;GDM_TCK_SERVER__DATABASE=neo4j`
> - GDM: `GDM_TCK_SERVER__BACKEND=gdm;GDM_TCK_SERVER__BOLT_URI=bolt://host:7690;GDM_TCK_SERVER__USERNAME=admin;GDM_TCK_SERVER__PASSWORD=admin123;GDM_TCK_SERVER__DATABASE=default`

### 6.5 过滤与跳过测试

```bash
# 使用 -k 按关键字过滤
uv run pytest tests/tck/ -k "match"

# 排除带 @ignore 标签的测试（已默认启用）
uv run pytest tests/tck/ -k "not ignore"

# 使用 -m 按标记过滤
uv run pytest tests/tck/ -m "not ignore"

# 跳过因已知 bug 标记的测试
uv run pytest tests/tck/ -m "not skip_bug"
```

在 `.feature` 文件中使用标签控制跳过：

```gherkin
@ignore
Feature: 暂不执行的测试
  ...

@skip_bug
Scenario: 已知 bug 待修复
  ...
```

可用的标记：`ignore`、`skip_bug`、`skip_script`、`skipGrammarCheck`、`skipStyleCheck`、`allowCustomErrors`、`todo-ldbc` 等。

### 6.6 并行执行

使用 pytest-xdist 插件并行执行：

```bash
# 使用 4 个 worker 并行
uv run pytest tests/tck/ -n 4

# 结合 --features 选项
uv run pytest tests/tck/ --features=0-opencypher -n 4

# 使用脚本并行
./scripts/run_suite.sh --features 0-opencypher -- -n 4
```

> **注意**：并行执行时每个 worker 拥有独立的场景状态（`ScenarioContext`），不会相互干扰。但并发测试（`features/1-metadata/Concurrent`）本身设计为验证并发行为，不建议与 `-n` 并行叠加使用。

### 6.7 其他常用选项

```bash
# 设置单用例超时（覆盖配置文件中的默认 120 秒）
uv run pytest tests/tck/ --timeout=30

# 遇到第一个失败立即停止
uv run pytest tests/tck/ -x

# 仅重跑上次失败的用例
uv run pytest tests/tck/ --lf

# 显示详细输出（包括完整的 Cypher 语句和结果对比）
uv run pytest tests/tck/ -v -s

# 关闭警告输出
uv run pytest tests/tck/ -p no:warnings
```

---

## 7. 测试报告

### 7.1 生成 Allure 报告

```bash
# 第一步：运行测试，收集 Allure 数据
uv run pytest tests/tck/ --alluredir=allure-results

# 第二步：生成 HTML 报告
allure generate allure-results -o allure-report --clean

# 第三步：在浏览器中查看
allure open allure-report
```

或使用一键脚本：

```bash
# 运行测试后生成报告
./scripts/generate_report.sh allure-results allure-report
```

### 7.2 自定义报告目录

默认报告数据输出到 `allure-results`，可以通过配置或环境变量修改：

```bash
# 通过环境变量指定
export GDM_TCK_REPORT__ALLURE_RESULTS_DIR="/tmp/allure-results"

# 或在 pytest 命令行直接指定
uv run pytest tests/tck/ --alluredir=/tmp/allure-results
```

### 7.3 测试结果状态

| 状态 | 含义 |
|------|------|
| `PASSED` | 测试通过 |
| `FAILED` | 测试失败，需排查原因 |
| `SKIPPED` | 测试被跳过（标签过滤或条件不满足） |
| `ERROR` | 测试执行出错（通常是框架或环境问题） |

---

## 8. 环境部署

### 8.1 自动部署

使用 `deploy.sh` 脚本自动部署 GDM 测试环境：

```bash
# 完整部署（下载 + 安装 + 启动 + 健康检查）
./scripts/deploy/deploy.sh -u <下载URL> -m standalone

# 跳过下载，使用服务器已有安装包
./scripts/deploy/deploy.sh -p /path/to/package -m standalone --skip-download

# 部署集群模式
./scripts/deploy/deploy.sh -u <下载URL> -m cluster
```

**常用选项：**

| 选项 | 说明 |
|------|------|
| `-u, --url <URL>` | 安装包下载链接 |
| `-m, --mode <MODE>` | 部署模式：`standalone`、`cluster`、`all`（默认） |
| `-s, --skip-download` | 跳过下载，使用已有安装包 |
| `-p, --pkg-path <PATH>` | 指定已有安装包路径 |
| `--no-stop` | 不停止已有服务 |
| `--no-verify` | 跳过环境可用性验证 |

### 8.2 健康检查

```bash
# 检查所有服务
./scripts/deploy/check_health.sh

# 仅检查单机版
./scripts/deploy/check_health.sh -m standalone

# 仅检查集群版
./scripts/deploy/check_health.sh -m cluster

# 等待服务就绪（带超时，适合 CI 脚本）
./scripts/deploy/check_health.sh -m all -w
```

---

## 9. 测试用例目录总览

`features/` 目录下按功能类别组织，编号对应测试领域：

| 目录 | 类别 | 说明 |
|------|------|------|
| `0-opencypher/` | OpenCypher | 标准 Cypher 兼容性（子句、表达式、字面量、数学运算、模式匹配等） |
| `0-debug/` | 调试 | 临时调试用 feature |
| `1-metadata/` | 元数据 | 图、标签、属性等元数据管理与并发操作 |
| `2-DML/` | DML | 数据操作语言（CREATE、MERGE、DELETE、SET 等） |
| `3-Index/` | 索引 | 全文索引、二级索引、向量索引等 |
| `4-Constraint/` | 约束 | 唯一约束、存在约束、键约束等 |
| `5-Transaction/` | 事务 | 事务隔离、并发事务行为 |
| `6-Security/` | 安全 | 用户认证、角色、权限控制 (RBAC) |
| `7-Charset/` | 字符集 | 多语言字符集兼容性 |
| `8-ImportExport/` | 导入导出 | 数据批量导入导出 |
| `9-BackupRestore/` | 备份恢复 | 数据库备份与恢复 |
| `10-GQL/` | GQL | GQL 语言特性（操作符、子句、函数、模式、元数据） |
| `11-GraphComputing/` | 图计算 | 图算法与计算引擎 |
| `12-GDMCLI/` | CLI | gdm-cli 命令行工具自动化 |
| `13-GDMAdmin/` | Admin | gdm-admin 管理工具自动化 |
| `14-Job/` | 作业 | 异步作业管理 |
| `15-ServerProgramming/` | 服务端编程 | UDF（用户定义函数）与存储过程 |
| `16-Distributed/` | 分布式 | 分布式集群能力 |
| `17-Observability/` | 可观测性 | 监控指标、日志、慢查询 |
| `18-Capacity/` | 容量 | 数据库容量与规模上限 |
| `20-LDBC/` | LDBC | LDBC 标准兼容 |
| `21-movie/` | Movie 示例 | 综合示例（电影数据集） |

---

## 10. 编写新测试

### 10.1 创建 Feature 文件

在 `features/` 目录下对应功能类别中创建 `.feature` 文件，使用标准 Gherkin 语法：

```gherkin
# features/3-Index/MyNewIndex/01_my_test.feature
Feature: 我的索引测试

  Scenario: 创建节点索引
    Given parameters are:
      | label | property |
      | Person | name |
    When executing query:
      """
      CREATE INDEX FOR (n:Person) ON (n.name)
      """
    Then the result should be empty

  Scenario: 查询已有索引
    When executing query:
      """
      SHOW INDEXES
      """
    Then the result should contain:
      | label  | property |
      | Person | name    |
```

### 10.2 步骤定义

框架已提供丰富的通用步骤定义（位于 `steps/` 目录），大多数场景无需编写新的步骤代码：

| 步骤文件 | 功能 |
|---------|------|
| `step_query_exec.py` | 查询执行（`When executing query`） |
| `step_result_assert.py` | 结果断言（`Then the result should be`） |
| `step_side_effects.py` | 副作用断言 |
| `step_error_assert.py` | 错误断言（`Then an error should be raised`） |
| `step_parameters.py` | 参数设置（`Given parameters are`） |
| `step_graph_init.py` | 图初始化与清理 |
| `step_schema_assert.py` | Schema 验证 |
| `step_plan_assert.py` | 执行计划断言 |

如果现有步骤无法满足需求，在 `steps/` 目录下创建新的 Python 文件，使用 `@when`、`@then`、`@given` 装饰器定义新步骤即可。框架会自动发现。

### 10.3 自动发现

新增 `.feature` 文件后无需额外注册，pytest-bdd 会自动扫描 `features/` 目录。

---

## 11. 常见问题与故障排查

### Q1: 如何确认 GDM 服务正在运行？

```bash
# 快速健康检查
./scripts/deploy/check_health.sh

# 仅检查单机版
./scripts/deploy/check_health.sh -m standalone

# 等待服务就绪（带超时）
./scripts/deploy/check_health.sh -m all -w
```

### Q2: 连接超时怎么办？

1. 确认数据库服务正在运行且网络可达
2. 检查 `config/default.toml` 中的 `bolt_uri` 是否正确
3. 增大超时时间：

```bash
# 通过环境变量临时增大
export GDM_TCK_SERVER__TIMEOUTS__CONNECT_SECS="60"
export GDM_TCK_SERVER__TIMEOUTS__QUERY_SECS="300"

# 或修改配置文件
# [server.timeouts]
# connect_secs = 60.0
# query_secs = 300.0
```

### Q3: 测试全部 FAILED 且报 Agent 错误？

这通常说明后端类型配置与实际图库不匹配。Neo4j 驱动仅接受 Neo4j agent，连接 GDM 时必须将 `backend` 设为 `gdm` 以触发 agent 补丁：

```bash
# 确认当前配置
uv run python -c "from gdm_tck.config import load_settings; s = load_settings(); print(s.server.backend, s.server.bolt_uri)"
```

### Q4: 如何跳过某些测试？

- **命令行过滤**：`uv run pytest tests/tck/ -k "not ignore"`
- **Feature 标签**：在 `.feature` 文件中添加 `@ignore` 或 `@skip_bug` 标签
- **配置文件**：修改 `config/default.toml` 中的 `test.tags` 表达式

### Q5: 如何只重跑失败的测试？

```bash
# 第一次运行
uv run pytest tests/tck/ --alluredir=allure-results

# 仅重跑失败用例
uv run pytest tests/tck/ --lf
```

### Q6: 时区相关用例本地运行失败？

这是已知问题。部分时间/时区相关用例在不同时区环境下结果不同，属于环境差异而非功能缺陷。可以跳过这些用例：

```bash
uv run pytest tests/tck/ --features=0-opencypher -k "not temporal"
```

### Q7: 如何查看测试覆盖率？

```bash
# 安装 pytest-cov
uv add --dev pytest-cov

# 运行并生成覆盖率报告
uv run pytest tests/tck/ --cov=src/gdm_tck --cov-report=html
# 报告生成在 htmlcov/ 目录
```

### Q8: 报 `ConfigurationError: server.bolt_uri must not be empty`？

确保配置文件中的 `server.bolt_uri` 不为空，或通过环境变量提供：

```bash
export GDM_TCK_SERVER__BOLT_URI="bolt://your-host:7690"
```

### Q9: 如何注册新的图库后端？

在 `src/gdm_tck/connection/agent_patch.py` 的 `BACKEND_AGENT_PREFIXES` 字典中添加新条目：

```python
BACKEND_AGENT_PREFIXES: dict[str, list[str]] = {
    "gdm": ["GDM/"],
    "gdmbase": ["GdmBase/"],
    "your-backend": ["YourPrefix/"],  # 新增
}
```

### Q10: 分布式模式报 `server.bolt_uris must be provided`？

分布式模式要求 `bolt_uris` 列表非空。请检查：

```toml
[server]
mode = "distributed"
bolt_uris = ["bolt://node1:7690", "bolt://node2:7690", "bolt://node3:7690"]
```
