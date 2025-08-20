# ── Build stage (Go) ──────────────────────────────────────────────
# Use latest patched Go toolchain
FROM golang:1.25-bookworm AS builder
WORKDIR /app

# Cache deps
COPY go.mod go.sum ./
RUN go mod download

# Build
COPY . .
# If your binary can be static, consider:
# ENV CGO_ENABLED=0
# RUN go build -trimpath -ldflags "-s -w" -o build/mcp-proxy ./...
RUN make build

# ── Node stage (unchanged) ────────────────────────────────────────
FROM node:lts-bookworm-slim AS node

# ── Final stage (python + node + your binary) ─────────────────────
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx && \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs

COPY --from=builder /app/build/mcp-proxy /main
ENTRYPOINT ["/main"]
CMD ["--config", "/config/config.json"]
