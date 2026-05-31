"""CLI 输出解析模块。

提供纯函数用于解析 gdm-cli 和 gdm-admin 的命令输出。
"""

from __future__ import annotations

import json
import logging
import re
from typing import Any

logger = logging.getLogger(__name__)


def parse_table_output(stdout: str) -> list[dict[str, str]]:
    """解析表格格式输出为字典列表。

    假设表格使用 Markdown 风格的管道符分隔格式。

    Args:
        stdout: 命令标准输出。

    Returns:
        list[dict[str, str]]: 每行一个字典，键为列名。
    """
    lines = [line for line in stdout.splitlines() if line.strip().startswith("|")]
    if not lines:
        return []

    # 解析表头
    header_line = lines[0]
    headers = [cell.strip() for cell in header_line.split("|")[1:-1]]

    records = []
    # 跳过表头和分隔行（如果存在）
    start_idx = 1
    if len(lines) > 1 and "-" in lines[1]:
        start_idx = 2

    for line in lines[start_idx:]:
        cells = [cell.strip() for cell in line.split("|")[1:-1]]
        if len(cells) == len(headers):
            records.append(dict(zip(headers, cells)))

    return records


def parse_json_output(stdout: str) -> list[dict[str, Any]]:
    """解析 JSON 格式输出为字典列表。

    假设每行是一个独立的 JSON 对象（JSON Lines 格式）。

    Args:
        stdout: 命令标准输出。

    Returns:
        list[dict[str, Any]]: JSON 对象列表。
    """
    records = []
    for line in stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            if isinstance(obj, dict):
                records.append(obj)
            elif isinstance(obj, list):
                records.extend(obj)
        except json.JSONDecodeError:
            logger.debug("Skipping non-JSON line: %s", line[:100])
    return records


def parse_tsv_output(stdout: str) -> list[dict[str, str]]:
    """解析 TSV 格式输出为字典列表。

    Args:
        stdout: 命令标准输出。

    Returns:
        list[dict[str, str]]: 每行一个字典，键为第一行的列名。
    """
    lines = [line for line in stdout.splitlines() if line.strip()]
    if not lines:
        return []

    headers = lines[0].split("\t")
    records = []
    for line in lines[1:]:
        cells = line.split("\t")
        if len(cells) == len(headers):
            records.append(dict(zip(headers, cells)))
    return records


def extract_import_summary(stdout: str) -> dict[str, Any]:
    """从 gdm-admin import 输出中提取摘要信息。

    解析 GDM Import Report 中的关键字段：
    - status: OK / FAILED / COMPLETED_WITH_ERRORS / ABORTED
    - vertices_imported: 导入的顶点数（从 summary 部分的 ok 值）
    - edges_imported: 导入的边数（从 summary 部分的 ok 值）
    - elapsed_ms: 耗时（毫秒）

    Args:
        stdout: import 命令的标准输出。

    Returns:
        dict: 包含解析后的摘要信息，解析失败时返回空字典。
    """
    summary: dict[str, Any] = {
        "status": None,
        "vertices_imported": 0,
        "edges_imported": 0,
        "elapsed_ms": 0,
        "rows_skipped": 0,
        "rows_errored": 0,
    }

    # 解析 status
    status_match = re.search(r"status\s*[:=]\s*(\w+)", stdout, re.IGNORECASE)
    if status_match:
        summary["status"] = status_match.group(1).upper()

    # 解析 summary 部分
    # 格式:
    # summary:
    #   vertices:      ok=5 skip=0 err=0
    #   edges:         ok=5 skip=0 err=0
    in_summary = False
    for line in stdout.splitlines():
        stripped = line.strip()
        if stripped.startswith("summary:"):
            in_summary = True
            continue
        if in_summary:
            if not stripped or stripped.startswith("-"):
                break
            # 解析 vertices 行
            if "vertices:" in stripped and "ok=" in stripped:
                ok_match = re.search(r"ok=(\d+)", stripped)
                if ok_match:
                    summary["vertices_imported"] = int(ok_match.group(1))
                skip_match = re.search(r"skip=(\d+)", stripped)
                if skip_match:
                    summary["rows_skipped"] += int(skip_match.group(1))
                err_match = re.search(r"err=(\d+)", stripped)
                if err_match:
                    summary["rows_errored"] += int(err_match.group(1))
            # 解析 edges 行
            elif "edges:" in stripped and "ok=" in stripped:
                ok_match = re.search(r"ok=(\d+)", stripped)
                if ok_match:
                    summary["edges_imported"] = int(ok_match.group(1))
                skip_match = re.search(r"skip=(\d+)", stripped)
                if skip_match:
                    summary["rows_skipped"] += int(skip_match.group(1))
                err_match = re.search(r"err=(\d+)", stripped)
                if err_match:
                    summary["rows_errored"] += int(err_match.group(1))

    # 解析耗时
    time_match = re.search(r"elapsed\s*[:=]\s*(\d+(?:\.\d+)?)\s*(ms|s)", stdout, re.IGNORECASE)
    if time_match:
        value = float(time_match.group(1))
        unit = time_match.group(2).lower()
        if unit.startswith("s"):
            value *= 1000
        summary["elapsed_ms"] = int(value)

    return summary
