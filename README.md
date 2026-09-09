# MyBox 现代化多协议代理 & Cloudflare 智能优选节点系统

<p align="center">
  <b>一键生成 · 纯净独立 · 现代化协议 · 双内核驱动 · 智能 DNS 自动优选</b>
</p>

<p align="center">
  🌐 <b>官方在线生成器直达</b>：<a href="https://box.66688800.xyz" target="_blank"><b>https://box.66688800.xyz</b></a>
</p>

---

## 📖 使用方式指引（两种途径）

本项目为不同需求的用户提供了两种使用方式：
1. **[方式一：直接使用（推荐 · 小白零门槛，免搭建）](#-方式一直接使用推荐--小白零门槛免搭建)**：直接访问作者搭建好的在线网页，使用预置的自动优选通道，30秒完成节点部署；
2. **[方式二：完全自建部署（进阶 · 拥有专属域名与独立品牌）](#-方式二完全自建部署进阶--拥有专属域名与独立品牌)**：Fork 本仓库，配置属于你自己的域名、前端网站与独立测速工作流。

---

## 🚀 方式一：直接使用（推荐 · 小白零门槛，免搭建）

如果你不想繁琐地购买域名、配置 Cloudflare API，你可以**直接使用作者已经部署好的完整服务**。

### 1. 访问在线命令生成器
👉 **点击直达：[https://box.66688800.xyz](https://box.66688800.xyz)**

* 网页界面开箱即用，已默认集成作者全天候维护的 **`best.66688800.xyz`** 优选解析通道；
* **客户端终身免改配置**：后台 GitHub Actions 每 6 小时自动测速，并将全网延迟最低的双 Anycast IP 自动刷入该域名；
* 支持点击 **`[⚡ 智能测速优选]`** 按钮，在你的浏览器端实时探测电信、联通、移动、全网延迟排行榜，并支持一键选定。

### 2. 服务器一键安装
在在线生成器网页勾选所需协议后，复制命令，在 Linux 服务器（VPS）终端回车执行即可：

```bash
# 示例：启用 Reality Vision 与 Hysteria2（默认接入 best.66688800.xyz 自动优选通道）
vlpt="" hypt="" bash <(curl -Ls https://raw.githubusercontent.com/Carton-qin/mybox/main/install.sh)
```

### 3. 服务器快捷运维命令
安装完成后，在服务器随时输入以下命令即可维护：
* `list`：查看当前已配置节点的分享链接与配置参数
* `res`：重启 Xray / Sing-box / Argo 核心守护服务
* `del`：彻底卸载并清理 MyBox 核心及配置文件
* `upx`：一键升级 Xray-core 内核至最新官方版本
* `ups`：一键升级 Sing-box 内核至最新官方版本

---

## 🛠️ 方式二：完全自建部署（进阶 · 拥有专属域名与独立品牌）

如果你拥有自己的域名（如 `.com` / `.xyz`），希望**完全独立运行、不想依赖 `66688800.xyz`**，可以自行搭建整套系统：

### 1. Fork 本仓库
点击右上角 **Fork**，将 `Carton-qin/mybox` 复制到你自己的 GitHub 账号下。

### 2. 全局替换为你的个人信息
在你的仓库中，将以下内容替换为你自己的配置：
* 将 `66688800.xyz` 替换为你自己的域名（如 `yourdomain.com`）；
* 将 `Carton-qin` 替换为你自己的 GitHub 用户名；
* `index.html` 中的默认优选域名 `best.66688800.xyz` 改为 `best.yourdomain.com`。

### 3. 使用 Cloudflare Pages 上线前端
* 在 Cloudflare 控制台连接你 Fork 的 GitHub 仓库，即可免费生成专属网站；
* 可自定义绑定类似 `box.yourdomain.com` 的二级域名。

### 4. 激活专属自动测速 DNS 工作流
* 在 GitHub 仓库的 `Settings -> Secrets and variables -> Actions` 中填入你的 Cloudflare 密钥：
  * `CF_ZONE_ID`：你的域名在 Cloudflare 的区域 ID；
  * `CF_API_TOKEN`：具有 DNS 编辑权限的 API 令牌。
* 激活后，GitHub Actions 每 6 小时会自动为你的 `best.yourdomain.com` 刷新最优 IP！

👉 **完整的图文级自建步骤请阅读：[DEPLOY.md（自建部署指引）](./DEPLOY.md)**

---

## 🌟 项目核心特性

- ⚡ **零服务器成本**：前端生成器运行在 Cloudflare Pages，自动化测速运行在 GitHub Actions，纯云端托管。
- 🎯 **智能多线路测速弹窗**：内置浏览器端 HTTP/RTT 延迟探测器，可实时查看全网、电信、联通、移动优质 CDN 节点延迟。
- 🔄 **全自动优选 DNS 调度**：配备 GitHub Actions 定时测速工作流，每 6 小时自动测速并通过 Cloudflare API 刷新 A 记录，客户端**终身免改节点配置**。
- 🛡️ **黄金现代化协议栈**：
  - **抗封锁直连**：`Vless-tcp-reality-vision`、`Vless-xhttp-reality-enc`（抗量子加密）
  - **高速 QUIC/UDP 突破网络拥塞**：`Hysteria2`（端口跳跃）、`Tuic`
  - **穿透与救砖主力**：`Vless-ws-enc` / `Vless-xhttp-enc` + Cloudflare Argo 临时/固定隧道
- 🧼 **纯净去中心化**：淘汰陈旧的 Socks5 / Vmess / Shadowsocks-2022 / NaiveProxy 臃肿协议，彻底移除第三方引流外链，基于官方 release 内核运行。

---

## 📁 目录结构

```
my-box/
├── index.html                  # MyBox 前端命令生成器（内置智能测速弹窗）
├── install.sh                  # 独立自建的服务器一键安装与运维脚本
├── DEPLOY.md                   # 独立自建部署与配置全流程指引
├── README.md                   # 项目使用与架构说明
├── scripts/
│   └── update_cf_dns.py        # 自动化多线程 IP 测速与 Cloudflare DNS API 交互脚本
└── .github/
    └── workflows/
        └── speedtest-dns.yml   # GitHub Actions 每 6 小时定时调度工作流
```

---

## 🤝 鸣谢与声明
本项目仅供个人网络技术研究与合法管理自有服务器使用。
感谢开源生态中的 [Xray-core](https://github.com/XTLS/Xray-core)、[Sing-box](https://github.com/SagerNet/sing-box) 与 [Cloudflared](https://github.com/cloudflare/cloudflared) 团队。
