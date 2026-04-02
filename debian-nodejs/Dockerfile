# 使用最新的 Debian 稳定版瘦身镜像
FROM debian:bookworm-slim

# 设置环境变量以避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要的基础依赖并配置 Node.js 20.x 源
RUN apt-get update && apt-get install -y \
    tzdata \
    libssl3 \
    openssl \
    iproute2 \
    openssh-server \
    cron \
    wget \
    gnupg \
    curl \
    nano \
    vim \
    iputils-ping \
    net-tools \
    procps \
    ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && mkdir /var/run/sshd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 配置 SSH：允许 root 登录和密码认证
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 将启动脚本复制到根目录
COPY debian-nodejs/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露端口与定义持久化目录
EXPOSE 22
VOLUME ["/root", "/opt", "/usr/local/bin"]

ENTRYPOINT ["/entrypoint.sh"]
