#!/bin/bash

# --- 1. 设置 Root 密码 ---
if [ -z "$PASSWORD" ]; then
    echo "root:root" | chpasswd
    echo "Warning: No PASSWORD environment variable found, using default: root"
else
    echo "root:$PASSWORD" | chpasswd
    echo "Success: Root password updated."
fi

# --- 2. 启动核心服务 ---
# 启动 SSH 服务
/usr/sbin/sshd

mkdir -p /root/auto
touch /root/auto/cron && touch /root/auto/systemd

# --- 3. 处理定时任务 (加载 /root/auto/cron) ---
if [ -f "/root/auto/cron" ]; then
    echo "Checking /root/auto/cron..."
    # 移除 Windows 换行符
    sed -i 's/\r$//' /root/auto/cron
    chmod 600 /root/auto/cron
    crontab /root/auto/cron
    echo "Cron tasks loaded."
else
    echo "Notice: /root/auto/cron not found, skipping."
fi
# 启动定时任务守护进程
service cron start

# --- 4. 启动后台常驻任务 (加载 /root/auto/systemd) ---
if [ -f "/root/auto/systemd" ]; then
    echo "Reading /root/auto/systemd list..."
    while IFS= read -r line || [[ -n "$line" ]]; do
        # 移除回车符，并过滤注释(#)和空行
        line=$(echo "$line" | sed 's/\r$//')
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        
        echo "Launching in background: $line"
        eval "$line" &
    done < "/root/auto/systemd"
else
    echo "Notice: /root/auto/systemd not found, skipping."
fi

# --- 5. 保持容器前台运行 ---
echo "Debian 12 environment is ready."
# 打印已加载的定时任务供检查
crontab -l 2>/dev/null || echo "No active cron jobs."

# 阻塞主进程
tail -f /dev/null
