FROM clickhouse/clickhouse-server:latest as clickhouse

FROM python:3.13-slim

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    build-essential \
    curl \
    procps \
    sudo \
    lsof \
    && rm -rf /var/lib/apt/lists/*

# Create clickhouse user and group
RUN groupadd -r clickhouse --gid=101 || echo "Group clickhouse already exists" && \
    useradd -r -g clickhouse --uid=101 --home-dir=/var/lib/clickhouse --shell=/bin/bash clickhouse || echo "User clickhouse already exists"

WORKDIR /app

# Copy ClickHouse files from the official image
COPY --from=clickhouse /usr/bin/clickhouse-server /usr/bin/
COPY --from=clickhouse /usr/bin/clickhouse-client /usr/bin/
COPY --from=clickhouse /etc/clickhouse-server /etc/clickhouse-server
COPY --from=clickhouse /var/lib/clickhouse /var/lib/clickhouse
COPY --from=clickhouse /usr/share/clickhouse /usr/share/clickhouse

# Copy application code
COPY . /app/

# Install Python dependencies directly
RUN pip install --no-cache-dir mcp[cli]>=1.3.0 python-dotenv>=1.0.1 clickhouse-connect>=0.8.0 pip-system-certs>=4.0

# Configure ClickHouse with a local password
RUN mkdir -p /etc/clickhouse-server/config.d/ && \
    echo '<?xml version="1.0"?>' > /etc/clickhouse-server/config.d/local-settings.xml && \
    echo '<clickhouse>' >> /etc/clickhouse-server/config.d/local-settings.xml && \
    echo '    <listen_host>0.0.0.0</listen_host>' >> /etc/clickhouse-server/config.d/local-settings.xml && \
    echo '    <default_password>clickhouse</default_password>' >> /etc/clickhouse-server/config.d/local-settings.xml && \
    echo '</clickhouse>' >> /etc/clickhouse-server/config.d/local-settings.xml

# Update users.xml for password authentication
RUN sed -i 's/<password>.*<\/password>/<password>clickhouse<\/password>/g' /etc/clickhouse-server/users.xml

# Create log directory and set permissions
RUN mkdir -p /var/log/clickhouse-server && \
    chmod -R 777 /var/log/clickhouse-server && \
    chown -R clickhouse:clickhouse /var/log/clickhouse-server /var/lib/clickhouse /etc/clickhouse-server && \
    chmod +x /usr/bin/clickhouse-server /usr/bin/clickhouse-client

# Expose ClickHouse ports
EXPOSE 8123 9000

# Set environment variables for ClickHouse connection
ENV CLICKHOUSE_HOST=localhost
ENV CLICKHOUSE_USER=default
ENV CLICKHOUSE_PASSWORD=clickhouse
ENV CLICKHOUSE_SECURE=false

# Start ClickHouse in background, then run the simplified MCP server
CMD ["bash", "-c", "sudo -E -u clickhouse clickhouse-server --config-file=/etc/clickhouse-server/config.xml & echo 'Waiting for ClickHouse to start...' >&2 && sleep 5 && echo 'ClickHouse started, MCP server is ready for STDIO input!' >&2 && python -m mcp_clickhouse.main"]