# Use the official Elixir image as base
FROM elixir:1.15-alpine AS builder

# Install build dependencies
RUN apk add --no-cache build-base git nodejs npm

# Set working directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=dev

# Copy mix files (mix.lock is optional)
COPY mix.exs ./
COPY mix.lock* ./

# Install dependencies
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy config files
COPY config/config.exs config/$MIX_ENV.exs config/
COPY config/runtime.exs config/

# Copy assets
COPY priv priv
COPY assets assets

# Install Node.js dependencies for esbuild and tailwind (if package.json exists)
RUN if [ -f assets/package.json ]; then \
        cd assets && npm install; \
    else \
        echo "No package.json found in assets, skipping npm install"; \
    fi

# Build assets using Mix tasks
RUN mix assets.deploy

# Compile the release
COPY lib lib
RUN mix do compile, release

# Start a new build stage
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs libstdc++

WORKDIR /app

# Copy the release from the builder stage
COPY --from=builder /app/_build/dev/rel/soup_and_nutz ./

# Set run ENV
ENV PHX_HOST=localhost
ENV PORT=4000

# Run the Phoenix app
CMD ["bin/soup_and_nutz", "start"] 