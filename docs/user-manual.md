# GDM TCK 测试框架 - 用户手册

## 1. 概述

GDM TCK (Technology Compatibility Kit) 测试框架用于验证 GDM 图数据库对 openCypher 标准的兼容性。
基于 Python + pytest-bdd，采用 BDD (Behavior-Driven Development) 模式，
通过 Gherkin `.feature` 文件定义测试场景，自动发现并执行。

### 技术栈

| 组件 | 版本 | 用途 |
|---|---|---|
| Python | >= 3.11 | 运行时 |
| uv | latest | 包管理器 |
| pytest | >= 8.2 | 测试框架 |
| pytest-bdd | >= 7.0 | BDD/Gherkin 集成 |
| neo4j (driver) | >= 5.20 | Bolt 协议连接 GDM |
| allure-pytest | >= 2.13 | 测试报告 |
| pytest-xdist | >= 3.5 | 并行执行 |

---

## 2. 快速开始

### 2.1 环境准备

```bash
# 克隆项目后进入目录
cd gdm-tck

# 安装依赖（需要已安装 uv）
uv sync

# 安装 Allure CLI（用于生成报告）
brew install allure
```

### 2.2 配置 GDM 连接

编辑 `config/default.toml`：

```toml
[server]
mode = "standalone"                     # standalone | distributed
bolt_uri = "bolt://10.86.11.245:7690"   # GDM Bolt 协议地址
username = "admin"                      # 认证用户名
password = "admin123"                   # 认证密码
database = "default"                    # 目标图数据库名
```

也可以通过环境变量覆盖（优先级高于配置文件）：

```bash
export GDM_TCK_SERVER__BOLT_URI="bolt://192.168.1.100:7690"
export GDM_TCK_SERVER__USERNAME="myuser"
export GDM_TCK_SERVER__PASSWORD="mypassword"
```

> 环境变量命名规则：前缀 `GDM_TCK_`，双下划线 `__` 表示 TOML 嵌套层级。

### 2.3 运行测试

```bash
# 运行所有 TCK 测试
uv run pytest tests/tck/ -v

# 运行特定模块
uv run pytest tests/tck/test_clauses.py -v       # Cypher 语句
uv run pytest tests/tck/test_expressions.py -v    # 表达式
uv run pytest tests/tck/test_use_cases.py -v      # 使用场景
uv run pytest tests/tck/test_neo4j.py -v          # Neo4j 兼容

# 运行匹配关键字的用例
uv run pytest tests/tck/ -k "create" -v           # 仅 CREATE 相关
uv run pytest tests/tck/ -k "match and not merge"  # MATCH 但排除 MERGE
```

### 2.4 生成测试报告

```bash
# 运行测试并收集 Allure 数据
uv run pytest tests/tck/ --alluredir=reports/allure-results

# 生成 HTML 报告
allure generate reports/allure-results -o reports/allure-report --clean

# 打开报告（浏览器）
allure open reports/allure-report

# 或使用一键脚本
bash scripts/run_suite.sh
bash scripts/generate_report.sh
```

---

## 3. 项目结构

