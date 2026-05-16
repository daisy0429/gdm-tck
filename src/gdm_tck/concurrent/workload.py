"""性能工作负载模板模块。

提供 TPS/QPS 基准测试的工作负载定义。
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from typing import Any

from ..connection.bolt_client import BoltClient


@dataclass
class ThroughputResult:
    """吞吐量测试结果。"""

    duration_secs: float = 0.0
    workers: int = 0
    total_ops: int = 0
    successful_ops: int = 0
    failed_ops: int = 0
    ops_per_sec: float = 0.0
    avg_latency_ms: float = 0.0
    p50_ms: float = 0.0
    p95_ms: float = 0.0
    p99_ms: float = 0.0
    max_ms: float = 0.0
    latencies: list[float] = field(default_factory=list)

    def compute_stats(self) -> None:
        """根据延迟列表计算统计指标。"""
        if not self.latencies:
            return
        sorted_latencies = sorted(self.latencies)
        n = len(sorted_latencies)
        self.avg_latency_ms = sum(sorted_latencies) / n
        self.p50_ms = sorted_latencies[int(n * 0.50)]
        self.p95_ms = sorted_latencies[min(n - 1, int(n * 0.95))]
        self.p99_ms = sorted_latencies[min(n - 1, int(n * 0.99))]
        self.max_ms = sorted_latencies[-1]
        if self.duration_secs > 0:
            self.ops_per_sec = self.successful_ops / self.duration_secs


@dataclass
class WorkloadConfig:
    """工作负载配置。"""

    duration_secs: float = 30.0
    workers: int = 4
    read_queries: list[str] = field(default_factory=list)
    write_queries: list[str] = field(default_factory=list)
    read_weight: int = 7
    write_weight: int = 3


def run_throughput_workload(client: BoltClient, config: WorkloadConfig) -> ThroughputResult:
    """执行吞吐量基准测试。

    在指定时间内混合执行读写查询，收集延迟和吞吐量数据。

    Args:
        client: Bolt 客户端。
        config: 工作负载配置。

    Returns:
        ThroughputResult: 测试结果。
    """
    import random
    from concurrent.futures import ThreadPoolExecutor, as_completed

    result = ThroughputResult(workers=config.workers)
    all_queries = (
        [(q, "read") for q in config.read_queries] * config.read_weight +
        [(q, "write") for q in config.write_queries] * config.write_weight
    )
    if not all_queries:
        return result

    start_time = time.time()
    end_time = start_time + config.duration_secs

    def execute_one() -> float:
        """执行一次随机查询，返回延迟(ms)。"""
        query, _ = random.choice(all_queries)
        t0 = time.time()
        client.execute(query)
        return (time.time() - t0) * 1000

    with ThreadPoolExecutor(max_workers=config.workers) as executor:
        futures = []
        while time.time() < end_time:
            futures.append(executor.submit(execute_one))

        for future in as_completed(futures):
            result.total_ops += 1
            try:
                latency = future.result(timeout=60)
                result.successful_ops += 1
                result.latencies.append(latency)
            except Exception:
                result.failed_ops += 1

    result.duration_secs = time.time() - start_time
    result.compute_stats()
    return result
