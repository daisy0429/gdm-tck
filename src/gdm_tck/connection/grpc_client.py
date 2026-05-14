"""gRPC 客户端预留接口模块。

当前仅定义接口规范，暂不实现。待 proto 文件提供后填充具体逻辑。
"""

from __future__ import annotations

from ..exceptions import GrpcNotImplementedError


class GrpcClient:
    """gRPC 客户端接口（预留）。

    后续实现时需要：
    1. 获取 GDM 的 .proto 文件
    2. 使用 grpcio-tools 生成 Python 桩代码
    3. 实现 ExecuteQuery / BulkImport 等 RPC 调用
    """

    def __init__(self, address: str):
        """初始化 gRPC 客户端。

        Args:
            address: gRPC 服务地址，如 "host:port"。
        """
        self._address = address

    def connect(self) -> None:
        """建立 gRPC 连接。"""
        raise GrpcNotImplementedError("gRPC client not yet implemented")

    def close(self) -> None:
        """关闭 gRPC 连接。"""
        raise GrpcNotImplementedError("gRPC client not yet implemented")

    def execute_query(self, cypher: str, params: dict | None = None) -> dict:
        """执行 Cypher 查询。"""
        raise GrpcNotImplementedError("gRPC client not yet implemented")
