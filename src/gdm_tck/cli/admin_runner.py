"""gdm-admin 工具执行器模块。

提供 AdminRunner 类，封装 gdm-admin 的常用命令模式，特别是 import 子命令。
"""

from __future__ import annotations

import logging
from pathlib import Path

from ..config import PROJECT_ROOT
from .runner import BaseRunner, CommandResult

logger = logging.getLogger(__name__)


class AdminRunner(BaseRunner):
    """gdm-admin 命令执行器。

    继承 BaseRunner，提供 gdm-admin 特有的命令构建方法。
    """

    def import_data(
        self,
        manifest_path: str,
        *,
        dry_run: bool = False,
        vertices_only: bool = False,
        edges_only: bool = False,
        on_conflict: str | None = None,
        append: bool = False,
        errors_out: str | None = None,
        allow_row_errors: bool = False,
        bulk: bool = False,
        validate: bool = False,
        no_precount: bool = False,
        bulk_allow_spill: bool = False,
        target: str | None = None,
        space: str | None = None,
        graph: str | None = None,
        import_root: str | None = None,
    ) -> CommandResult:
        """执行 import 命令。

        manifest_path 为相对于 testdata/import/ 的路径。
        内部解析为绝对路径，并自动设置 --import-root。

        Args:
            manifest_path: manifest 文件路径（相对于 testdata/import/）。
            dry_run: 是否仅验证不写入。
            vertices_only: 仅导入顶点。
            edges_only: 仅导入边。
            on_conflict: 冲突处理策略（skip/error）。
            append: 是否允许追加到非空图。
            errors_out: 错误行输出文件路径。
            allow_row_errors: 是否允许行级错误。
            bulk: 是否使用批量写入路径。
            validate: 是否在批量导入后运行验证检查。
            no_precount: 是否跳过预导入 CSV 计数。
            bulk_allow_spill: 是否允许溢写。
            target: 覆盖目标（space.graph 格式）。
            space: 覆盖空间。
            graph: 覆盖图名。
            import_root: 自定义数据根目录。

        Returns:
            CommandResult: 命令执行结果。
        """
        # 解析 manifest 绝对路径
        manifest_abs = (PROJECT_ROOT / "testdata" / "import" / manifest_path).resolve()
        if not manifest_abs.exists():
            logger.warning("Manifest file not found: %s", manifest_abs)

        # import-root 设置为 manifest 所在目录（除非显式指定）
        if import_root is None:
            import_root = str(manifest_abs.parent)

        args = [
            "import",
            "--manifest", str(manifest_abs),
            "--import-root", import_root,
        ]

        if dry_run:
            args.append("--dry-run")
        if vertices_only:
            args.append("--vertices-only")
        if edges_only:
            args.append("--edges-only")
        if on_conflict:
            args.extend(["--on-conflict", on_conflict])
        if append:
            args.append("--append")
        if errors_out:
            args.extend(["--errors-out", errors_out])
        if allow_row_errors:
            args.append("--allow-row-errors")
        if bulk:
            args.append("--bulk")
        if validate:
            args.append("--validate")
        if no_precount:
            args.append("--no-precount")
        if bulk_allow_spill:
            args.append("--bulk-allow-spill")
        if target:
            args.extend(["--target", target])
        if space:
            args.extend(["--space", space])
        if graph:
            args.extend(["--graph", graph])

        return self.run(args)

    def import_data_with_args(
        self,
        manifest_path: str,
        extra_args: list[str],
    ) -> CommandResult:
        """执行带自定义参数的 import 命令。

        用于支持步骤中直接传递参数字符串的场景。

        Args:
            manifest_path: manifest 文件路径（相对于 testdata/import/）。
            extra_args: 额外的命令行参数列表。

        Returns:
            CommandResult: 命令执行结果。
        """
        # 解析 manifest 绝对路径
        manifest_abs = (PROJECT_ROOT / "testdata" / "import" / manifest_path).resolve()
        if not manifest_abs.exists():
            logger.warning("Manifest file not found: %s", manifest_abs)

        # import-root 设置为 manifest 所在目录
        import_root = str(manifest_abs.parent)

        args = [
            "import",
            "--manifest", str(manifest_abs),
            "--import-root", import_root,
        ] + extra_args

        return self.run(args)

    def run_raw(self, subcommand: str, args: list[str] | None = None) -> CommandResult:
        """执行通用 admin 命令。

        用于支持未来扩展的 catalog、status 等子命令。

        Args:
            subcommand: 子命令名称（如 "status", "catalog"）。
            args: 可选的子命令参数列表。

        Returns:
            CommandResult: 命令执行结果。
        """
        cmd_args = [subcommand]
        if args:
            cmd_args.extend(args)
        return self.run(cmd_args)