```
gdm-tck/
├── pyproject.toml                  # 项目定义、依赖、pytest 配置
├── config/
│   ├── default.toml                # 默认配置（开发环境）
│   ├── distributed.toml            # 分布式模式配置
│   └── ci.toml                     # CI 流水线配置
├── features/
│   └── 0-original/                 # openCypher TCK 标准 feature 文件
│       ├── clauses/                #   Cypher 语句（CREATE/MATCH/RETURN...）
│       ├── expressions/            #   表达式（布尔/比较/聚合...）
│       ├── neo4j/                  #   Neo4j 特定功能
│       └── useCases/               #   综合使用场景
├── src/gdm_tck/                    # 框架核心代码
│   ├── config.py                   #   配置加载（TOML + 环境变量）
│   ├── exceptions.py               #   自定义异常体系
│   ├── state.py                    #   ScenarioContext（场景状态管理）
│   ├── connection/                 #   连接管理
│   │   ├── agent_patch.py          #     GDM 兼容补丁
│   │   ├── bolt_client.py          #     Bolt 客户端
│   │   └── bolt_pool.py            #     连接池
│   ├── result/                     #   结果处理
│   │   ├── parser.py               #     TCK 值解析
│   │   ├── converter.py            #     Bolt 结果转换
│   │   ├── comparator.py           #     结果比对
│   │   └── side_effects.py         #     副作用断言
│   ├── concurrent/                 #   并发测试
│   │   ├── executor.py             #     并发执行器
│   │   └── workload.py             #     吞吐量测试
│   ├── server/                     #   服务器管理
│   │   ├── health.py               #     健康检查
│   │   └── lifecycle.py            #     生命周期（重启等）
│   └── reporting/                  #   报告集成
│       ├── allure_hooks.py         #     Allure 钩子
│       └── summary.py             #     运行摘要
├── steps/                          # BDD Step Definitions
│   ├── step_graph_init.py          #   Given 步骤（图初始化）
│   ├── step_query_exec.py          #   When 步骤（查询执行）
│   ├── step_result_assert.py       #   Then 步骤（结果断言）
│   ├── step_error_assert.py        #   Then 步骤（错误断言）
│   ├── step_side_effects.py        #   Then 步骤（副作用）
│   └── step_parameters.py          #   Given 步骤（参数设置）
├── tests/
│   ├── conftest.py                 # 顶层 fixtures + plugins 注册
│   └── tck/                        # 测试收集器（按模块）
│       ├── test_clauses.py
│       ├── test_expressions.py
│       ├── test_neo4j.py
│       ├── test_use_cases.py
│       ├── test_ddl.py             # 预留：DDL 测试
│       ├── test_dml.py             # 预留：DML 测试
│       ├── test_index.py           # 预留：索引测试
│       ├── test_constraint.py      # 预留：约束测试
│       └── test_national_std.py    # 预留：国标合规
├── scripts/
│   ├── run_suite.sh                # 测试执行脚本
│   └── generate_report.sh          # 报告生成脚本
└── AGENTS.md                       # Agent 使用文档
```

---

## 4. 配置说明

### 4.1 配置文件

所有配置存放在 `config/` 目录，使用 TOML 格式。通过 `GDM_TCK_CONFIG` 环境变量指定配置文件：

```bash
# 使用默认配置
uv run pytest tests/tck/

# 使用分布式配置
GDM_TCK_CONFIG=config/distributed.toml uv run pytest tests/tck/

# 使用 CI 配置
GDM_TCK_CONFIG=config/ci.toml uv run pytest tests/tck/
```

### 4.2 配置项参考

| 配置项 | 环境变量 | 默认值 | 说明 |
|---|---|---|---|
| `server.bolt_uri` | `GDM_TCK_SERVER__BOLT_URI` | `bolt://10.86.11.245:7690` | Bolt 连接地址 |
| `server.username` | `GDM_TCK_SERVER__USERNAME` | `admin` | 用户名 |
| `server.password` | `GDM_TCK_SERVER__PASSWORD` | `admin123` | 密码 |
| `server.database` | `GDM_TCK_SERVER__DATABASE` | `default` | 数据库名 |
| `server.mode` | `GDM_TCK_SERVER__MODE` | `standalone` | 部署模式 |
| `server.timeouts.connect_secs` | `GDM_TCK_SERVER__TIMEOUTS__CONNECT_SECS` | `30.0` | 连接超时(秒) |
| `server.timeouts.query_secs` | `GDM_TCK_SERVER__TIMEOUTS__QUERY_SECS` | `60.0` | 查询超时(秒) |
| `test.parallel_workers` | `GDM_TCK_TEST__PARALLEL_WORKERS` | `1` | 并行工作线程数 |
| `report.allure_results_dir` | `GDM_TCK_REPORT__ALLURE_RESULTS_DIR` | `allure-results` | Allure 数据目录 |

### 4.3 分布式模式

分布式测试需要配置多个节点 URI：

```toml
[server]
mode = "distributed"
bolt_uri = "bolt://node1:7690"
bolt_uris = [
    "bolt://node1:7690",
    "bolt://node2:7690",
    "bolt://node3:7690",
]
```

---

## 5. 添加新测试

### 5.1 添加新 Feature 文件

1. 在 `features/` 下创建分类目录（如 `features/1-DDL/`）
2. 创建 `.feature` 文件，遵循 Gherkin 语法：

