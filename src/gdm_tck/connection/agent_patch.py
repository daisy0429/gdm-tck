"""Bolt 兼容图库 Agent 补丁模块。

Neo4j Python 驱动默认仅接受 Neo4j server agent 标识。
其他 Bolt 兼容图库（如 GDM、Memgraph）返回各自前缀的 agent，
需要 monkey-patch 驱动以接受这些标识。

通过 BACKEND_AGENT_PREFIXES 字典管理各 backend 的允许前缀。
不在字典中的 backend（如 neo4j）不会触发 patch，保持原生行为。
此补丁设计为幂等：多次调用不会重复 patch。
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

_PATCHED = False
_PATCHED_PREFIXES: list[str] = []

BACKEND_AGENT_PREFIXES: dict[str, list[str]] = {
    "gdm": ["GDM/"],
    "memgraph": ["Memgraph/"],
}

_TARGET_MODULES = [
    "neo4j._sync.io._common",
    "neo4j._async.io._common",
    "neo4j._sync.io._bolt4",
    "neo4j._sync.io._bolt5",
    "neo4j._async.io._bolt4",
    "neo4j._async.io._bolt5",
]


def apply_agent_patch(backend: str) -> None:
    """按 backend 类型应用 agent 兼容补丁。

    仅当 backend 在 BACKEND_AGENT_PREFIXES 中注册了非空前缀列表时才 patch。
    neo4j 等原生支持的 backend 不在字典中，自动跳过。

    Args:
        backend: 后端类型标识，如 "gdm"、"neo4j"、"memgraph"。
    """
    global _PATCHED, _PATCHED_PREFIXES

    prefixes = BACKEND_AGENT_PREFIXES.get(backend, [])
    if not prefixes:
        logger.debug("Backend '%s' requires no agent patch", backend)
        return

    if _PATCHED:
        logger.debug("Agent patch already applied for prefixes: %s", _PATCHED_PREFIXES)
        return

    for module_path in _TARGET_MODULES:
        try:
            _patch_module(module_path, prefixes)
        except (ImportError, AttributeError):
            pass

    _PATCHED = True
    _PATCHED_PREFIXES = prefixes
    logger.debug("Agent patch applied for backend '%s', prefixes: %s", backend, prefixes)


def apply_gdm_agent_patch() -> None:
    """向后兼容入口：应用 GDM agent 补丁。"""
    apply_agent_patch("gdm")


def _patch_module(module_path: str, prefixes: list[str]) -> None:
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
        """允许注册前缀的 agent 标识通过检查。"""
        if agent and any(agent.startswith(p) for p in prefixes):
            return
        original_fn(agent)

    setattr(module, "check_supported_server_product", patched_check)
