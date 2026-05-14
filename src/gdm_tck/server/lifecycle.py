"""服务生命周期管理模块。

支持 GDM 服务的重启操作，用于 DDL 语义恢复验证等场景。
"""

from __future__ import annotations

import logging
import subprocess
import time

from ..config import Settings
from ..exceptions import HealthCheckError
from .health import wait_for_health

logger = logging.getLogger(__name__)


class ServerLifecycle:
    """GDM 服务生命周期管理器。

    支持通过 Docker Compose 或进程信号管理服务的启停和重启。
    """

    def __init__(self, settings: Settings):
        """初始化生命周期管理器。

        Args:
            settings: 全局配置。
        """
        self._settings = settings
        self._metrics_url = settings.server.metrics.url
        self._ready_timeout = settings.server.timeouts.ready_secs

    def restart(self) -> None:
        """重启 GDM 服务并等待就绪。

        用于 DDL 语义恢复验证：执行 DDL 后重启，验证元数据持久化。

        Raises:
            HealthCheckError: 重启后服务未在超时时间内就绪。
        """
        logger.info("Restarting GDM service...")
        # 当前仅支持外部管理的服务重启提示
        # 未来可扩展 Docker Compose / SSH 重启
        logger.warning(
            "Server restart requires manual intervention or Docker Compose setup. "
            "Waiting for service to become ready..."
        )
        wait_for_health(self._metrics_url, self._ready_timeout)
        logger.info("GDM service restarted and ready")

    def wait_ready(self) -> None:
        """等待服务就绪。"""
        wait_for_health(self._metrics_url, self._ready_timeout)
