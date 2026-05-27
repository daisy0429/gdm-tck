"""快捷测试入口
feature 路径是 features/ 目录下的相对路径，例如:
  - "0-opencypher/clauses/match"       → MATCH 子句测试
  - "4-Constraint"                     → 约束测试
  - "3-Index/SecondaryIndex"           → 二级索引测试

"""

from pathlib import Path

from pytest_bdd import scenarios

FEATURES_ROOT = Path(__file__).resolve().parents[2] / "features"

# ============================================================
#  在这里配置你想执行的 feature 路径。每行一个路径，相对于 features/ 目录
#  修改运行配置- 添加环境变量：
#  neo4j:   GDM_TCK_SERVER__BACKEND=neo4j;GDM_TCK_SERVER__BOLT_URI=bolt://10.86.11.245:7687;GDM_TCK_SERVER__USERNAME=neo4j;GDM_TCK_SERVER__PASSWORD=12345678;GDM_TCK_SERVER__DATABASE=neo4j
#  gdm:     GDM_TCK_SERVER__BACKEND=gdm;GDM_TCK_SERVER__BOLT_URI=bolt://10.86.11.245:7690;GDM_TCK_SERVER__USERNAME=admin;GDM_TCK_SERVER__PASSWORD=admin123;GDM_TCK_SERVER__DATABASE=default
#  gdmbase: GDM_TCK_SERVER__BACKEND=gdmbase;GDM_TCK_SERVER__BOLT_URI=bolt://10.86.11.220:23990;GDM_TCK_SERVER__USERNAME=SYSDBA;GDM_TCK_SERVER__PASSWORD=SYSDBA;GDM_TCK_SERVER__DATABASE=default
# ============================================================
# 支持文件夹级别
_QUICK_RUN_PATHS: list[str] = [
    "0-opencypher",
]
# fixme script:时间相关用例，从本地运行会失败。比如  Expected: [{'d': '1816-01-01T00:00Z'}]， Actual:   [{'d': '1816-01-01T00:00+00:00'}]
# "0-opencypher/expressions/temporal",

# ============================================================
#  以下代码自动收集配置的路径，无需修改
# ============================================================
for _rel in _QUICK_RUN_PATHS:
    _target = FEATURES_ROOT / _rel
    if _target.exists():
        _scan_dir = _target if _target.is_dir() else _target.parent
        if _target.is_dir() and not any(_target.rglob("*.feature")):
            continue
        scenarios(str(_scan_dir))
