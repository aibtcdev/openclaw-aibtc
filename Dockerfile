# OpenClaw + aibtc Docker Image
# Based on official OpenClaw image with aibtc-mcp-server pre-installed

FROM ghcr.io/openclaw/openclaw:v2026.2.2

# Install aibtc-mcp-server and mcporter globally
USER root
RUN npm install -g @aibtc/mcp-server@1.14.2 mcporter@0.7.3

# Install sudo, git, and GitHub CLI; grant node user scoped privileges
# hadolint ignore=DL3008,DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
    && apt-get install -y --no-install-recommends sudo git curl gpg \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/* \
    && echo "node ALL=(root) NOPASSWD: /usr/bin/apt-get, /usr/bin/apt, /usr/local/bin/npm, /usr/bin/npx" > /etc/sudoers.d/node-agent \
    && chmod 0440 /etc/sudoers.d/node-agent

# Set default network
ENV NETWORK=mainnet

# Switch back to node user
USER node

# Default command runs the gateway
CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
