"""GDM Agent 兼容补丁模块。

Neo4j Python 驱动默认拒绝非 Neo4j server agent 标识的连接。
GDM 返回 "GDM/" 前缀的 agent，需要 monkey-patch 驱动以接受该标识。
此补丁设计为幂等：多次调用不会重复 patch。
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

_PATCHED = False


def apply_gdm_agent_patch() -> None:
    """应用 GDM agent 兼容补丁到 neo4j 驱动。

    Monkey-patch neo4j 驱动的 server product 检查函数，
    使其接受 "GDM/" 前缀的 server agent 标识。
    需要同时 patch 定义模块和所有使用方模块（from-import 导致本地绑定）。
    幂等设计：重复调用安全。
    """
    global _PATCHED
    if _PATCHED:
        return

    # 需要 patch 的模块列表：定义处 + 所有 from-import 使用方
    target_modules = [
        "neo4j._sync.io._common",
        "neo4j._async.io._common",
        "neo4j._sync.io._bolt4",
        "neo4j._sync.io._bolt5",
        "neo4j._async.io._bolt4",
        "neo4j._async.io._bolt5",
    ]

    for module_path in target_modules:
        try:
            _patch_module(module_path)
        except (ImportError, AttributeError):
            pass

    _PATCHED = True
    logger.debug("GDM agent patch applied successfully")


def _patch_module(module_path: str) -> None:
    """对指定模块中的 check_supported_server_product 应用补丁。"""
    import importlib

    module = importlib.import_module(module_path)
    original_fn = getattr(module, "check_supported_server_product", None)
    if original_fn is None:
        return

    marker = "_gdm_original_check_supported_server_product"
    if hasattr(module, marker):
        return

    setattr(module, marker, original_fn)

    def patched_check(agent: str) -> None:
        """允许 GDM agent 标识通过检查。"""
        if agent and agent.startswith("GDM/"):
            return
        original_fn(agent)

    setattr(module, "check_supported_server_product", patched_check)
