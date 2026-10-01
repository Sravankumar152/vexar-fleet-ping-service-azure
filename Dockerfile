# syntax=docker/dockerfile:1

# =============================================================================
# Multi-stage build for a small, secure production image.
# Original issues fixed: unpinned `node:latest`, ran as root, installed ALL
# deps (incl. dev), exposed SSH (port 22), no healthcheck, no signal handling.
# =============================================================================

# ---- deps: install production dependencies only ----------------------------
FROM node:26.10-alpine AS deps
WORKDIR /app
# Copy manifests first for better layer caching.
# NOTE: package-lock.json must be committed so `npm ci` gives reproducible,
# audited installs (see README — generate it once with `npm install`).
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# ---- runtime: minimal image that only contains what we need to run ----------
FROM node:26.10-alpine AS runtime
ENV NODE_ENV=production \
    NPM_CONFIG_UPDATE_NOTIFIER=false

# tini = proper PID 1: forwards signals (graceful shutdown) and reaps zombies.
RUN apk add --no-cache tini

WORKDIR /app

# Bring in vetted deps and only the runtime source (no tests, IaC, docs — see
# .dockerignore).
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY server.js ./
COPY src ./src
COPY db ./db
COPY scripts ./scripts

# Drop privileges: run as the built-in non-root `node` user.
USER node

EXPOSE 3000

# Container-level health (compose / docker). Kubernetes uses the HTTP probes.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:3000/healthz',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "server.js"]
