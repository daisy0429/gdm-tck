"""配置加载模块。

支持 TOML 文件 + 环境变量覆盖，优先级：环境变量 > 指定配置文件 > default.toml。
环境变量命名约定：前缀 GDM_TCK_，双下划线表示嵌套层级。
例: GDM_TCK_SERVER__BOLT_URI 对应 server.bolt_uri
"""

from __future__ import annotations

import logging
import os
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .exceptions import ConfigurationError

logger = logging.getLogger(__name__)

PROJECT_ROOT = Path(__file__).resolve().parents[2]
CONFIG_DIR = PROJECT_ROOT / "config"
ENV_PREFIX = "GDM_TCK_"


@dataclass(frozen=True)
class TimeoutSettings:
    """超时配置。"""

    connect_secs: float
    query_secs: float
    ready_secs: float
    retry_interval_secs: float
    max_retries: int


@dataclass(frozen=True)
class PoolSettings:
    """连接池配置。"""

    max_size: int


@dataclass(frozen=True)
class MetricsSettings:
    """服务指标端点配置。"""

    url: str


@dataclass(frozen=True)
class ServerSettings:
    """服务器连接配置。"""

    backend: str
    mode: str
    bolt_uri: str
    bolt_uris: list[str]
    username: str
    password: str
    database: str
    timeouts: TimeoutSettings
    pool: PoolSettings
    metrics: MetricsSettings


@dataclass(frozen=True)
class GrpcSettings:
    """gRPC 配置。"""

    enabled: bool
    address: str


@dataclass(frozen=True)
class TestSettings:
    """测试执行配置。"""

    tags: str
    parallel_workers: int
    feature_base_path: str


@dataclass(frozen=True)
class ReportSettings:
    """报告配置。"""

    allure_results_dir: str


@dataclass(frozen=True)
class PerformanceSettings:
    """性能测试配置。"""

    default_workers: int
    default_duration_secs: int


@dataclass(frozen=True)
class Settings:
    """全局配置容器，聚合所有子配置。"""

    server: ServerSettings
    grpc: GrpcSettings
    test: TestSettings
    report: ReportSettings
    performance: PerformanceSettings
    project_root: Path


def _deep_merge(base: dict, override: dict) -> dict:
    """递归合并两个字典，override 中的值覆盖 base 中的同名键。"""
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = _deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def _apply_env_overrides(config: dict) -> dict:
    """将环境变量覆盖应用到配置字典。

    环境变量命名规则：GDM_TCK_ 前缀 + 双下划线分隔的键路径。
    值类型自动推断：整数、浮点、布尔、列表(逗号分隔)。
    """
    for env_key, env_value in os.environ.items():
        if not env_key.startswith(ENV_PREFIX):
            continue
        # 去除前缀并转为小写键路径
        key_path = env_key[len(ENV_PREFIX) :].lower().split("__")
        _set_nested(config, key_path, _cast_env_value(env_value))
    return config


def _set_nested(d: dict, keys: list[str], value: Any) -> None:
    """在嵌套字典中按键路径设置值。"""
    for key in keys[:-1]:
        d = d.setdefault(key, {})
    d[keys[-1]] = value


def _cast_env_value(value: str) -> Any:
    """将环境变量字符串值转换为合适的 Python 类型。"""
    if value.lower() in ("true", "1", "yes", "on"):
        return True
    if value.lower() in ("false", "0", "no", "off"):
        return False
    try:
        return int(value)
    except ValueError:
        pass
    try:
        return float(value)
    except ValueError:
        pass
    # 逗号分隔的列表
    if "," in value:
        return [item.strip() for item in value.split(",")]
    return value


def _load_toml(path: Path) -> dict:
    """加载并解析 TOML 文件。"""
    if not path.exists():
        raise ConfigurationError(f"Configuration file not found: {path}")
    with open(path, "rb") as f:
        return tomllib.load(f)


