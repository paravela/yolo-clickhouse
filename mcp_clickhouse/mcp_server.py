import logging
import os
import sys
import json

import clickhouse_connect
from mcp.server.fastmcp import FastMCP

MCP_SERVER_NAME = "mcp-clickhouse"

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(MCP_SERVER_NAME)

# Print startup message to stderr
print(f"WAAAGH! MCP-CLICKHOUSE SERVER STARTIN' UP!", file=sys.stderr)
print(f"DA BRUTAL SQL EXECUTION MACHINE IS READY!", file=sys.stderr)

# Create the MCP server
mcp = FastMCP(MCP_SERVER_NAME)

def create_clickhouse_client():
    """Create and return a ClickHouse client with the current configuration."""
    # Get configuration from environment variables
    host = os.environ.get("CLICKHOUSE_HOST", "localhost")
    port = int(os.environ.get("CLICKHOUSE_PORT", 8123))
    username = os.environ.get("CLICKHOUSE_USER", "default")
    password = os.environ.get("CLICKHOUSE_PASSWORD", "")
    secure = os.environ.get("CLICKHOUSE_SECURE", "false").lower() == "true"

    client_config = {
        "host": host,
        "port": port,
        "username": username,
        "password": password,
        "secure": secure,
    }

    logger.info(
        f"Creating ClickHouse client connection to {client_config['host']}:{client_config['port']} "
        f"as {client_config['username']}"
    )
    print(f"CONNECTIN' TO CLICKHOUSE AT {client_config['host']}:{client_config['port']}", file=sys.stderr)

    try:
        client = clickhouse_connect.get_client(**client_config)
        # Test the connection
        version = client.server_version
        logger.info(f"Successfully connected to ClickHouse server version {version}")
        print(f"CLICKHOUSE FOUND! VERSION {version}", file=sys.stderr)
        return client
    except Exception as e:
        error_msg = f"Failed to connect to ClickHouse: {str(e)}"
        logger.error(error_msg)
        print(f"ZOGGIN' ERROR! {error_msg}", file=sys.stderr)
        raise

@mcp.tool()
def exec_sql(query: str):
    """Run any SQL query on ClickHouse.

    Args:
        query: SQL query to execute

    Returns:
        Query results or command output
    """
    logger.info(f"Executing SQL: {query}")
    print(f"EXECUTIN' SQL QUERY: {query}", file=sys.stderr)

    client = create_clickhouse_client()

    try:
        # Execute query
        result = client.query(query)

        # Format results for return
        column_names = result.column_names
        rows = []
        for row in result.result_rows:
            row_dict = {}
            for i, col_name in enumerate(column_names):
                row_dict[col_name] = row[i]
            rows.append(row_dict)

        logger.info(f"Query returned {len(rows)} rows")
        print(f"QUERY RESULTS: GOT {len(rows)} ROWS", file=sys.stderr)

        # Format the result as JSON string for MCP protocol
        result_json = json.dumps({"rows": rows, "columns": column_names})
        return {"content": [{"type": "text", "text": result_json}], "isError": False}
    except Exception as err:
        error_msg = f"Error executing SQL: {err}"
        logger.error(error_msg)
        print(f"ZOGGIN' SQL ERROR: {err}", file=sys.stderr)
        return {"content": [{"type": "text", "text": error_msg}], "isError": True}
