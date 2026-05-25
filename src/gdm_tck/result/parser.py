"""TCK 表格值解析器模块。

将 Gherkin feature 文件中数据表格的单元格文本解析为 Python 对象，
支持 openCypher TCK 规范中的所有值表示格式。
"""

from __future__ import annotations

import json
import re
from typing import Any


def parse_tck_value(text: str) -> Any:
    """解析 TCK 表格单元格中的值表示。

    支持格式：
    - null
    - 布尔: true / false
    - 整数: 42, -1
    - 浮点: 3.14, -0.5, Inf, NaN
    - 字符串: 'hello' (单引号包围)
    - 列表: [1, 2, 3]
    - Map: {key: value}
    - Node: (:Label {prop: value})
    - Relationship: [:TYPE {prop: value}]
    - Path: <(:A)-[:R]->(:B)>

    Args:
        text: 单元格文本内容。

    Returns:
        解析后的 Python 对象。
    """
    text = text.strip()
    if not text:
        return None
    # null
    if text == "null":
        return None
    # 布尔
    if text == "true":
        return True
    if text == "false":
        return False
    # 整数
    if re.match(r"^-?\d+$", text):
        return int(text)
    # 浮点
    if _is_float(text):
        return _parse_float(text)
    # 字符串（单引号包围）
    if text.startswith("'") and text.endswith("'"):
        return text[1:-1]
    # 字符串（双引号包围）
    if text.startswith('"') and text.endswith('"'):
        return text[1:-1]
    # Relationship 表示: [:TYPE {prop: value}] (必须在列表判断之前)
    if text.startswith("[:") and text.endswith("]"):
        return _parse_relationship(text)
    # 列表
    if text.startswith("[") and text.endswith("]"):
        return _parse_list(text)
    # Map
    if text.startswith("{") and text.endswith("}"):
        return _parse_map(text)
    # Node 表示: (:Label {prop: value})
    if text.startswith("(") and text.endswith(")"):
        return _parse_node(text)
    # Path 表示: <(a)-[r]->(b)>
    if text.startswith("<") and text.endswith(">"):
        return {"_type": "path", "_repr": text}
    # 无法解析的值原样返回
    return text


def _is_float(text: str) -> bool:
    """判断文本是否为浮点数表示。"""
    if text in ("Inf", "-Inf", "NaN"):
        return True
    try:
        float(text)
        return "." in text or "e" in text.lower() or "E" in text
    except ValueError:
        return False


def _parse_float(text: str) -> float:
    """解析浮点数文本。"""
    if text == "Inf":
        return float("inf")
    if text == "-Inf":
        return float("-inf")
    if text == "NaN":
        return float("nan")
    return float(text)


def _parse_list(text: str) -> list:
    """解析 TCK 列表表示。

    简单的逗号分隔解析，支持嵌套结构。
    """
    inner = text[1:-1].strip()
    if not inner:
        return []
    # 尝试 JSON 解析（处理简单情况）
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    # 手动分割（处理嵌套情况）
    elements = _split_top_level(inner, ",")
    return [parse_tck_value(elem.strip()) for elem in elements]


def _parse_map(text: str) -> dict:
    """解析 TCK Map 表示。"""
    inner = text[1:-1].strip()
    if not inner:
        return {}
    # 尝试 JSON 解析
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    # 手动解析 key: value 对
    result = {}
    pairs = _split_top_level(inner, ",")
    for pair in pairs:
        pair = pair.strip()
        colon_idx = pair.find(":")
        if colon_idx == -1:
            continue
        key = pair[:colon_idx].strip().strip("'\"")
        value = parse_tck_value(pair[colon_idx + 1:].strip())
        result[key] = value
    return result


def _parse_node(text: str) -> dict:
    """解析 Node 表示 (:Label {prop: value})。"""
    inner = text[1:-1].strip()
    labels = []
    properties = {}
    # 提取标签
    label_match = re.findall(r":(\w+)", inner)
    if label_match:
        labels = label_match
    # 提取属性
    prop_match = re.search(r"\{(.+)\}", inner)
    if prop_match:
        properties = _parse_map("{" + prop_match.group(1) + "}")
    return {"_type": "node", "labels": labels, "properties": properties}


def _parse_relationship(text: str) -> dict:
    """解析 Relationship 表示 [:TYPE {prop: value}]。"""
    inner = text[1:-1].strip()
    rel_type = ""
    properties = {}
    # 提取类型
    type_match = re.search(r":(\w+)", inner)
    if type_match:
        rel_type = type_match.group(1)
    # 提取属性
    prop_match = re.search(r"\{(.+)\}", inner)
    if prop_match:
        properties = _parse_map("{" + prop_match.group(1) + "}")
    return {"_type": "relationship", "rel_type": rel_type, "properties": properties}


def _split_top_level(text: str, delimiter: str) -> list[str]:
    """在顶层分割字符串，忽略括号/引号内的分隔符。"""
    parts = []
    depth = 0
    in_string = False
    string_char = ""
    current = []

    for ch in text:
        if in_string:
            current.append(ch)
            if ch == string_char:
                in_string = False
            continue
        if ch in ("'", '"'):
            in_string = True
            string_char = ch
            current.append(ch)
        elif ch in ("(", "[", "{"):
            depth += 1
            current.append(ch)
        elif ch in (")", "]", "}"):
            depth -= 1
            current.append(ch)
        elif ch == delimiter and depth == 0:
            parts.append("".join(current))
            current = []
        else:
            current.append(ch)

    if current:
        parts.append("".join(current))
    return parts
