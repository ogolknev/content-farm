FROM debian:bookworm-slim

# System dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      tzdata \
      python3 \
      python3-venv \
      python3-pip \
      ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install n8n with npm (faster in CI/CD)
RUN npm install -g n8n

# Create Python venv
RUN python3 -m venv /opt/venv

# Install Python dependencies in venv
COPY scripts/auto_posting/requirements.txt /tmp/auto_posting_req.txt
COPY scripts/clip_factory/requirements.txt /tmp/clip_factory_req.txt
RUN /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel && \
    /opt/venv/bin/pip install --no-cache-dir -r /tmp/auto_posting_req.txt && \
    /opt/venv/bin/pip install --no-cache-dir -r /tmp/clip_factory_req.txt

# Create non-root user and data dir
RUN useradd -m -d /home/n8n -s /bin/bash n8n && \
    mkdir -p /data && chown -R n8n:n8n /data /home/n8n /opt/venv

WORKDIR /data
EXPOSE 5678

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["n8n"]
