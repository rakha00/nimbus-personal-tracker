# AI worker: Claude Code + the Nimbus worker and MCP server, prebuilt with
#   dart compile exe mcp/bin/{worker,nimbus_mcp}.dart --target-os=linux --target-arch=x64
# and copied here as nimbus-worker and nimbus-mcp (not in Git).
FROM node:22-slim
ARG CLAUDE_CODE_VERSION=2.1.332
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* \
 && npm install -g --no-fund --no-audit @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} && npm cache clean --force
COPY nimbus-worker nimbus-mcp /usr/local/bin/
USER node
WORKDIR /home/node
CMD ["nimbus-worker"]
