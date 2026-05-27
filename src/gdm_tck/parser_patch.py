"""pytest-bdd 解析器补丁模块。

修补三个 pytest-bdd 上游 bug：

1. **And/But mode 继承 bug**（parse_feature）：
   当 Scenario 的第一个步骤使用 ``And`` 作为前缀时（如 ``And having executed:``），
   ``get_step_type("And having executed:")`` 返回 ``None``，
   导致 ``mode = None or prev_mode`` 将 mode 错误地继承为 ``SCENARIO``，
   进而在场景内部创建出同名的幽灵 Scenario。

   修复：当 ``get_step_type`` 返回 ``None``（And/But 前缀），
   且当前 mode 不是步骤类型时，仅在行以 ``And `` 或 ``But `` 开头时才强制
   设为 ``GIVEN``。

2. **STEP_PARAM_RE 模板变量解析 bug**：
   ``STEP_PARAM_RE = re.compile(r"<(.+?)>")`` 使用非贪婪 ``.+?`` 匹配，
   在 Cypher 查询中出现比较运算符相邻模板变量时（如 ``RETURN <lhs> < <rhs> AS result``），
   会将 ``< <rhs>`` 误匹配为单个模板变量 `` <rhs``（带前导空格），
   导致 Scenario Outline 渲染时 KeyError。

   修复：将正则收紧为 ``r"<([^<>\\s]+)>"``，禁止模板变量名包含空格和角括号。

3. **Docstring 同级缩进无法识别 bug**（parse_feature multiline 检测）：
   原始逻辑仅在 ``step.indent < line_indent`` 时才将后续行视为 step 的
   多行内容。当 feature 文件中三引号定界符与 step 关键字处于相同缩进时，
   docstring 无法被识别为 step 的一部分，导致 StepDefinitionNotFoundError。

   修复：新增 ``in_docstring`` 状态标记，当检测到三引号定界符且存在活跃 step 时
   进入 docstring 模式，在此模式内所有行（无论缩进）都归入当前 step，
   直到遇到闭合的三引号定界符。
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

_PATCHED = False


def apply_patch() -> None:
    """应用 pytest-bdd 解析器补丁（幂等）。"""
    global _PATCHED
    if _PATCHED:
        return

    import pytest_bdd.parser as _parser
    import pytest_bdd.types as _types

    _original_parse_feature = _parser.parse_feature

    def _patched_parse_feature(basedir: str, filename: str, encoding: str = "utf-8"):
        """parse_feature 的修复版本。
        
        修改行：将 ``mode = get_step_type(clean_line) or mode``
        替换为仅在前一个 mode 是步骤类型时才继承。
        """
        __tracebackhide__ = True
        import os
        from collections import OrderedDict

        abs_filename = os.path.abspath(os.path.join(basedir, filename))
        rel_filename = os.path.join(os.path.basename(basedir), filename)
        feature = _parser.Feature(
            scenarios=OrderedDict(),
            filename=abs_filename,
            rel_filename=rel_filename,
            line_number=1,
            name=None,
            tags=set(),
            background=None,
            description="",
        )
        scenario = None
        mode = None
        prev_mode = None
        description: list[str] = []
        step = None
        multiline_step = False
        prev_line = None

        with open(abs_filename, encoding=encoding) as f:
            content = f.read()

        in_docstring = False

        for line_number, line in enumerate(content.splitlines(), start=1):
            unindented_line = line.lstrip()
            line_indent = len(line) - len(unindented_line)

            # --- docstring 同级缩进修复 ---
            # 当已在 docstring 内部时，无论缩进都归入当前 step
            if step and in_docstring:
                if unindented_line.rstrip() == '"""':
                    # 闭合三引号，结束 docstring 模式，不将闭合行加入 step
                    in_docstring = False
                else:
                    step.add_line(line)
                continue

            # 跳过注释行：不破坏当前 step 引用（支持 step 和 docstring 之间有注释）
            if step and unindented_line.startswith('#'):
                continue

            # 检测 docstring 开始：step 存在且当前行为 """ 且缩进 >= step 缩进
            if step and unindented_line.rstrip() == '"""' and line_indent >= step.indent:
                multiline_step = True
                in_docstring = True
                # 不将开启三引号加入 step lines，仅进入 docstring 模式
                continue

            # 表格行同级缩进修复：| 开头的行在 indent >= step.indent 时视为多行内容
            if step and unindented_line.startswith('|') and line_indent >= step.indent:
                multiline_step = True
                step.add_line(line)
                continue

            if step and (
                step.indent < line_indent or ((not unindented_line) and multiline_step)
            ):
                multiline_step = True
                step.add_line(line)
                continue
            else:
                step = None
                multiline_step = False
            stripped_line = line.strip()
            clean_line = _parser.strip_comments(line)
            if not clean_line and (
                not prev_mode or prev_mode not in _parser.TYPES_WITH_DESCRIPTIONS
            ):
                continue

            # === 修复点 ===
            # 原始：mode = get_step_type(clean_line) or mode
            # 当 And/But 后 mode 是 SCENARIO/FEATURE/BACKGROUND/TAG 等非步骤类型时，
            # 会错误地创建幽灵 Scenario。
            # 修复：仅当行以 And/But 开头（即 raw_mode 为 None 的 And/But 行）
            # 且 mode 不是步骤类型时，才强制为 GIVEN。
            # 注意：不使用 `and clean_line` 作为条件，因为这会误触发
            # Examples 表行（`| col |`），导致 Scenario Outline 参数化失效。
            raw_mode = _parser.get_step_type(clean_line)
            if raw_mode is not None:
                mode = raw_mode
            elif mode not in _types.STEP_TYPES and clean_line.startswith(('And ', 'But ')):
                mode = _types.GIVEN

            allowed_prev_mode = (_types.BACKGROUND, _types.GIVEN, _types.WHEN)

            if (
                not scenario
                and prev_mode not in allowed_prev_mode
                and mode in _types.STEP_TYPES
            ):
                raise _parser.exceptions.FeatureError(
                    "Step definition outside of a Scenario or a Background",
                    line_number,
                    clean_line,
                    filename,
                )

            if mode == _types.FEATURE:
                if prev_mode is None or prev_mode == _types.TAG:
                    _, feature.name = _parser.parse_line(clean_line)
                    feature.line_number = line_number
                    feature.tags = _parser.get_tags(prev_line)
                elif prev_mode == _types.FEATURE:
                    if not stripped_line.startswith("#"):
                        description.append(clean_line)
                else:
                    raise _parser.exceptions.FeatureError(
                        "Multiple features are not allowed in a single feature file",
                        line_number,
                        clean_line,
                        filename,
                    )

            prev_mode = mode

            keyword, parsed_line = _parser.parse_line(clean_line)

            if mode in [_types.SCENARIO, _types.SCENARIO_OUTLINE]:
                if scenario and not keyword:
                    if not stripped_line.startswith("#"):
                        scenario.add_description_line(clean_line)
                    continue
                tags = _parser.get_tags(prev_line)
                scenario = _parser.ScenarioTemplate(
                    feature=feature,
                    name=parsed_line,
                    line_number=line_number,
                    tags=tags,
                    templated=mode == _types.SCENARIO_OUTLINE,
                )
                feature.scenarios[parsed_line] = scenario
            elif mode == _types.BACKGROUND:
                feature.background = _parser.Background(feature=feature, line_number=line_number)
            elif mode == _types.EXAMPLES:
                mode = _types.EXAMPLES_HEADERS
                scenario.examples.line_number = line_number
            elif mode == _types.EXAMPLES_HEADERS:
                scenario.examples.set_param_names(
                    [l for l in _parser.split_line(parsed_line) if l]
                )
                mode = _types.EXAMPLE_LINE
            elif mode == _types.EXAMPLE_LINE:
                scenario.examples.add_example(list(_parser.split_line(stripped_line)))
            elif mode and mode not in (_types.FEATURE, _types.TAG):
                step = _parser.Step(
                    name=parsed_line,
                    type=mode,
                    indent=line_indent,
                    line_number=line_number,
                    keyword=keyword,
                )
                if feature.background and not scenario:
                    feature.background.add_step(step)
                else:
                    scenario = __import__("typing").cast(_parser.ScenarioTemplate, scenario)
                    scenario.add_step(step)
            prev_line = clean_line

        feature.description = "\n".join(description).strip()
        return feature

    _parser.parse_feature = _patched_parse_feature

    import pytest_bdd.feature as _feature
    _feature.parse_feature = _patched_parse_feature
    _feature.features.clear()

    import re
    _parser.STEP_PARAM_RE = re.compile(r"<([^<>\s]+)>")

    _PATCHED = True
    logger.info("pytest-bdd parser patched: And/But + STEP_PARAM_RE fixes applied")
