"""并发查询执行器模块。

使用 ThreadPoolExecutor 实现多线程并发查询执行，
支持并发正确性测试和性能基准测试。
"""

from __future__ import annotations

import logging
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from typing import Any, Callable

from ..connection.bolt_client import BoltClient, QueryResult

logger = logging.getLogger(__name__)


@dataclass
class ConcurrentResult:
    """并发执行结果汇总。"""

    total: int = 0
    succeeded: int = 0
    failed: int = 0
    results: list[QueryResult] = field(default_factory=list)
    errors: list[Exception] = field(default_factory=list)
    elapsed_ms: float = 0.0


class ConcurrentExecutor:
    """并发查询执行器。

    封装 ThreadPoolExecutor，支持多线程执行相同或不同的 Cypher 查询。
    """

    def __init__(self, client: BoltClient, max_workers: int = 4):
        """初始化并发执行器。

        Args:
            client: Bolt 客户端实例。
            max_workers: 最大并发线程数。
        """
        self._client = client
        self._max_workers = max_workers

    def run_same_query(self, cypher: str, concurrency: int,
                       parameters: dict[str, Any] | None = None) -> ConcurrentResult:
        """并发执行相同查询 N 次。

        Args:
            cypher: 要执行的 Cypher 查询。
            concurrency: 并发次数。
            parameters: 查询参数。

        Returns:
            ConcurrentResult: 汇总结果。
        """
        return self._execute_tasks(
            [lambda: self._client.execute(cypher, parameters)] * concurrency
        )

    def run_parameterized(self, cypher: str, params_list: list[dict[str, Any]]) -> ConcurrentResult:
        """并发执行参数化查询（每个参数组合一个线程）。

        Args:
            cypher: 查询模板。
            params_list: 参数字典列表。

        Returns:
            ConcurrentResult: 汇总结果。
        """
        tasks = [
            lambda p=params: self._client.execute(cypher, p)
            for params in params_list
        ]
        return self._execute_tasks(tasks)

    def run_workload(self, task_fn: Callable[[], QueryResult],
                     duration_secs: float, max_workers: int | None = None) -> ConcurrentResult:
        """运行持续负载测试。

        在指定时间内持续并发执行任务函数。

        Args:
            task_fn: 任务函数，每次调用执行一次查询。
            duration_secs: 持续时间（秒）。
            max_workers: 并发线程数，不指定时使用默认值。

        Returns:
            ConcurrentResult: 汇总结果。
        """
        workers = max_workers or self._max_workers
        result = ConcurrentResult()
        start_time = time.time()
        end_time = start_time + duration_secs

        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = []
            while time.time() < end_time:
                future = executor.submit(task_fn)
                futures.append(future)

            for future in as_completed(futures):
                result.total += 1
                try:
                    qr = future.result(timeout=30)
                    result.succeeded += 1
                    result.results.append(qr)
                except Exception as e:
                    result.failed += 1
                    result.errors.append(e)

        result.elapsed_ms = (time.time() - start_time) * 1000
        return result

    def _execute_tasks(self, tasks: list[Callable]) -> ConcurrentResult:
        """执行任务列表并汇总结果。"""
        result = ConcurrentResult()
        result.total = len(tasks)
        start_time = time.time()

        with ThreadPoolExecutor(max_workers=self._max_workers) as executor:
            futures = [executor.submit(task) for task in tasks]
            for future in as_completed(futures):
                try:
                    qr = future.result(timeout=60)
                    result.succeeded += 1
                    result.results.append(qr)
                except Exception as e:
                    result.failed += 1
                    result.errors.append(e)

        result.elapsed_ms = (time.time() - start_time) * 1000
        logger.info(
            "Concurrent execution done: %d/%d succeeded in %.1fms",
            result.succeeded, result.total, result.elapsed_ms,
        )
        return result
