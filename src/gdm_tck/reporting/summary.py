"""运行摘要收集模块。

收集测试运行统计、延迟数据等信息，生成 JSON 格式的摘要报告。
"""

from __future__ import annotations

import json
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class LatencyRecord:
    """单次查询延迟记录。"""

    phase: str
    query_name: str
    elapsed_ms: float
    ok: bool
    row_count: int = 0
    error: str = ""


@dataclass
class RunSummary:
    """测试运行摘要收集器（线程安全）。"""

    started_at: float = field(default_factory=time.time)
    finished_at: float | None = None
    tests: list[dict[str, Any]] = field(default_factory=list)
    latencies: list[LatencyRecord] = field(default_factory=list)
    _lock: threading.Lock = field(default_factory=threading.Lock, repr=False)

    def record_test(self, nodeid: str, outcome: str, duration_secs: float) -> None:
        """记录单个测试结果。"""
        with self._lock:
            self.tests.append({
                "nodeid": nodeid,
                "outcome": outcome,
                "duration_secs": round(duration_secs, 3),
            })

    def record_latency(self, phase: str, query_name: str, elapsed_ms: float,
                       ok: bool, row_count: int = 0, error: str = "") -> None:
        """记录查询延迟数据。"""
        with self._lock:
            self.latencies.append(LatencyRecord(
                phase=phase,
                query_name=query_name,
                elapsed_ms=round(elapsed_ms, 2),
                ok=ok,
                row_count=row_count,
                error=error,
            ))

    def finish(self) -> None:
        """标记运行结束。"""
        self.finished_at = time.time()

    @property
    def total_count(self) -> int:
        """总测试数。"""
        return len(self.tests)

    @property
    def passed_count(self) -> int:
        """通过数。"""
        return sum(1 for t in self.tests if t["outcome"] == "passed")

    @property
    def failed_count(self) -> int:
        """失败数。"""
        return sum(1 for t in self.tests if t["outcome"] == "failed")

    @property
    def duration_secs(self) -> float:
        """总耗时（秒）。"""
        if self.finished_at is None:
            return time.time() - self.started_at
        return self.finished_at - self.started_at

    def to_dict(self) -> dict[str, Any]:
        """转为可序列化的字典。"""
        return {
            "started_at": self.started_at,
            "finished_at": self.finished_at,
            "duration_secs": round(self.duration_secs, 2),
            "total": self.total_count,
            "passed": self.passed_count,
            "failed": self.failed_count,
            "skipped": self.total_count - self.passed_count - self.failed_count,
            "latency_records": len(self.latencies),
        }

    def write_json(self, path: Path) -> None:
        """将摘要写入 JSON 文件。"""
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(self.to_dict(), f, indent=2, ensure_ascii=False)
