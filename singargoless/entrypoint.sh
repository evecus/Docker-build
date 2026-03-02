#!/bin/bash

# 1. 检查环境变量 
if [ -z "$UUID" ] || [ -z "$DOMAIN" ] || [ -z "$TOKEN" ]; then
    echo "错误: 请确保设置了 UUID, DOMAIN 和 TOKEN 环境变量。" 
    exit 1 
fi

WS_PATH="/YDT4hf6q3ndbRzwvefijeiwnjwjen39" 
LISTEN_PORT=${PORT:-8001} 

# 2. 生成 sing-box 配置文件 (VLESS + WS) 
cat <<EOF > /etc/sing-box.json
{
  "log": { "level": "warn", "timestamp": true },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": ${LISTEN_PORT},
      "users": [{ "uuid": "${UUID}" }],
      "transport": {
        "type": "ws",
        "path": "${WS_PATH}"
      }
    }
  ],
  "outbounds": [{ "type": "direct", "tag": "direct" }]
}
EOF

# 5. 生成链接
VLESS_LINK="vless://${UUID}@$www.visa.com:443?encryption=none&security=tls&sni=${DOMAIN}&type=ws&host=${DOMAIN}&path=${WS_PATH}#Argo-VLESS-${DOMAIN}"

# 6. 启动服务 (后台运行) 
echo "启动 Cloudflared 和 Sing-box..."
cloudflared tunnel --no-autoupdate run --token ${TOKEN} > /dev/null 2>&1 &
sing-box run -c /etc/sing-box.json > /dev/null 2>&1 &

# 7. 检测服务是否真正启动 (修正：检测本地端口)
echo "正在检查服务状态..." 

MAX_RETRIES=10 
COUNT=0 
while [ $COUNT -lt $MAX_RETRIES ]; do
    # 检查 sing-box 是否在监听端口
    if netstat -tuln | grep -q ":${LISTEN_PORT} "; then
        echo "---------------------------------------------------" 
        echo "✅ 服务启动成功！" 
        echo "✅ Cloudflare 隧道已连接"
        echo "---------------------------------------------------" 
        echo "VLESS 节点链接:" 
        echo "${VLESS_LINK}" 
        echo "---------------------------------------------------" 
        # 保持脚本运行，防止服务退出
        tail -f /dev/null
        exit 0 
    fi
    echo "等待服务启动... ($COUNT/$MAX_RETRIES)"
    sleep 2 
    COUNT=$((COUNT + 1)) 
done

echo "❌ 服务启动失败，请检查配置。" 
exit 1
