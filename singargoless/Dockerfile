# ---------- 第一阶段：下载 ----------
FROM alpine:3.20 AS builder

RUN apk add --no-cache curl tar jq

ARG TARGETARCH
# 接收来自 Actions 的版本号变量，用于强制打破 Docker 缓存
ARG SB_VER_TAG
ARG CF_VER_TAG

# 下载 sing-box
RUN set -eux; \
    SB_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r '.tag_name' | sed 's/^v//'); \
    case "$TARGETARCH" in \
      amd64) SB_ARCH=amd64 ;; \
      arm64) SB_ARCH=arm64 ;; \
      *) echo "unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac; \
    curl -Lo /tmp/sing-box.tar.gz \
      https://github.com/SagerNet/sing-box/releases/download/v${SB_VERSION}/sing-box-${SB_VERSION}-linux-${SB_ARCH}.tar.gz; \
    tar -xzf /tmp/sing-box.tar.gz -C /tmp; \
    mv /tmp/sing-box-*/sing-box /usr/local/bin/sing-box; \
    chmod +x /usr/local/bin/sing-box

# 下载 cloudflared
RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) CF_ARCH=amd64 ;; \
      arm64) CF_ARCH=arm64 ;; \
      *) echo "unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac; \
    # 只要 CF_VER_TAG 变了，这一层就会重新下载
    curl -Lo /usr/local/bin/cloudflared \
      https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}; \
    chmod +x /usr/local/bin/cloudflared

# ---------- 第二阶段：运行 ----------
FROM alpine:3.20

RUN apk add --no-cache bash ca-certificates curl

RUN mkdir -p /etc/sing-box
COPY --from=builder /usr/local/bin/sing-box /usr/local/bin/
COPY --from=builder /usr/local/bin/cloudflared /usr/local/bin/
COPY singargoless/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# 设置 Go 内存限制的环境变量，辅助降低内存占用
ENV PORT=8080 \
    UUID="" \
    DOMAIN="" \
    TOKEN="" \
    GOGC=50

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
