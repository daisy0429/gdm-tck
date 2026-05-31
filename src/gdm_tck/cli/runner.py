"""CLI 命令执行基础设施模块。

提供 CommandResult 数据类和 BaseRunner 基类，封装 subprocess 调用和超时处理。
"""

from __future__ import annotations

import logging
import shlex
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from ..exceptions import ConfigurationError

logger = logging.getLogger(__name__)


@dataclass
class CommandResult:
    """CLI 命令执行结果。

    run() 默认不抛异常，所有信息封装在此结构中。
    """

    exit_code: int  # 超时时 exit_code=-1
    stdout: str
    stderr: str
    command: list[str]
    duration_secs: float

    @property
    def succeeded(self) -> bool:
        """判断命令是否成功执行。"""
        return self.exit_code == 0

    @property
    def stdout_lines(self) -> list[str]:
        """将 stdout 按行分割，过滤空行。"""
        return [line for line in self.stdout.splitlines() if line.strip()]

    @property
    def stderr_lines(self) -> list[str]:
        """将 stderr 按行分割，过滤空行。"""
        return [line for line in self.stderr.splitlines() if line.strip()]


class BaseRunner:
    """CLI 工具执行器基类。

    封装二进制调用、连接参数构建、超时处理和结果封装。
    子类通过继承获得通用能力，只需实现特定命令构建逻辑。
    """

    def __init__(
        self,
        binary_path: str,
        host: str,
        port: int,
        user: str,
        password: str,
        timeout: float = 60.0,
    ):
        """初始化基类执行器。

        Args:
            binary_path: CLI 二进制文件路径（相对或绝对）。
            host: gRPC 服务器主机地址。
            port: gRPC 服务器端口。
            user: 认证用户名。
            password: 认证密码。
            timeout: 命令执行超时时间（秒）。

        Raises:
            ConfigurationError: 二进制文件不存在时抛出。
        """
        self._binary_path = self._resolve_binary(binary_path)
        self._host = host
        self._port = port
        self._user = user
        self._password = password
        self._timeout = timeout
        self._base_args = self._build_base_args()

    def _resolve_binary(self, path: str) -> str:
        """解析并验证二进制文件路径。

        支持相对路径（相对于项目根目录）和绝对路径。

        Args:
            path: 原始路径字符串。

        Returns:
            str: 验证后的绝对路径。

        Raises:
            ConfigurationError: 文件不存在或不可执行时抛出。
        """
        from ..config import PROJECT_ROOT

        binary = Path(path)
        if not binary.is_absolute():
            binary = PROJECT_ROOT / path

        resolved = binary.resolve()
        if not resolved.exists():
            raise ConfigurationError(f"CLI binary not found: {resolved} (original: {path})")

        return str(resolved)

    def _build_base_args(self) -> list[str]:
        """构建通用连接参数。

        使用 --url 格式（同时被 gdm-cli 和 gdm-admin 支持，更简洁）。

        Returns:
            list[str]: 基础参数列表 [--url, url, -u, user, -p, password]。
        """
        url = f"http://{self._host}:{self._port}"
        return [
            "--url", url,
            "-u", self._user,
            "-p", self._password,
        ]

    def run(
        self,
        args: list[str],
        *,
        stdin: str | None = None,
        timeout: float | None = None,
    ) -> CommandResult:
        """执行 CLI 命令。

        默认不抛异常，所有结果封装在 CommandResult 中。
        捕获 TimeoutExpired，返回 exit_code=-1。

        Args:
            args: 命令参数列表（不含二进制路径和基础连接参数）。
            stdin: 可选的标准输入数据。
            timeout: 可选的超时覆盖（秒）。

        Returns:
            CommandResult: 命令执行结果。
        """
        cmd = [self._binary_path] + self._base_args + args
        cmd_str = " ".join(shlex.quote(a) for a in cmd)
        logger.debug("Executing CLI command: %s", cmd_str)

        effective_timeout = timeout if timeout is not None else self._timeout
        start = time.time()

        try:
            result = subprocess.run(
                cmd,
                input=stdin,
                capture_output=True,
                text=True,
                timeout=effective_timeout,
            )
            duration = time.time() - start
            return CommandResult(
                exit_code=result.returncode,
                stdout=result.stdout,
                stderr=result.stderr,
                command=cmd,
                duration_secs=duration,
            )
        except subprocess.TimeoutExpired as e:
            duration = time.time() - start
            logger.warning("CLI command timed out after %.1fs: %s", effective_timeout, cmd_str)
            return CommandResult(
                exit_code=-1,
                stdout=e.stdout or "",
                stderr=e.stderr or "Command timed out",
                command=cmd,
                duration_secs=duration,
            )
        except Exception as e:
            duration = time.time() - start
            logger.error("CLI command failed: %s - %s", cmd_str, e)
            return CommandResult(
                exit_code=-1,
                stdout="",
                stderr=str(e),
                command=cmd,
                duration_secs=duration,
            )
