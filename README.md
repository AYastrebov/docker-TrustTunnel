# docker-TrustTunnel

Docker container for [TrustTunnel](https://github.com/TrustTunnel/TrustTunnel) VPN — a censorship-resistant VPN protocol from AdGuard that disguises traffic as regular HTTPS.

Built on [LinuxServer.io](https://www.linuxserver.io/) base image with s6-overlay service management.

## Features

- **Server & Client** in a single container (mode selected via environment variables)
- **Multi-arch**: `linux/amd64` and `linux/arm64`
- **s6-overlay** process supervision with proper init/shutdown
- **Auto-config generation** for server mode
- **TLS options**: self-signed, Let's Encrypt, or bring-your-own certificates
- **HTTP/1.1 + HTTP/2 + QUIC** protocol support (server)

## Quick Start

### Server

```bash
docker run -d \
  --name trusttunnel-server \
  --cap-add NET_ADMIN \
  -e TT_HOSTNAME=vpn.example.com \
  -e TT_CREDENTIALS=myuser:mypassword \
  -e TT_CERT_TYPE=self-signed \
  -p 443:8443/tcp \
  -p 443:8443/udp \
  -v trusttunnel-config:/config \
  ghcr.io/ayastrebov/docker-trusttunnel:latest
```

### Client

```bash
docker run -d \
  --name trusttunnel-client \
  --cap-add NET_ADMIN \
  --device /dev/net/tun \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  -e TT_MODE=client \
  -v ./trusttunnel_client.toml:/config/client/trusttunnel_client.toml:ro \
  -v trusttunnel-client:/config \
  ghcr.io/ayastrebov/docker-trusttunnel:latest
```

### Docker Compose

See [`docker-compose.server.yml`](docker-compose.server.yml) and [`docker-compose.client.yml`](docker-compose.client.yml).

## Environment Variables

### General

| Variable | Default | Description |
|---|---|---|
| `PUID` | `911` | User ID for file ownership |
| `PGID` | `911` | Group ID for file ownership |
| `TZ` | `Etc/UTC` | Timezone |
| `TT_MODE` | `auto` | Force mode: `server`, `client`, or `auto` (detect from env vars) |

### Server Mode

| Variable | Required | Default | Description |
|---|---|---|---|
| `TT_HOSTNAME` | Yes | — | Server hostname (e.g. `vpn.example.com`) |
| `TT_CREDENTIALS` | Yes | — | Credentials as `user:pass` or `user1:pass1,user2:pass2` |
| `TT_LISTEN_ADDRESS` | No | `0.0.0.0:8443` | Endpoint listen address |
| `TT_CERT_TYPE` | No | `self-signed` | Certificate type: `self-signed`, `letsencrypt`, `provided` |
| `TT_ACME_EMAIL` | For LE | — | Email for Let's Encrypt |
| `TT_ACME_STAGING` | No | `false` | Use Let's Encrypt staging |
| `TT_CERT_CHAIN_PATH` | For provided | `/config/server/certs/fullchain.pem` | Path to cert chain |
| `TT_CERT_KEY_PATH` | For provided | `/config/server/certs/privkey.pem` | Path to private key |

### Client Mode

| Variable | Required | Default | Description |
|---|---|---|---|
| `TT_CLIENT_CONFIG` | No | — | Raw TOML client config content |
| `TT_DEEPLINK` | No | — | TrustTunnel deep-link URI (`tt://...`) |

Or mount your config file at `/config/client/trusttunnel_client.toml`.

## Volumes

| Path | Description |
|---|---|
| `/config` | Persistent configuration and certificates |
| `/config/server/` | Server configs (`vpn.toml`, `hosts.toml`, `credentials.toml`) |
| `/config/client/` | Client config (`trusttunnel_client.toml`) |

## Ports

| Port | Protocol | Description |
|---|---|---|
| `8443` | TCP + UDP | TrustTunnel endpoint (map to 443 on host) |
| `80` | TCP | Let's Encrypt HTTP-01 challenge |

## Building Locally

```bash
docker build -t docker-trusttunnel .
```

## License

Apache 2.0
