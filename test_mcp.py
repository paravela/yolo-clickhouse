#!/usr/bin/env python3
import json
import subprocess
import sys

# The sequence of messages to send to the MCP server
messages = [
    # 1. Initialize request
    {
        "jsonrpc": "2.0",
        "id": "init-1",
        "method": "initialize",
        "params": {
            "protocolVersion": "0.1.0",
            "capabilities": {},
            "clientInfo": {
                "name": "test-client",
                "version": "1.0.0"
            }
        }
    },
    # 2. Initialized notification
    {
        "jsonrpc": "2.0",
        "method": "initialized"
    },
    # 3. List tools request
    {
        "jsonrpc": "2.0",
        "id": "tools-1",
        "method": "tools/list"
    },
    # 4. Call the exec_sql tool
    {
        "jsonrpc": "2.0",
        "id": "sql-1",
        "method": "tools/call",
        "params": {
            "name": "exec_sql",
            "parameters": {
                "query": "SELECT 1 as test"
            }
        }
    }
]

# Convert messages to newline-delimited JSON
input_data = "\n".join(json.dumps(msg) for msg in messages)

# Run the Docker container with the input data
try:
    result = subprocess.run(
        ["docker", "run", "-i", "--rm", "mcp-clickhouse"],
        input=input_data.encode('utf-8'),
        capture_output=True,
        text=True
    )

    # Print stderr for debugging
    print("STDERR:", file=sys.stderr)
    print(result.stderr, file=sys.stderr)

    # Print stdout (the responses)
    print("STDOUT:")
    print(result.stdout)

    # Print exit code
    print(f"Exit code: {result.returncode}")

except Exception as e:
    print(f"Error running Docker container: {e}", file=sys.stderr)
    sys.exit(1)