# FileServer

一个基于 Go 的轻量文件服务容器，自动从 GitHub 仓库或 URL 同步文件，并通过浏览器友好的界面提供浏览与预览，同时支持 `wget`/`curl` 直接下载。

---

## 特性

- **双模式响应**：同一 URL，浏览器访问返回 HTML 预览页，`wget`/`curl` 访问返回原始文件内容
- **文件预览**：文本文件语法高亮（行号）、图片内联预览、500KB 以上提示下载
- **多仓库同步**：支持同时同步多个 GitHub 仓库，单仓库放根目录，多仓库自动建子目录
- **定时同步**：支持 `TIME`（本地时间）或 `CRON` 表达式，时区统一按 `TZ` 解释
- **同步状态显示**：同步进行中网页显示等待界面，完成后自动刷新
- **Cloudflare Argo 隧道**：可选，内置 `cloudflared`，无需公网 IP 即可暴露服务
- **单二进制**：Go 编译产物 + 嵌入模板，运行时仅需 Alpine 基础镜像

---

## 快速开始

```bash
docker run -d \
  -p 8080:8080 \
  -e REPOSITORIES=" github用户名/仓库名/分支1 github用户名/仓库名/分支2" \
  -v /host/data:/data \
  --name fileserver \
  evecus/fileserver:latest
```

访问 `http://localhost:8080` 即可查看文件列表。

---

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TZ` | `Asia/Shanghai` | 时区，影响容器系统时间、`TIME` 和 `CRON` 的解释 |
| `REPOSITORIES` | 空 | 要同步的 GitHub 仓库，空格分隔，格式见下方 |
| `URLS` | 空 | 要下载的文件直链，空格分隔 |
| `PATH_NAME` | 空 | `URLS` 下载到的子目录，不填放根目录 |
| `TIME` | `12:00` | 定时同步时间，按 `TZ` 时区解释，格式 `HH:MM` |
| `CRON` | 空 | 5 段 cron 表达式，按 `TZ` 时区解释，优先级高于 `TIME` |
| `CF` | 空 | 设为 `true` 时启动 Cloudflare Argo 隧道 |
| `TOKEN` | 空 | Cloudflare Tunnel token |

> 所有变量均可不填，容器会以默认值正常启动，显示空文件列表。

---

## REPOSITORIES 格式

```
用户名/仓库名
用户名/仓库名/分支
```

多个仓库用空格分隔：

```bash
# 单仓库，分支默认 main，文件放根目录
-e REPOSITORIES="evecus/rules_set"

# 单仓库，指定分支
-e REPOSITORIES="evecus/rules_set/dev"

# 多仓库，每个仓库放到 仓库名/分支/ 子目录
-e REPOSITORIES="evecus/rules_set evecus/tv/main user2/repo/dev"
```

**目录结构示例（多仓库）：**

```
/data/files/
├── rules_set/
│   └── main/
│       ├── mihomo/
│       └── sing-box/
└── tv/
    └── main/
        └── tv.json
```

---

## 同步逻辑

| 情况 | 行为 |
|------|------|
| 首次启动 | 强制同步 |
| 重启，`REPOSITORIES`/`URLS`/`PATH_NAME` 未变 | 跳过同步 |
| 重启，以上任一变量有变化 | 触发同步 |
| 修改 `TIME`/`CRON`/`TZ`/`CF`/`TOKEN` 后重启 | 跳过同步（不参与 hash） |
| 到达 cron 设定时间 | 无条件全量同步 |

手动触发同步：

```bash
docker exec <容器名> /bin/sh /sync.sh
```

---

## 数据目录

挂载 `-v /host/data:/data` 后目录结构：

```
/data/
├── files/          # 同步的文件，对外提供服务
├── .env_hash       # 环境变量指纹，用于判断是否需要重新同步
├── .env_cache      # 运行时参数缓存，供 cron 任务读取
├── .syncing        # 同步进行中时存在，完成后删除
├── .last_update    # 最后同步完成时间
├── sync.log        # cron 定时同步日志
└── cloudflared.log # Cloudflare 隧道日志（启用时）
```

> 不挂载 `-v` 也可运行，但容器重启后同步的文件会丢失。

---

## 进程结构

```
PID 1  fileserver     ← 主进程，Go HTTP 服务，容器存活锚点
PID x  crond          ← 后台，定时触发同步
PID y  cloudflared    ← 后台，可选
```

---

## 构建镜像

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t evecus/fileserver:argo \
  --push .
```

---

## API 接口

| 路径 | 说明 |
|------|------|
| `/<path>` | 浏览器：HTML 预览页；`wget`/`curl`：原始文件 |
| `/__raw__/<path>` | 强制返回原始文件内容（浏览器点 Raw 按钮使用） |
| `/__last_update__` | 返回最后同步时间文本 |
| `/__syncing__` | 同步中返回 `1`，否则返回 `0` |
