# MCP-CLICKHOUSE

DA MOST BRUTAL AN' SIMPLE WAY TA QUERY CLICKHOUSE FROM YER MCP TOOLS!

## WOT IT DOES

MCP-CLICKHOUSE is a Model Context Protocol (MCP) server dat gives ya a simple way ta run any SQL query on ClickHouse. It only has one tool - `exec_sql` - cuz dat's all ya need! LESS IS MORE, YA GROT!

## INSTALLATION

```bash
pip install -e .
```

## RUNNIN' DA SERVER

### USIN' DOCKER (DA BEST WAY!)

First, build da image:

```bash
docker build -t mcp-clickhouse .
```

Den run a query by pipin' a JSON-RPC message sequence:

```bash
# Create a file with the proper MCP initialization sequence
cat > mcp_query.json << EOF
{"jsonrpc": "2.0", "id": "init-1", "method": "initialize", "params": {"protocolVersion": "0.1.0", "capabilities": {}, "clientInfo": {"name": "test-client", "version": "1.0.0"}}}
{"jsonrpc": "2.0", "method": "notifications/initialized"}
{"jsonrpc": "2.0", "id": "sql-1", "method": "tools/call", "params": {"name": "exec_sql", "arguments": {"query": "SELECT 1 as test"}}}
EOF

# Run the query
cat mcp_query.json | docker run -i --rm mcp-clickhouse
```

### USIN' PYTHON (IF YA MUST)

```bash
export CLICKHOUSE_HOST=localhost
export CLICKHOUSE_USER=default
export CLICKHOUSE_PASSWORD=clickhouse
python -m mcp_clickhouse.main
```

## ENVIRONMENT VARIABLES

'ERE ARE DA ENVIRONMENT VARIABLES YA CAN USE:

- `CLICKHOUSE_HOST`: ClickHouse server hostname (default: `localhost`)
- `CLICKHOUSE_PORT`: ClickHouse server port (default: `8123`)
- `CLICKHOUSE_USER`: ClickHouse username (default: `default`)
- `CLICKHOUSE_PASSWORD`: ClickHouse password (default: empty string)
- `CLICKHOUSE_SECURE`: Whether ta use HTTPS (default: `false`)

## HOW TA CALL DA EXEC_SQL TOOL

### MCP INITIALIZATION SEQUENCE

Before ya can call any tools, ya need ta initialize da MCP server with dis sequence:

```json
// 1. Initialize request
{"jsonrpc": "2.0", "id": "init-1", "method": "initialize", "params": {"protocolVersion": "0.1.0", "capabilities": {}, "clientInfo": {"name": "test-client", "version": "1.0.0"}}}

// 2. Initialized notification
{"jsonrpc": "2.0", "method": "notifications/initialized"}

// 3. Now ya can call tools!
```

### JSON-RPC FORMAT

Da proper JSON-RPC format (version 2.0) for callin' da exec_sql tool is:

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "id": "456",
  "params": {
    "name": "exec_sql",
    "arguments": {
      "query": "SELECT * FROM system.tables LIMIT 5"
    }
  }
}
```

### EXAMPLES

#### CREATIN' A TABLE

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "id": "789",
  "params": {
    "name": "exec_sql",
    "arguments": {
      "query": "CREATE TABLE IF NOT EXISTS test_table (id UInt32, name String) ENGINE = MergeTree() ORDER BY id"
    }
  }
}
```

#### INSERTIN' DATA

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "id": "101112",
  "params": {
    "name": "exec_sql",
    "arguments": {
      "query": "INSERT INTO test_table VALUES (1, 'WAAAGH!')"
    }
  }
}
```

#### RUNNIN' A QUERY

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "id": "131415",
  "params": {
    "name": "exec_sql",
    "arguments": {
      "query": "SELECT * FROM test_table"
    }
  }
}
```

## RESPONSE FORMAT

Da server will respond with a JSON-RPC response like dis:

```json
{
  "jsonrpc": "2.0",
  "id": "131415",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"rows\": [{\"id\": 1, \"name\": \"WAAAGH!\"}], \"columns\": [\"id\", \"name\"]}"
      }
    ],
    "isError": false
  }
}
```

If dere's an error, you'll get:

```json
{
  "jsonrpc": "2.0",
  "id": "131415",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Error executing SQL: [error message]"
      }
    ],
    "isError": true
  }
}
```