```gherkin
Feature: DDL - Schema Management

  Scenario: Create a node label
    Given an empty graph
    When executing query:
      """
      CREATE (:Person {name: 'Alice'})
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes  | 1 |
      | +labels | 1 |
```

3. 确保对应的测试收集器存在（如 `tests/tck/test_ddl.py`）。现有收集器已预留，
   只需将 feature 文件放到对应目录即可自动发现。

### 5.2 添加新 Step Definition

如果 Feature 文件使用了框架未定义的 step，需要在 `steps/` 目录下添加：

```python
# steps/step_my_custom.py
from pytest_bdd import given, when, then, parsers
from gdm_tck.state import ScenarioContext

@given("a graph with schema constraints")
def graph_with_schema(bolt_pool, scenario_ctx):
    """初始化带有约束的图。"""
    client = bolt_pool.primary
    client.execute("CREATE CONSTRAINT ...", database=scenario_ctx.current_database)
```

然后在 `tests/conftest.py` 中注册新模块：

```python
pytest_plugins = [
    "steps.step_graph_init",
    "steps.step_query_exec",
    # ... 现有模块 ...
    "steps.step_my_custom",  # 添加新模块
]
```

### 5.3 添加新测试收集器

在 `tests/tck/` 下创建新收集器文件：

```python
# tests/tck/test_my_module.py
"""TCK 测试收集器 - 自定义模块。"""

from pathlib import Path
from pytest_bdd import scenarios

FEATURES_DIR = Path(__file__).resolve().parents[2] / "features" / "1-DDL"

if FEATURES_DIR.exists():
    scenarios(str(FEATURES_DIR))
```

---

## 6. 常用命令参考

### 6.1 测试执行

```bash
# 运行所有测试
uv run pytest tests/tck/ -v

# 并行执行（4 个 worker）
uv run pytest tests/tck/ -n 4

# 设置超时（每个用例 30 秒）
uv run pytest tests/tck/ --timeout=30

# 仅列出测试（不执行）
uv run pytest tests/tck/ --co

# 跳过带 @ignore 标记的用例
uv run pytest tests/tck/ -m "not ignore"

# 失败后立即停止
uv run pytest tests/tck/ -x

# 仅重跑上次失败的用例
uv run pytest tests/tck/ --lf
```

### 6.2 报告生成

```bash
# 收集 Allure 数据
uv run pytest tests/tck/ --alluredir=reports/allure-results

# 生成 HTML 报告
allure generate reports/allure-results -o reports/allure-report --clean

# 在浏览器中查看报告
allure open reports/allure-report
```

### 6.3 依赖管理

```bash
# 安装依赖
uv sync

# 添加新依赖
uv add <package-name>

# 安装开发工具
uv sync --extra dev
```

---

## 7. BDD Step 参考

### 7.1 Given 步骤（前置条件）

| Step | 说明 |
|---|---|
| `Given an empty graph` | 清空图数据（MATCH (n) DETACH DELETE n） |
| `Given any graph` | 不要求特定图状态 |
| `Given having executed: """<cypher>"""` | 执行初始化 Cypher 查询 |
| `Given there exists a procedure ...` | 声明存储过程（GDM noop） |

### 7.2 When 步骤（操作）

| Step | 说明 |
|---|---|
| `When executing query: """<cypher>"""` | 执行 Cypher 查询，捕获结果或错误 |

### 7.3 Then 步骤（断言）

| Step | 说明 |
|---|---|
| `Then the result should be empty` | 断言结果集为空 |
| `Then the result should be, in any order:` | 断言结果匹配（无序） |
| `Then the result should be, in order:` | 断言结果匹配（有序） |
| `Then the result should contain:` | 断言结果包含指定行 |
| `Then a <ErrorType> should be raised at compile time: <Detail>` | 断言编译期错误 |
| `Then a <ErrorType> should be raised at runtime: <Detail>` | 断言运行时错误 |
| `Then a <ErrorType> should be raised at any time: <Detail>` | 断言任意阶段错误 |
| `Then an error should be raised` | 断言有任意错误 |
| `Then the side effects should be:` | 断言副作用（节点/关系增删数） |

### 7.4 参数设置

| Step | 说明 |
|---|---|
| `And parameters are:` | 设置查询参数（表格形式） |

---

## 8. 测试结果解读

### 8.1 状态分类

