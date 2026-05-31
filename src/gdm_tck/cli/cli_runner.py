"""gdm-cli 工具执行器模块。

提供 CliRunner 类，封装 gdm-cli 的常用命令模式。
"""

from __future__ import annotations

import logging

from .runner import BaseRunner, CommandResult

logger = logging.getLogger(__name__)


class CliRunner(BaseRunner):
    """gdm-cli 命令执行器。

    继承 BaseRunner，提供 gdm-cli 特有的命令构建方法。
    """

    def execute(
        self,
        cypher: str,
        *,
        graph: str | None = None,
        format: str = "table",  # noqa: A002
        max_rows: int | None = None,
    ) -> CommandResult:
        """执行单条 Cypher 查询（-e 模式）。

        Args:
            cypher: Cypher 查询语句。
            graph: 可选的目标图名称。
            format: 输出格式（table, tsv, json）。
            max_rows: 可选的最大行数限制。

        Returns:
            CommandResult: 命令执行结果。
        """
        args = ["-e", cypher, "--format", format]
        if graph:
            args.extend(["-g", graph])
        if max_rows is not None:
            args.extend(["--max-rows", str(max_rows)])
        return self.run(args)

    def batch(self, stdin_data: str, *, graph: str | None = None) -> CommandResult:
        """执行批处理模式（--batch）。

        Args:
            stdin_data: 标准输入数据。
            graph: 可选的目标图名称。

        Returns:
            CommandResult: 命令执行结果。
        """
        args = ["--batch"]
        if graph:
            args.extend(["-g", graph])
        return self.run(args, stdin=stdin_data)

    def run_raw(self, args: list[str], *, stdin: str | None = None) -> CommandResult:
        """执行原始命令（透传所有参数）。

        Args:
            args: 参数列表。
            stdin: 可选的标准输入数据。

        Returns:
            CommandResult: 命令执行结果。
        """
        return self.run(args, stdin=stdin)
