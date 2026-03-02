#!/bin/bash

# 1. 设置默认变量
# 如果未设置 UUID 环境变量，则使用此默认值
DEFAULT_UUID="3d039e25-d253-4b05-8d9f-91badac7c3ff"
UUID=${UUID:-$DEFAULT_UUID}

LISTEN_PORT=${PORT:-8001} 
WS_PATH="/YDT4hf6qaozmd46fijeiwnjwjen39" 

echo "使用 UUID: ${UUID}"

# 2. 生成 sing-box 配置文件 
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

# 3. 启动 sing-box
echo "启动 Sing-box..."
sing-box run -c /etc/sing-box.json > /dev/null 2>&1 &

# 4. 自动生成临时 Cloudflare 隧道 (获取域名)
echo "正在创建 Cloudflare 临时隧道..."

# 将日志重定向到一个临时文件以获取生成的域名
LOG_FILE="/tmp/cloudflared.log"
cloudflared tunnel --no-autoupdate --url http://localhost:${LISTEN_PORT} > ${LOG_FILE} 2>&1 &

# 等待几秒钟让 cloudflared 生成域名
sleep 10

# 从日志文件中提取域名
DOMAIN=$(grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com" ${LOG_FILE} | head -n 1 | sed 's#https://##')

if [ -z "$DOMAIN" ]; then
    echo "❌ 无法获取临时域名，请检查 cloudflared 是否正常运行。"
    exit 1
fi

echo "✅ 临时域名已生成: ${DOMAIN}"

# 5. 生成 VLESS 节点链接 
VLESS_LINK="vless://${UUID}@${DOMAIN}:443?encryption=none&security=tls&sni=${DOMAIN}&type=ws&host=${DOMAIN}&path=${WS_PATH}#Argo-Temp-${DOMAIN}"

# 6. 输出结果
echo "---------------------------------------------------" 
echo "✅ 临时服务已启动！" 
echo "---------------------------------------------------" 
echo "VLESS 节点链接:" 
echo "${VLESS_LINK}" 
echo "---------------------------------------------------" 
echo "⚠️ 注意: 重启服务器后域名会改变。"

# 保持脚本运行
wait
