"""服务健康检查模块。

通过 HTTP 端点轮询验证 GDM 服务的存活和就绪状态。
"""

from __future__ import annotations

import logging
import time
from urllib.request import urlopen, Request
from urllib.error import URLError

from ..exceptions import HealthCheckError

logger = logging.getLogger(__name__)


def check_liveness(metrics_url: str) -> bool:
    """检查服务存活状态。

    Args:
        metrics_url: 指标端点基础 URL，如 "http://host:9095"。

    Returns:
        True 表示服务存活。
    """
    return _probe_endpoint(f"{metrics_url}/live")


def check_readiness(metrics_url: str) -> bool:
    """检查服务就绪状态。

    Args:
        metrics_url: 指标端点基础 URL。

    Returns:
        True 表示服务就绪。
    """
    return _probe_endpoint(f"{metrics_url}/ready")


def wait_for_health(metrics_url: str, timeout_secs: float = 300.0,
                    interval_secs: float = 5.0) -> None:
    """等待服务健康（存活且就绪）。

    轮询健康端点直到服务就绪或超时。

    Args:
        metrics_url: 指标端点基础 URL。
        timeout_secs: 最大等待时间（秒）。
        interval_secs: 轮询间隔（秒）。

    Raises:
        HealthCheckError: 超时仍未就绪时抛出。
    """
    start = time.time()
    while time.time() - start < timeout_secs:
        if check_liveness(metrics_url) and check_readiness(metrics_url):
            elapsed = time.time() - start
            logger.info("Service ready at %s (%.1fs)", metrics_url, elapsed)
            return
        time.sleep(interval_secs)

    raise HealthCheckError(
        f"Service at {metrics_url} not ready after {timeout_secs}s"
    )


def _probe_endpoint(url: str, timeout: float = 5.0) -> bool:
    """探测单个 HTTP 端点。"""
    try:
        req = Request(url, method="GET")
        with urlopen(req, timeout=timeout) as response:
            return response.status == 200
    except (URLError, OSError, TimeoutError):
        return False
