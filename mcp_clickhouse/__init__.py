"""MCP-CLICKHOUSE - DA MOST BRUTAL AN' SIMPLE WAY TA QUERY CLICKHOUSE FROM YER MCP TOOLS!"""

from .mcp_server import (
    create_clickhouse_client,
    exec_sql,
    mcp,
)

__all__ = [
    "exec_sql",
    "create_clickhouse_client",
    "mcp",
]
