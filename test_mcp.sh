#!/bin/bash

# Create a temporary file for the input
INPUT_FILE=$(mktemp)

# Write the sequence of messages to the input file
cat > "$INPUT_FILE" << EOF
{"jsonrpc": "2.0", "id": "init-1", "method": "initialize", "params": {"protocolVersion": "0.1.0", "capabilities": {}, "clientInfo": {"name": "test-client", "version": "1.0.0"}}}
{"jsonrpc": "2.0", "method": "notifications/initialized"}
{"jsonrpc": "2.0", "id": "tools-1", "method": "tools/list"}
{"jsonrpc": "2.0", "id": "sql-1", "method": "tools/call", "params": {"name": "exec_sql", "arguments": {"query": "SELECT 1 as test"}}}
EOF

# Run the Docker container with the input file
echo "Running MCP server with initialization sequence..."
cat "$INPUT_FILE" | docker run -i --rm paravela/yolo-clickhouse

# Clean up
rm "$INPUT_FILE"