def _build_settings(config: dict) -> Settings:
    """从合并后的配置字典构建 Settings 对象。"""
    server_cfg = config.get("server", {})
    timeouts_cfg = server_cfg.get("timeouts", {})
    pool_cfg = server_cfg.get("pool", {})
    metrics_cfg = server_cfg.get("metrics", {})
    grpc_cfg = config.get("grpc", {})
    test_cfg = config.get("test", {})
    report_cfg = config.get("report", {})
    perf_cfg = config.get("performance", {})

    timeouts = TimeoutSettings(
        connect_secs=float(timeouts_cfg.get("connect_secs", 30.0)),
        query_secs=float(timeouts_cfg.get("query_secs", 60.0)),
        ready_secs=float(timeouts_cfg.get("ready_secs", 300.0)),
        retry_interval_secs=float(timeouts_cfg.get("retry_interval_secs", 5.0)),
        max_retries=int(timeouts_cfg.get("max_retries", 10)),
    )

    pool = PoolSettings(max_size=int(pool_cfg.get("max_size", 100)))

    metrics = MetricsSettings(url=str(metrics_cfg.get("url", "http://127.0.0.1:9095")))

    server = ServerSettings(
        backend=str(server_cfg.get("backend", "gdm")),
        mode=str(server_cfg.get("mode", "standalone")),
        bolt_uri=str(server_cfg.get("bolt_uri", "bolt://127.0.0.1:7690")),
        bolt_uris=list(server_cfg.get("bolt_uris", [])),
        username=str(server_cfg.get("username", "SYSDBA")),
        password=str(server_cfg.get("password", "SYSDBA")),
        database=str(server_cfg.get("database", "default")),
        timeouts=timeouts,
        pool=pool,
        metrics=metrics,
    )

    grpc = GrpcSettings(
        enabled=bool(grpc_cfg.get("enabled", False)),
        address=str(grpc_cfg.get("address", "127.0.0.1:9830")),
    )

    test = TestSettings(
        tags=str(test_cfg.get("tags", "not ignore")),
        parallel_workers=int(test_cfg.get("parallel_workers", 1)),
        feature_base_path=str(test_cfg.get("feature_base_path", "features")),
    )

    report = ReportSettings(
        allure_results_dir=str(report_cfg.get("allure_results_dir", "allure-results")),
    )

    performance = PerformanceSettings(
        default_workers=int(perf_cfg.get("default_workers", 4)),
        default_duration_secs=int(perf_cfg.get("default_duration_secs", 30)),
    )

    return Settings(
        server=server,
        grpc=grpc,
        test=test,
        report=report,
        performance=performance,
        project_root=PROJECT_ROOT,
    )


def _validate_settings(settings: Settings) -> None:
    """验证配置有效性，无效时抛出 ConfigurationError。"""
    if not settings.server.bolt_uri:
        raise ConfigurationError("server.bolt_uri must not be empty")
    if settings.server.mode not in ("standalone", "distributed"):
        raise ConfigurationError(
            f"server.mode must be 'standalone' or 'distributed', got: {settings.server.mode}"
        )
    if settings.server.mode == "distributed" and not settings.server.bolt_uris:
        raise ConfigurationError("server.bolt_uris must be provided in distributed mode")
    if settings.server.timeouts.connect_secs <= 0:
        raise ConfigurationError("server.timeouts.connect_secs must be positive")
    if settings.server.timeouts.query_secs <= 0:
        raise ConfigurationError("server.timeouts.query_secs must be positive")
    _KNOWN_BACKENDS = {"gdm", "neo4j", "gdmbase"}
    if settings.server.backend not in _KNOWN_BACKENDS:
        logger.warning(
            "Unknown backend '%s'; agent patch will be skipped. "
            "If the server uses a non-standard agent prefix, "
            "register it in BACKEND_AGENT_PREFIXES.",
            settings.server.backend,
        )


def load_settings(config_path: Path | str | None = None) -> Settings:
    """加载配置并返回 Settings 实例。

    加载优先级（高覆盖低）：
    1. 环境变量 (GDM_TCK_*)
    2. config_path 指定的配置文件（或 GDM_TCK_CONFIG 环境变量）
    3. config/default.toml

    Args:
        config_path: 可选的额外配置文件路径，会覆盖 default.toml 中的值。

    Returns:
        Settings: 冻结的配置实例。

    Raises:
        ConfigurationError: 配置文件不存在或验证失败。
    """
    # 加载基础配置
    default_path = CONFIG_DIR / "default.toml"
    if not default_path.exists():
        raise ConfigurationError(f"Default config not found: {default_path}")
    config = _load_toml(default_path)

    # 加载覆盖配置文件
    override_path = config_path or os.environ.get("GDM_TCK_CONFIG")
    if override_path:
        override_file = Path(override_path)
        if not override_file.is_absolute():
            override_file = CONFIG_DIR / override_file
        override_config = _load_toml(override_file)
        config = _deep_merge(config, override_config)

    # 应用环境变量覆盖
    config = _apply_env_overrides(config)

    # 构建并验证
    settings = _build_settings(config)
    _validate_settings(settings)
    logger.info("Active backend: %s", settings.server.backend)
    return settings
