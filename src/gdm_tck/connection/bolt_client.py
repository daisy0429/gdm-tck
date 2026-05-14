"""Bolt 协议客户端封装模块。

提供对 neo4j Python 驱动的封装，包括连接管理、查询执行、事务控制。
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any

import neo4j
from neo4j import GraphDatabase

from ..config import ServerSettings
from ..exceptions import ConnectionError, QueryExecutionError
from .agent_patch import apply_gdm_agent_patch

logger = logging.getLogger(__name__)


@dataclass
class QueryResult:
    """查询结果的标准化表示。"""

    records: list[dict[str, Any]] = field(default_factory=list)
    keys: list[str] = field(default_factory=list)
    summary: neo4j.ResultSummary | None = None


class BoltClient:
    """单节点 Bolt 协议客户端。

    封装 neo4j Driver 的生命周期管理、会话创建和查询执行。
    """

    def __init__(self, uri: str, username: str, password: str, database: str,
                 pool_size: int = 100, timeout_secs: float = 60.0):
        """初始化 Bolt 客户端。

        Args:
            uri: Bolt 连接 URI，如 "bolt://host:port"。
            username: 认证用户名。
            password: 认证密码。
            database: 目标数据库名称。
            pool_size: 连接池最大连接数。
            timeout_secs: 查询超时时间（秒）。
        """
        apply_gdm_agent_patch()
        self._uri = uri
        self._username = username
        self._password = password
        self._database = database
        self._timeout_secs = timeout_secs
        self._driver: neo4j.Driver | None = None
        self._pool_size = pool_size

    @property
    def uri(self) -> str:
        """返回连接 URI。"""
        return self._uri

    @property
    def database(self) -> str:
        """返回当前数据库名。"""
        return self._database

    @database.setter
    def database(self, value: str) -> None:
        """设置当前数据库名。"""
        self._database = value

    def connect(self) -> None:
        """建立到数据库的连接。

        Raises:
            ConnectionError: 连接失败时抛出。
        """
        if self._driver is not None:
            return
        try:
            self._driver = GraphDatabase.driver(
                self._uri,
                auth=(self._username, self._password),
                max_connection_pool_size=self._pool_size,
            )
            self._driver.verify_connectivity()
            logger.info("Connected to %s", self._uri)
        except Exception as e:
            self._driver = None
            raise ConnectionError(f"Failed to connect to {self._uri}: {e}") from e

    def close(self) -> None:
        """关闭连接并释放资源。"""
        if self._driver is not None:
            self._driver.close()
            self._driver = None
            logger.info("Disconnected from %s", self._uri)

    def execute(self, cypher: str, parameters: dict[str, Any] | None = None,
                database: str | None = None) -> QueryResult:
        """执行 Cypher 查询并返回结果。

        Args:
            cypher: Cypher 查询语句。
            parameters: 查询参数字典。
            database: 可选的目标数据库，不指定时使用客户端默认值。

        Returns:
            QueryResult: 包含记录列表、列名和执行摘要。

        Raises:
            ConnectionError: 未连接时抛出。
            QueryExecutionError: 查询执行失败时抛出。
        """
        if self._driver is None:
            raise ConnectionError("Not connected. Call connect() first.")
        db = database or self._database
        try:
            with self._driver.session(
                database=db,
                default_access_mode=neo4j.WRITE_ACCESS,
            ) as session:
                result = session.run(cypher, parameters or {})
                records = [dict(record) for record in result]
                keys = list(result.keys()) if records else []
                summary = result.consume()
                return QueryResult(records=records, keys=keys, summary=summary)
        except neo4j.exceptions.Neo4jError as e:
            raise QueryExecutionError(cypher, str(e), cause=e) from e
        except Exception as e:
            raise QueryExecutionError(cypher, str(e), cause=e) from e

    def execute_no_throw(self, cypher: str, parameters: dict[str, Any] | None = None,
                         database: str | None = None) -> tuple[QueryResult | None, Exception | None]:
        """执行查询，不抛出异常，返回 (result, error) 元组。

        用于 BDD 场景中需要延迟验证错误的情况。

        Args:
            cypher: Cypher 查询语句。
            parameters: 查询参数字典。
            database: 可选的目标数据库。

        Returns:
            (QueryResult, None) 成功时返回结果。
            (None, Exception) 失败时返回异常。
        """
        try:
            result = self.execute(cypher, parameters, database)
            return result, None
        except Exception as e:
            return None, e

    def create_session(self, database: str | None = None,
                       access_mode: int = neo4j.WRITE_ACCESS) -> neo4j.Session:
        """创建一个新的会话对象（用于事务控制）。

        Args:
            database: 目标数据库名。
            access_mode: 访问模式（READ_ACCESS 或 WRITE_ACCESS）。

        Returns:
            neo4j.Session: 新的会话实例。

        Raises:
            ConnectionError: 未连接时抛出。
        """
        if self._driver is None:
            raise ConnectionError("Not connected. Call connect() first.")
        return self._driver.session(
            database=database or self._database,
            default_access_mode=access_mode,
        )

    @classmethod
    def from_settings(cls, settings: ServerSettings) -> "BoltClient":
        """从 ServerSettings 配置创建客户端实例。

        Args:
            settings: 服务器配置对象。

        Returns:
            BoltClient: 配置好的客户端实例（未连接）。
        """
        return cls(
            uri=settings.bolt_uri,
            username=settings.username,
            password=settings.password,
            database=settings.database,
            pool_size=settings.pool.max_size,
            timeout_secs=settings.timeouts.query_secs,
        )
