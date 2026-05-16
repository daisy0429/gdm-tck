"""GDM TCK 自定义异常类型模块。

按职责分类定义异常，便于区分不同层面的错误。
"""


class GdmTckError(Exception):
    """所有 GDM TCK 异常的基类。"""


class ConfigurationError(GdmTckError):
    """配置加载或验证失败时抛出。"""


class ConnectionError(GdmTckError):
    """数据库连接建立或维持失败时抛出。"""


class QueryExecutionError(GdmTckError):
    """Cypher 查询执行失败时抛出（非预期错误）。"""

    def __init__(self, cypher: str, message: str, cause: Exception | None = None):
        self.cypher = cypher
        self.cause = cause
        super().__init__(f"Query execution failed: {message}\nCypher: {cypher}")


class ResultComparisonError(GdmTckError):
    """结果比较断言失败时抛出。"""

    def __init__(self, message: str, expected: object = None, actual: object = None):
        self.expected = expected
        self.actual = actual
        detail = message
        if expected is not None:
            detail += f"\nExpected: {expected}"
        if actual is not None:
            detail += f"\nActual:   {actual}"
        super().__init__(detail)


class SideEffectError(GdmTckError):
    """副作用断言不匹配时抛出。"""


class HealthCheckError(GdmTckError):
    """服务健康检查超时或失败时抛出。"""


class GrpcNotImplementedError(GdmTckError):
    """gRPC 功能尚未实现时抛出。"""
