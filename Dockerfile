# Build (unchanged)
FROM golang:1.25-bookworm AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN make build

# Node (we just copy the binaries later)
FROM node:22-trixie-slim AS node

# Runtime: switch to Debian 13 (trixie)
FROM ghcr.io/astral-sh/uv:python3.14-trixie-slim

# Pull in latest security patches in the base
RUN apt-get update && apt-get -y dist-upgrade --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

# upgrade PIP to fix CVE-2025-8869
RUN python3 -m pip install --no-cache-dir --upgrade "pip>=25.3"


# Add Node/npm
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx && \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Your Go binary
COPY --from=builder /app/build/mcp-proxy /main
ENTRYPOINT ["/main"]
CMD ["--config", "/config/config.json"]
