"""pytest-bdd 解析器补丁模块。

修复 pytest_bdd.parser.parse_feature 中的一个 bug：
当 Scenario 的第一个步骤使用 ``And`` 作为前缀时（如 ``And having executed:``），
``get_step_type("And having executed:")`` 返回 ``None``，
导致 ``mode = None or prev_mode`` 将 mode 错误地继承为 ``SCENARIO``，
进而在场景内部创建出同名的幽灵 Scenario。

5 个受影响的场景（[25]-[29]）各自创建一个幽灵，但由于 feature.scenarios
是 OrderedDict 且所有幽灵 key 相同（``"having executed:"``），
4 个被覆盖，仅剩最后一个幽灵偷走场景 [29] 的断言步骤。

此补丁的修复：当 ``get_step_type`` 返回 ``None``（And/But 前缀），
仅在前一个 mode 是步骤类型（given/when/then）时才继承该 mode，
否则默认视为 ``GIVEN`` 类型。
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

        for line_number, line in enumerate(content.splitlines(), start=1):
            unindented_line = line.lstrip()
            line_indent = len(line) - len(unindented_line)
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
            # 修复：仅在前一个 mode 是步骤类型 or clean_line 为空时才继承 mode，
            # 否则默认 GIVEN。（clean_line 为空时保持原 mode，供 description 收集）
            raw_mode = _parser.get_step_type(clean_line)
            if raw_mode is not None:
                mode = raw_mode
            elif mode not in _types.STEP_TYPES and clean_line:
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

    _PATCHED = True
    logger.info("pytest-bdd parser patched: And/But after Scenario now defaults to GIVEN")
