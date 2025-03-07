#!/bin/bash

# Create a temporary file for the input
INPUT_FILE=$(mktemp)

# Write the sequence of messages to the input file with simplified queries
cat > "$INPUT_FILE" << EOF
{"jsonrpc": "2.0", "id": "init-1", "method": "initialize", "params": {"protocolVersion": "0.1.0", "capabilities": {}, "clientInfo": {"name": "test-client", "version": "1.0.0"}}}
{"jsonrpc": "2.0", "method": "notifications/initialized"}

{"jsonrpc": "2.0", "id": "query-data", "method": "tools/call", "params": {"name": "exec_sql", "arguments": {"query": "SELECT * FROM orky_db.waaagh_table"}}}

{"jsonrpc": "2.0", "id": "enable-logging", "method": "tools/call", "params": {"name": "exec_sql", "arguments": {"query": "SET log_queries=1"}}}

{"jsonrpc": "2.0", "id": "complex-query", "method": "tools/call", "params": {"name": "exec_sql", "arguments": {"query": "SELECT *, power_level/100 as percentage_power FROM orky_db.waaagh_table WHERE power_level > 1000 ORDER BY power_level DESC"}}}

{"jsonrpc": "2.0", "id": "show-settings", "method": "tools/call", "params": {"name": "exec_sql", "arguments": {"query": "SHOW SETTINGS LIKE '%profile%'"}}}

{"jsonrpc": "2.0", "id": "explain-query", "method": "tools/call", "params": {"name": "exec_sql", "arguments": {"query": "EXPLAIN SELECT * FROM orky_db.waaagh_table WHERE power_level > 1000"}}}
EOF

# Run the Docker container with the input file
echo "Running MCP server with simplified queries..."
cat "$INPUT_FILE" | docker run -i --rm paravela/yolo-clickhouse

# Clean up
rm "$INPUT_FILE"