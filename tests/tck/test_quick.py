"""快捷测试入口 - 类似 cypher-tck/tck/bvt_test.go。

使用方法:
  1. 修改下方 _QUICK_RUN_PATHS 列表，添加你想执行的 feature 路径
  2. 在 PyCharm 中右键本文件 → Run pytest 即可

也可以指定多个路径（列表中的每一项都会被收集执行）。

feature 路径是 features/ 目录下的相对路径，例如:
  - "4-Constraint"                     → 约束测试
  - "3-Index/SecondaryIndex"           → 二级索引测试
  - "0-original/clauses/match"         → MATCH 子句测试
  - "0-debug"                          → 调试用例
  - "0-original/clauses/match/Match1.feature"  → 单个 feature 文件
"""

from pathlib import Path

from pytest_bdd import scenarios

FEATURES_ROOT = Path(__file__).resolve().parents[2] / "features"

#
# ============================================================
#  在这里配置你想执行的 feature 路径
#  每行一个路径，相对于 features/ 目录
#  GDM_TCK_SERVER__BACKEND=neo4j;GDM_TCK_SERVER__BOLT_URI=bolt://10.86.11.245:7687;GDM_TCK_SERVER__USERNAME=neo4j;GDM_TCK_SERVER__PASSWORD=12345678;GDM_TCK_SERVER__DATABASE=neo4j
# ============================================================
_QUICK_RUN_PATHS: list[str] = [
    "4-Constraint",                     # 约束测试
    "3-Index/SecondaryIndex",           # 二级索引
    "0-original/clauses/match/Match1.feature",  # 单个文件
]

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
