"""连接管理模块。"""

from .agent_patch import apply_gdm_agent_patch
from .bolt_client import BoltClient
from .bolt_pool import BoltConnectionPool

__all__ = ["BoltClient", "BoltConnectionPool", "apply_gdm_agent_patch"]
