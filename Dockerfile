# --- Stage 1: Build Go binary ---
# This Dockerfile is for local builds where web UI is pre-built.
# Run `make build-web` or `pnpm build` in web/ before using this Dockerfile.
FROM golang:1.25-alpine AS go-builder
RUN apk add --no-cache git
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG VERSION=dev
ARG COMMIT=unknown
RUN CGO_ENABLED=0 go build \
    -ldflags "-s -w -X main.version=${VERSION} -X main.commit=${COMMIT}" \
    -o /fastclaw ./cmd/fastclaw

# --- Stage 2: Runtime ---
FROM alpine:3.21
RUN apk add --no-cache ca-certificates tzdata docker-cli
COPY --from=go-builder /fastclaw /usr/local/bin/fastclaw

# Default data directory. Override at runtime with FASTCLAW_HOME, but the
# default value here lets `docker run fastclaw/fastclaw` work with no env.
# FASTCLAW_BIND=all is required for Docker port mapping to work (binds to
# 0.0.0.0 instead of loopback).
ENV FASTCLAW_HOME=/data/.fastclaw \
    HOME=/data \
    FASTCLAW_BIND=all
RUN mkdir -p /data/.fastclaw /data/.fastclaw/skills
VOLUME /data/.fastclaw

# Bundle built-in skills
COPY skills/ /data/.fastclaw/skills/

EXPOSE 18953
ENTRYPOINT ["fastclaw"]
CMD ["gateway"]
