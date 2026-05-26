"""错误断言 step definitions。

对应 Gherkin 中验证查询应该抛出特定错误类型的 Then 步骤。
"""

import re

from pytest_bdd import then, parsers

from gdm_tck.state import ScenarioContext


@then(parsers.re(r"a (?P<error_type>\w+) should be raised at compile time: (?P<detail>\S+)"))
def a_error_at_compile_time_with_detail(error_type: str, detail: str,
                                        scenario_ctx: ScenarioContext):
    """断言查询在编译阶段抛出了指定类型和详情的错误。"""
    _assert_error_raised(error_type, scenario_ctx, phase="compile time", detail=detail)


@then(parsers.re(r"a (?P<error_type>\w+) should be raised at compile time"))
def a_error_at_compile_time(error_type: str,
                            scenario_ctx: ScenarioContext):
    """断言查询在编译阶段抛出了指定类型的错误。"""
    _assert_error_raised(error_type, scenario_ctx, phase="compile time")


@then(parsers.re(r"a (?P<error_type>\w+) should be raised at runtime: (?P<detail>\S+)"))
def a_error_at_runtime_with_detail(error_type: str, detail: str,
                                   scenario_ctx: ScenarioContext):
    """断言查询在运行阶段抛出了指定类型和详情的错误。"""
    _assert_error_raised(error_type, scenario_ctx, phase="runtime", detail=detail)


@then(parsers.re(r"a (?P<error_type>\w+) should be raised at runtime"))
def a_error_at_runtime(error_type: str,
                       scenario_ctx: ScenarioContext):
    """断言查询在运行阶段抛出了指定类型的错误。"""
    _assert_error_raised(error_type, scenario_ctx, phase="runtime")


@then(parsers.re(r"a (?P<error_type>\w+) should be raised at any time: (?P<detail>\S+)"))
def a_error_at_any_time_with_detail(error_type: str, detail: str,
                                    scenario_ctx: ScenarioContext):
    """断言查询在任意阶段抛出了指定类型和详情的错误。"""
    _assert_error_raised(error_type, scenario_ctx, phase="any time", detail=detail)


@then(parsers.re(r"a (?P<error_type>\w+) should be raised at any time"))
def a_error_at_any_time(error_type: str,
                        scenario_ctx: ScenarioContext):
    """断言查询在任意阶段抛出了指定类型的错误。"""
    _assert_error_raised(error_type, scenario_ctx, phase="any time")


@then(parsers.parse("an error should be raised"))
def an_error_should_be_raised(scenario_ctx: ScenarioContext):
    """断言查询执行过程中有任意错误抛出。"""
    if not scenario_ctx.has_error:
        raise AssertionError("Expected an error to be raised, but query succeeded")


@then(parsers.re(r"the error message should contain '(?P<message>.+)'"))
def error_message_should_contain(message: str, scenario_ctx: ScenarioContext):
    """断言错误消息中包含指定文本。"""
    if not scenario_ctx.has_error:
        raise AssertionError("No error occurred, cannot check error message")
    error_msg = str(scenario_ctx.last_error)
    if message not in error_msg:
        raise AssertionError(
            f"Error message does not contain '{message}'\n"
            f"Actual error: {error_msg}"
        )


def _assert_error_raised(error_type: str, ctx: ScenarioContext,
                         phase: str = "", detail: str = "") -> None:
    """通用错误断言：严格验证有错误且类型匹配。

    检查点：
    1. 必须有错误抛出（否则失败）
    2. 错误类型必须匹配 TCK 预期的类型关键词（否则失败）
    3. 记录 detail 信息到断言消息（用于问题追踪）
    """
    if not ctx.has_error:
        raise AssertionError(
            f"Expected a {error_type} to be raised at {phase}, "
            f"but query succeeded"
        )

    error_msg = str(ctx.last_error)
    error_msg_lower = error_msg.lower()
    neo4j_code = _extract_neo4j_error_code(error_msg)
    neo4j_code_lower = neo4j_code.lower()

    # 严格检查：错误类型必须匹配（关键词匹配错误消息或错误码）
    type_keywords = _get_error_keywords(error_type)
    if type_keywords and not (
        any(kw in error_msg_lower for kw in type_keywords)
        or any(kw in neo4j_code_lower for kw in type_keywords)
    ):
        detail_info = f", detail={detail}" if detail else ""
        raise AssertionError(
            f"Error type mismatch: expected {error_type}{detail_info} at {phase}\n"
            f"  Expected keywords (any of): {type_keywords}\n"
            f"  Actual error code: {neo4j_code}\n"
            f"  Actual error message: {error_msg[:200]}"
        )


def _extract_neo4j_error_code(error_msg: str) -> str:
    """从错误消息中提取 Neo4j 错误码（如 Neo.ClientError.Statement.SyntaxError）。"""
    match = re.search(r'(Neo\.\w+\.\w+\.\w+)', error_msg)
    return match.group(1) if match else "unknown"


def _get_error_keywords(error_type: str) -> list[str]:
    """获取错误类型对应的关键词列表。

    基于 GDM 返回的 Neo4j 协议错误码进行映射。
    """
    mapping = {
        "SyntaxError": ["syntax", "syntaxerror", "parse", "unexpected", "argumenterror"],
        "TypeError": ["type", "typeerror", "incompatible", "invalidargumenttype"],
        "SemanticError": ["semantic", "semanticerror"],
        "ParameterMissing": ["parameter", "missing", "expected"],
        "ConstraintValidationFailed": ["constraint", "violation", "unique"],
        "EntityNotFound": ["not found", "does not exist", "entitynotfound", "deleted"],
        "ArithmeticError": ["arithmetic", "division by zero", "overflow"],
        "ArgumentError": ["argument", "argumenterror", "invalidargument", "numberoutofrange"],
        "ProcedureError": ["procedure", "procedurenotfound"],
    }
    return mapping.get(error_type, [])
