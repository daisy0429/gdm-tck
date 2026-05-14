"""BDD 场景状态容器模块。

ScenarioContext 替代 cypher-tck 中的包级全局变量，
为每个 BDD 场景提供独立的运行时状态，支持并行执行。
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import neo4j

from .connection.bolt_client import BoltClient, QueryResult


@dataclass
class ScenarioContext:
    """BDD 场景的运行时状态容器。

    每个 Scenario 开始前通过 function-scope fixture 创建新实例，
    确保场景间状态完全隔离。
    """

    # 最近一次查询结果
    last_result: QueryResult | None = None

    # 最近一次查询异常（延迟验证模式）
    last_error: Exception | None = None

    # 当前场景参数（Given parameters are: 步骤设置）
    parameters: dict[str, Any] = field(default_factory=dict)

    # 显式事务会话映射（session编号 -> Session对象）
    sessions: dict[int, neo4j.Session] = field(default_factory=dict)

    # 显式事务映射（session编号 -> Transaction对象）
    transactions: dict[int, neo4j.ManagedTransaction] = field(default_factory=dict)

    # 多用户连接缓存（用户名 -> BoltClient列表）
    user_clients: dict[str, list[BoltClient]] = field(default_factory=dict)

    # 当前使用的数据库名
    current_database: str = "default"

    def reset(self) -> None:
        """重置所有状态（场景开始前调用）。"""
        self.last_result = None
        self.last_error = None
        self.parameters = {}
        self._close_sessions()
        self._close_user_clients()
        self.current_database = "default"

    def _close_sessions(self) -> None:
        """关闭所有打开的事务和会话。"""
        for tx in self.transactions.values():
            try:
                tx.close()
            except Exception:
                pass
        self.transactions.clear()
        for session in self.sessions.values():
            try:
                session.close()
            except Exception:
                pass
        self.sessions.clear()

    def _close_user_clients(self) -> None:
        """关闭所有用户客户端连接。"""
        for clients in self.user_clients.values():
            for client in clients:
                try:
                    client.close()
                except Exception:
                    pass
        self.user_clients.clear()

    @property
    def has_error(self) -> bool:
        """判断上次执行是否有未验证的错误。"""
        return self.last_error is not None

    @property
    def result_records(self) -> list[dict[str, Any]]:
        """获取最近结果的记录列表（空安全）。"""
        if self.last_result is None:
            return []
        return self.last_result.records

    @property
    def result_keys(self) -> list[str]:
        """获取最近结果的列名列表（空安全）。"""
        if self.last_result is None:
            return []
        return self.last_result.keys
