"""Bolt 多节点连接池管理模块。

支持 standalone（单节点）和 distributed（多节点）两种模式。
"""

from __future__ import annotations

import logging
from typing import Any

from ..config import Settings
from ..exceptions import ConnectionError
from .bolt_client import BoltClient, QueryResult

logger = logging.getLogger(__name__)


class BoltConnectionPool:
    """多节点 Bolt 连接池管理器。

    standalone 模式下只有一个客户端，distributed 模式下管理多个节点连接。
    """

    def __init__(self, settings: Settings):
        """初始化连接池。

        Args:
            settings: 全局配置。
        """
        self._settings = settings
        self._clients: dict[str, BoltClient] = {}
        self._initialize_clients()

    def _initialize_clients(self) -> None:
        """根据配置初始化客户端实例（不建立连接）。"""
        server = self._settings.server
        if server.mode == "standalone":
            self._clients["primary"] = BoltClient.from_settings(server)
        else:
            # 分布式模式：为每个节点创建客户端
            for i, uri in enumerate(server.bolt_uris):
                name = f"node{i + 1}"
                self._clients[name] = BoltClient(
                    uri=uri,
                    username=server.username,
                    password=server.password,
                    database=server.database,
                    backend=server.backend,
                    pool_size=server.pool.max_size,
                    timeout_secs=server.timeouts.query_secs,
                )

    def connect_all(self) -> None:
        """建立到所有节点的连接。

        Raises:
            ConnectionError: 任何节点连接失败时抛出。
        """
        for name, client in self._clients.items():
            logger.info("Connecting to node '%s' at %s", name, client.uri)
            client.connect()

    def close_all(self) -> None:
        """关闭所有连接。"""
        for name, client in self._clients.items():
            client.close()

    @property
    def primary(self) -> BoltClient:
        """返回主节点客户端（standalone 的唯一节点或 distributed 的第一个节点）。"""
        if "primary" in self._clients:
            return self._clients["primary"]
        first_key = next(iter(self._clients))
        return self._clients[first_key]

    def get_client(self, name: str) -> BoltClient:
        """按名称获取指定节点的客户端。

        Args:
            name: 节点名称。

        Returns:
            BoltClient: 对应节点的客户端。

        Raises:
            ConnectionError: 节点不存在时抛出。
        """
        if name not in self._clients:
            raise ConnectionError(
                f"Node '{name}' not found. Available: {list(self._clients.keys())}"
            )
        return self._clients[name]

    def execute_on_any(
        self, cypher: str, parameters: dict[str, Any] | None = None, database: str | None = None
    ) -> QueryResult:
        """在任一可用节点上执行查询。

        Args:
            cypher: Cypher 查询语句。
            parameters: 查询参数。
            database: 目标数据库。

        Returns:
            QueryResult: 查询结果。
        """
        return self.primary.execute(cypher, parameters, database)

    def execute_on_all(
        self, cypher: str, parameters: dict[str, Any] | None = None, database: str | None = None
    ) -> dict[str, QueryResult]:
        """在所有节点上执行查询。

        Args:
            cypher: Cypher 查询语句。
            parameters: 查询参数。
            database: 目标数据库。

        Returns:
            dict: 节点名称 -> QueryResult 的映射。
        """
        results = {}
        for name, client in self._clients.items():
            results[name] = client.execute(cypher, parameters, database)
        return results

    def create_user_client(
        self, username: str, password: str, database: str | None = None
    ) -> BoltClient:
        """为特定用户创建独立客户端（用于 RBAC 测试）。

        Args:
            username: 用户名。
            password: 密码。
            database: 目标数据库。

        Returns:
            BoltClient: 新的客户端实例（已连接）。
        """
        server = self._settings.server
        client = BoltClient(
            uri=server.bolt_uri,
            username=username,
            password=password,
            database=database or server.database,
            backend=server.backend,
            pool_size=10,
            timeout_secs=server.timeouts.query_secs,
        )
        client.connect()
        return client

    @property
    def node_names(self) -> list[str]:
        """返回所有节点名称列表。"""
        return list(self._clients.keys())
