# syntax=docker/dockerfile:experimental

#######################################
# 1) Stage “downloader”: fetch binary #
#######################################
FROM alpine:latest AS downloader

ARG SPOOF_VER=0.12.0
ARG TARGETOS
ARG TARGETARCH

# Install dependencies
RUN apk add --no-cache ca-certificates wget tar

# Download and extract binary
RUN set -eux && \
    case "${TARGETARCH}" in \
      amd64)   ARCH=amd64 ;; \
      arm64)   ARCH=arm64 ;; \
      arm)     ARCH=arm ;; \
      *)       echo "Unsupported arch ${TARGETARCH}" && exit 1 ;; \
    esac && \
    URL="https://github.com/xvzc/SpoofDPI/releases/download/v${SPOOF_VER}/spoofdpi-linux-${ARCH}.tar.gz" && \
    wget -qO /tmp/spoofdpi.tar.gz "${URL}" && \
    mkdir -p /out && \
    tar -xzf /tmp/spoofdpi.tar.gz -C /out && \
    rm -f /tmp/spoofdpi.tar.gz && \
    chmod +x /out/spoofdpi && \
    apk del ca-certificates wget tar && \
    rm -rf /var/cache/apk/*

###################################
# 2) Final image: minimal runtime #
###################################
FROM cgr.dev/chainguard/wolfi-base

# Copy binary
COPY --from=downloader /out/spoofdpi /usr/bin/spoofdpi

# Drop privileges
USER nonroot

ENTRYPOINT ["/usr/bin/spoofdpi"]
CMD ["-h"]
