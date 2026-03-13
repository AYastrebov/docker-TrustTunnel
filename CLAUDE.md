# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Docker container for [TrustTunnel](https://github.com/TrustTunnel/TrustTunnel) VPN — a censorship-resistant VPN from AdGuard that tunnels over HTTPS (HTTP/1.1, HTTP/2, QUIC). Built on LinuxServer.io Alpine base image with s6-overlay.

Single image supports both **server** (endpoint) and **client** modes, selected via environment variables.

## Build & Test Commands

```bash
# Local build (current arch only)
docker build -t docker-trusttunnel .

# Multi-arch build (requires buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t docker-trusttunnel .

# Build with pinned TrustTunnel version
docker build --build-arg TRUSTTUNNEL_VERSION=1.0.17 -t docker-trusttunnel .

# Run server mode
docker compose -f docker-compose.server.yml up

# Run client mode
docker compose -f docker-compose.client.yml up

# Shell into running container for debugging
docker exec -it trusttunnel-server bash
```

No test suite — validation is done by building the image and running it.

## Architecture

### LinuxServer.io Pattern

Base image `ghcr.io/linuxserver/baseimage-alpine:3.21` provides s6-overlay init system, `abc` user (PUID/PGID), `/config` volume convention, and `lsiown`/`with-contenv` utilities. The `ENTRYPOINT ["/init"]` is inherited from base — we don't set CMD.

### Dockerfile

Downloads **pre-built static binaries** from two upstream repos at build time:
- **Endpoint** (server): from `TrustTunnel/TrustTunnel` releases → `trusttunnel_endpoint`, `trusttunnel_setup_wizard`
- **Client**: from `TrustTunnel/TrustTunnelClient` releases → `trusttunnel_client`, `trusttunnel_client_setup_wizard`

Binaries are statically linked (Rust), so Alpine/musl works fine. Architecture mapped via `TARGETARCH`: `amd64`→`x86_64`, `arm64`→`aarch64`.

### s6-overlay Service Chain

```
init-config (base) → init-trusttunnel-config (oneshot) → init-config-end (base) → init-services (base) → svc-trusttunnel (longrun)
```

- **`init-trusttunnel-config/run`**: Detects mode (auto/server/client), generates TOML configs for server or validates client config exists. Writes `TT_RESOLVED_MODE` to s6 container environment.
- **`svc-trusttunnel/run`**: Reads `TT_RESOLVED_MODE` and `exec`s either `trusttunnel_endpoint` or `trusttunnel_client`.

Dependencies are expressed via empty files in `dependencies.d/` directories. Services are registered in `user/contents.d/`.

### Mode Detection

`TT_MODE` env var (`auto`|`server`|`client`). In `auto` mode: `TT_HOSTNAME` set → server; `/config/client/trusttunnel_client.toml` exists → client.

### Server Config Generation

Generates three TOML files in `/config/server/`: `vpn.toml`, `hosts.toml`, `credentials.toml`. Skips generation if all three already exist (preserves manual edits). Credentials are always regenerated from `TT_CREDENTIALS` if set. The endpoint listens on port 8443 inside the container (mapped to 443 on host).

### CI/CD

`.github/workflows/build.yml` builds multi-arch images on push to `master` or tags, publishes to GHCR. Weekly scheduled run checks for new upstream TrustTunnel releases and skips if already published. Uses buildx with GHA cache.

## Conventions

- All s6 scripts use `#!/usr/bin/with-contenv bash` shebang to inherit container environment
- File ownership set with `lsiown -R abc:abc` (not `chown`)
- Persistent data goes under `/config/` volume
- Default branch is `master`
