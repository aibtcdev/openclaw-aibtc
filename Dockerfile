# OpenClaw + aibtc Docker Image
# Based on official OpenClaw image with aibtc-mcp-server pre-installed

FROM ghcr.io/openclaw/openclaw:v2026.2.2

# Install aibtc-mcp-server and mcporter globally
USER root
RUN npm install -g @aibtc/mcp-server@1.14.2 mcporter@0.7.3

# Install sudo and grant node user scoped privileges
# Agent can install packages but cannot get a root shell
RUN apt-get update && apt-get install -y --no-install-recommends sudo \
    && rm -rf /var/lib/apt/lists/* \
    && echo "node ALL=(root) NOPASSWD: /usr/bin/apt-get, /usr/bin/apt, /usr/local/bin/npm, /usr/bin/npx" > /etc/sudoers.d/node-agent \
    && chmod 0440 /etc/sudoers.d/node-agent

# Set default network
ENV NETWORK=mainnet

# Switch back to node user
USER node

# Default command runs the gateway
CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
