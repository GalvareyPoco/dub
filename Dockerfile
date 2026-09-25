FROM node:23.11.0-bookworm-slim AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable \
    && corepack prepare pnpm@9.15.9 --activate

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app


# -----------------------
# Install dependencies
# -----------------------
FROM base AS deps

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./
COPY apps ./apps
COPY packages ./packages

RUN pnpm install --frozen-lockfile



# -----------------------
# Build Dub
# -----------------------
FROM deps AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_OPTIONS="--max-old-space-size=6144"

RUN pnpm --filter web build

# -----------------------
# Production
# -----------------------
FROM base AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

COPY --from=builder /app /app

EXPOSE 3000

CMD ["pnpm", "--filter", "web", "start", "--", "-p", "3000"]
