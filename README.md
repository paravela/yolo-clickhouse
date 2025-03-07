# MCP-CLICKHOUSE

A simple and efficient way to query ClickHouse using the Model Context Protocol (MCP).

## What It Does

MCP-CLICKHOUSE is a Model Context Protocol (MCP) server that provides a straightforward way to run SQL queries on ClickHouse. It includes a single tool - `exec_sql` - which is all you need for efficient database interaction.

## Installation

```bash
pip install -e .
```

## Running the Server

### Using Docker (Recommended)

First, build the image:

```bash
docker build -t paravela/yolo-clickhouse .
```

Then run a query by piping a JSON-RPC message sequence:

```bash
# Create a file with the proper MCP initialization sequence
cat > mcp_query.json << EOF
{"jsonrpc": "2.0", "id": "init-1", "method": "initialize", "params": {"protocolVersion": "0.1.0", "capabilities": {}, "clientInfo": {"name": "test-client", "version": "1.0.0"}}}
{"jsonrpc": "2.0", "method": "notifications/initialized"}
{"jsonrpc": "2.0", "id": "sql-1", "method": "tools/call", "params": {"name": "exec_sql", "arguments": {"query": "SELECT 1 as test"}}}
EOF

# Run the query
cat mcp_query.json | docker run -i --rm paravela/yolo-clickhouse
```

### Using Python

```bash
export CLICKHOUSE_HOST=localhost
export CLICKHOUSE_USER=default
export CLICKHOUSE_PASSWORD=clickhouse
python -m mcp_clickhouse.main
```

## Environment Variables

The following environment variables can be used to configure the server:

- `CLICKHOUSE_HOST`: ClickHouse server hostname (default: `localhost`)
- `CLICKHOUSE_PORT`: ClickHouse server port (default: `8123`)
- `CLICKHOUSE_USER`: ClickHouse username (default: `default`)
- `CLICKHOUSE_PASSWORD`: ClickHouse password (default: empty string)
- `CLICKHOUSE_SECURE`: Whether to use HTTPS (default: `false`)

## How to Call the exec_sql Tool

### MCP Initialization Sequence

Before you can call any tools, you need to initialize the MCP server with this sequence:

```json
// 1. Initialize request
{"jsonrpc": "2.0", "id": "init-1", "method": "initialize", "params": {"protocolVersion": "0.1.0", "capabilities": {}, "clientInfo": {"name": "test-client", "version": "1.0.0"}}}

// 2. Initialized notification
{"jsonrpc": "2.0", "method": "notifications/initialized"}

// 3. Now you can call tools
```

### JSON-RPC Format

The proper JSON-RPC format (version 2.0) for calling the exec_sql tool is:

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

### Examples

#### Creating a Table

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

#### Inserting Data

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "id": "101112",
  "params": {
    "name": "exec_sql",
    "arguments": {
      "query": "INSERT INTO test_table VALUES (1, 'Test')"
    }
  }
}
```

#### Running a Query

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

## Response Format

The server will respond with a JSON-RPC response like this:

```json
{
  "jsonrpc": "2.0",
  "id": "131415",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"rows\": [{\"id\": 1, \"name\": \"Test\"}], \"columns\": [\"id\", \"name\"]}"
      }
    ],
    "isError": false
  }
}
```

If there's an error, you'll get:

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