| 状态 | Allure 分类 | 含义 |
|---|---|---|
| **passed** | Passed | GDM 正确实现了该 Cypher 功能 |
| **failed** | Failed | GDM 返回了错误结果（功能缺陷或不兼容） |
| **broken** | Broken | 框架层面问题（缺少 step 定义、连接失败等） |

### 8.2 常见失败原因

| 失败类型 | 说明 | 处理建议 |
|---|---|---|
| `SyntaxError` | GDM 不支持该 Cypher 语法 | 确认 GDM 版本和功能范围 |
| `ResultComparisonError` | 查询结果与预期不符 | 检查 GDM 实现的正确性 |
| `UnknownError` | GDM 内部错误 | 提交 Bug 报告 |
| `StepDefinitionNotFoundError` | 缺少 step 定义 | 在 `steps/` 中添加对应步骤 |
| `Expected error but succeeded` | 预期报错但 GDM 执行成功 | 可能是 GDM 容错处理不同 |

---

## 9. 高级功能

### 9.1 并发测试

框架内置并发执行器，可用于压力和性能测试：

```python
from gdm_tck.concurrent.executor import ConcurrentExecutor

executor = ConcurrentExecutor(bolt_pool)

# 同一查询并发执行
result = executor.run_same_query(
    "MATCH (n) RETURN count(n)",
    workers=10,
    iterations=100
)
print(f"Success: {result.success_count}, Fail: {result.failure_count}")
```

### 9.2 健康检查

```python
from gdm_tck.server.health import wait_for_health

# 等待服务就绪（最多 60 秒）
wait_for_health("bolt://10.86.11.245:7690", ("admin", "admin123"), timeout=60)
```

### 9.3 服务器生命周期管理

```python
from gdm_tck.server.lifecycle import ServerLifecycle

lifecycle = ServerLifecycle(settings)
lifecycle.restart()     # 重启服务器
lifecycle.wait_ready()  # 等待服务就绪
```

---

## 10. 故障排查

### 10.1 连接失败

```
neo4j.exceptions.ServiceUnavailable: Unable to retrieve routing information
```

**排查步骤：**
1. 确认 GDM 服务已启动：`nc -zv <host> <port>`
2. 检查 `config/default.toml` 中的 `bolt_uri` 是否正确
3. 确认用户名密码正确

### 10.2 UnsupportedServerProduct

```
neo4j.exceptions.UnsupportedServerProduct: GDM/0.1.0
```

**原因：** Neo4j 驱动默认拒绝非 Neo4j 服务器。框架已内置 Agent Patch 自动处理。
如果仍然出现，检查 `tests/conftest.py` 是否正确导入了 `bolt_pool` fixture。

### 10.3 Step 未匹配

```
pytest_bdd.exceptions.StepDefinitionNotFoundError: Step definition is not found
```

**处理：** 在 `steps/` 目录下添加对应的 step definition，并在 `tests/conftest.py`
的 `pytest_plugins` 列表中注册。

### 10.4 超时

```
pytest.timeout.TimeoutError: Timeout > 120.0s
```

**处理：** 在 `pyproject.toml` 或命令行中调整超时：
```bash
uv run pytest tests/tck/ --timeout=60   # 设置为 60 秒
```

---

## 11. CI/CD 集成

### 11.1 GitLab CI 示例

```yaml
tck-test:
  stage: test
  image: python:3.11
  variables:
    GDM_TCK_SERVER__BOLT_URI: "bolt://$GDM_HOST:7690"
    GDM_TCK_SERVER__USERNAME: "$GDM_USER"
    GDM_TCK_SERVER__PASSWORD: "$GDM_PASSWORD"
  script:
    - pip install uv
    - cd gdm-tck && uv sync
    - uv run pytest tests/tck/ --alluredir=reports/allure-results --timeout=30
  artifacts:
    paths:
      - gdm-tck/reports/allure-results/
    when: always
```

### 11.2 环境变量配置

CI 环境中推荐使用环境变量而非修改配置文件：

```bash
export GDM_TCK_CONFIG=config/ci.toml
export GDM_TCK_SERVER__BOLT_URI="bolt://gdm-server:7690"
export GDM_TCK_SERVER__USERNAME="ci-user"
export GDM_TCK_SERVER__PASSWORD="ci-password"
```
