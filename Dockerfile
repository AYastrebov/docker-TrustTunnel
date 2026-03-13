FROM ghcr.io/linuxserver/baseimage-alpine:3.21

ARG BUILD_DATE
ARG VERSION
ARG TRUSTTUNNEL_VERSION
LABEL build_version="docker-TrustTunnel version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="ayastrebov"

ARG TARGETARCH

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    ca-certificates \
    curl \
    iproute2 \
    iptables \
    ip6tables \
    iputils \
    jq \
    net-tools && \
  echo "**** download TrustTunnel endpoint ****" && \
  if [ -z "${TRUSTTUNNEL_VERSION}" ]; then \
    TRUSTTUNNEL_VERSION=$(curl -s https://api.github.com/repos/TrustTunnel/TrustTunnel/releases/latest | jq -r '.tag_name' | sed 's/^v//'); \
  fi && \
  case "${TARGETARCH}" in \
    amd64) TT_ARCH="x86_64" ;; \
    arm64) TT_ARCH="aarch64" ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
  esac && \
  echo "Downloading TrustTunnel endpoint v${TRUSTTUNNEL_VERSION} for ${TT_ARCH}" && \
  curl -fsSL "https://github.com/TrustTunnel/TrustTunnel/releases/download/v${TRUSTTUNNEL_VERSION}/trusttunnel-v${TRUSTTUNNEL_VERSION}-linux-${TT_ARCH}.tar.gz" \
    -o /tmp/trusttunnel-endpoint.tar.gz && \
  tar -xzf /tmp/trusttunnel-endpoint.tar.gz -C /tmp/ && \
  install -m 755 /tmp/trusttunnel-v${TRUSTTUNNEL_VERSION}-linux-${TT_ARCH}/trusttunnel_endpoint /usr/local/bin/trusttunnel_endpoint && \
  install -m 755 /tmp/trusttunnel-v${TRUSTTUNNEL_VERSION}-linux-${TT_ARCH}/setup_wizard /usr/local/bin/trusttunnel_setup_wizard && \
  echo "**** download TrustTunnel client ****" && \
  TTCLIENT_VERSION=$(curl -s https://api.github.com/repos/TrustTunnel/TrustTunnelClient/releases/latest | jq -r '.tag_name' | sed 's/^v//') && \
  echo "Downloading TrustTunnel client v${TTCLIENT_VERSION} for ${TT_ARCH}" && \
  curl -fsSL "https://github.com/TrustTunnel/TrustTunnelClient/releases/download/v${TTCLIENT_VERSION}/trusttunnel_client-v${TTCLIENT_VERSION}-linux-${TT_ARCH}.tar.gz" \
    -o /tmp/trusttunnel-client.tar.gz && \
  tar -xzf /tmp/trusttunnel-client.tar.gz -C /tmp/ && \
  install -m 755 /tmp/trusttunnel_client-v${TTCLIENT_VERSION}-linux-${TT_ARCH}/trusttunnel_client /usr/local/bin/trusttunnel_client && \
  install -m 755 /tmp/trusttunnel_client-v${TTCLIENT_VERSION}-linux-${TT_ARCH}/setup_wizard /usr/local/bin/trusttunnel_client_setup_wizard && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/*

COPY root/ /

EXPOSE 443/tcp 443/udp 80/tcp

VOLUME /config
