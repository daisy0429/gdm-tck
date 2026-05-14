"""TCK 测试收集器 - Clauses 模块。

通过 pytest-bdd scenarios() 自动发现并收集
features/0-original/clauses/ 下的所有 .feature 文件。
"""

from pathlib import Path

from pytest_bdd import scenarios

# 相对于本文件的 feature 文件路径
FEATURES_DIR = Path(__file__).resolve().parents[2] / "features" / "0-original" / "clauses"

# 自动为目录中每个 Scenario 生成一个 pytest test 函数
if FEATURES_DIR.exists():
    scenarios(str(FEATURES_DIR))
