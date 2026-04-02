# 使用最新的 Debian 稳定版瘦身镜像
FROM debian:bookworm-slim

# 设置环境变量以避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要的基础依赖并配置 Node.js 20.x 源
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    # 清理缓存以减小镜像体积
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 验证安装
RUN node -v && npm -v

CMD ["node"]
