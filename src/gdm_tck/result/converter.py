"""Bolt 查询结果转换模块。

将 neo4j 驱动返回的原生对象转换为可比较的标准化 Python 对象。
"""

from __future__ import annotations

from typing import Any

import neo4j
import neo4j.graph
import neo4j.time


def convert_bolt_record(record: dict[str, Any]) -> dict[str, Any]:
    """将单条 Bolt 记录转换为可比较格式。

    Args:
        record: neo4j Record 转为的字典。

    Returns:
        标准化后的字典，所有图对象被转为纯 Python 数据结构。
    """
    return {key: simplify_value(value) for key, value in record.items()}


def simplify_value(value: Any) -> Any:
    """递归简化 neo4j 驱动返回值为可比较的 Python 基本类型。

    处理类型：Node, Relationship, Path, 时间类型, 空间类型, 列表, 字典。

    Args:
        value: neo4j 驱动返回的任意值。

    Returns:
        简化后的 Python 对象。
    """
    if value is None:
        return None
    if isinstance(value, neo4j.graph.Node):
        return _simplify_node(value)
    if isinstance(value, neo4j.graph.Relationship):
        return _simplify_relationship(value)
    if isinstance(value, neo4j.graph.Path):
        return _simplify_path(value)
    if isinstance(value, list):
        return [simplify_value(item) for item in value]
    if isinstance(value, dict):
        return {k: simplify_value(v) for k, v in value.items()}
    # 时间类型
    if _is_temporal(value):
        return _format_temporal(value)
    # 空间类型
    if _is_spatial(value):
        return _simplify_spatial(value)
    # 基本类型直接返回
    return value


def _simplify_node(node: neo4j.graph.Node) -> dict:
    """将 Node 转为标准化字典。"""
    return {
        "_type": "node",
        "labels": sorted(node.labels),
        "properties": {k: simplify_value(v) for k, v in dict(node).items()},
    }


def _simplify_relationship(rel: neo4j.graph.Relationship) -> dict:
    """将 Relationship 转为标准化字典。"""
    return {
        "_type": "relationship",
        "rel_type": rel.type,
        "properties": {k: simplify_value(v) for k, v in dict(rel).items()},
    }


def _simplify_path(path: neo4j.graph.Path) -> dict:
    """将 Path 转为标准化字典。"""
    nodes = [_simplify_node(node) for node in path.nodes]
    relationships = [_simplify_relationship(rel) for rel in path.relationships]
    return {
        "_type": "path",
        "nodes": nodes,
        "relationships": relationships,
    }


def _is_temporal(value: Any) -> bool:
    """判断是否为 neo4j 时间类型。"""
    temporal_types = (
        neo4j.time.Date,
        neo4j.time.Time,
        neo4j.time.DateTime,
        neo4j.time.Duration,
    )
    return isinstance(value, temporal_types)


def _format_temporal(value: Any) -> str:
    """格式化 neo4j 时间类型为 TCK 兼容的紧凑格式。

    neo4j str() 总是输出纳秒精度（如 '10:35:00.000000000'），
    但 TCK 期望简洁格式（如 '10:35'）。当纳秒和秒都为 0 时省略。
    """
    if isinstance(value, neo4j.time.Date):
        return str(value)
    if isinstance(value, neo4j.time.DateTime):
        return _format_datetime(value)
    if isinstance(value, neo4j.time.Time):
        return _format_time(value)
    return str(value)


def _format_time(value: neo4j.time.Time) -> str:
    """格式化 Time 为紧凑格式。"""
    ns = value.nanosecond
    sec = value.second
    if ns == 0 and sec == 0:
        time_str = f"{value.hour:02d}:{value.minute:02d}"
    elif ns == 0:
        time_str = f"{value.hour:02d}:{value.minute:02d}:{sec:02d}"
    else:
        frac = f"{ns:09d}".rstrip("0")
        time_str = f"{value.hour:02d}:{value.minute:02d}:{sec:02d}.{frac}"
    if value.tzinfo is not None:
        offset = value.tzinfo.utcoffset(None)
        if offset is not None:
            offset_secs = int(offset.total_seconds())
            sign = "+" if offset_secs >= 0 else "-"
            abs_secs = abs(offset_secs)
            offset_h, offset_m = divmod(abs_secs // 60, 60)
            time_str += f"{sign}{offset_h:02d}:{offset_m:02d}"
    return time_str


def _format_datetime(value: neo4j.time.DateTime) -> str:
    """格式化 DateTime 为紧凑格式。"""
    ns = value.nanosecond
    sec = value.second
    if ns == 0 and sec == 0:
        dt_str = f"{value.year:04d}-{value.month:02d}-{value.day:02d}T{value.hour:02d}:{value.minute:02d}"
    elif ns == 0:
        dt_str = (
            f"{value.year:04d}-{value.month:02d}-{value.day:02d}"
            f"T{value.hour:02d}:{value.minute:02d}:{sec:02d}"
        )
    else:
        frac = f"{ns:09d}".rstrip("0")
        dt_str = (
            f"{value.year:04d}-{value.month:02d}-{value.day:02d}"
            f"T{value.hour:02d}:{value.minute:02d}:{sec:02d}.{frac}"
        )
    if value.tzinfo is not None:
        offset = value.tzinfo.utcoffset(None)
        if offset is not None:
            offset_secs = int(offset.total_seconds())
            sign = "+" if offset_secs >= 0 else "-"
            abs_secs = abs(offset_secs)
            offset_h, offset_m = divmod(abs_secs // 60, 60)
            dt_str += f"{sign}{offset_h:02d}:{offset_m:02d}"
    return dt_str


def _is_spatial(value: Any) -> bool:
    """判断是否为空间类型。"""
    module = type(value).__module__
    return module.startswith("neo4j.spatial") if module else False


def _simplify_spatial(value: Any) -> dict:
    """将空间类型转为字典表示。"""
    result = {"_type": "point", "srid": getattr(value, "srid", None)}
    if hasattr(value, "x"):
        result["x"] = value.x
    if hasattr(value, "y"):
        result["y"] = value.y
    if hasattr(value, "z"):
        result["z"] = value.z
    return result
