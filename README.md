# MyBox 现代化多协议代理 & Cloudflare 智能优选节点系统

<p align="center">
  <b>一键生成 · 纯净独立 · 现代化协议 · 双内核驱动 · 智能 DNS 自动优选</b>
</p>

---

## 🌟 核心特性

- ⚡ **前端零依赖纯静态**：单页面设计，可在 Cloudflare Pages / GitHub Pages 秒级免费部署上线。
- 🎯 **智能多线路测速弹窗**：内置浏览器端 HTTP/RTT 延迟探测器，可实时查看全网、电信、联通、移动优质 CDN 节点延迟并一键选用。
- 🔄 **全自动优选 DNS 调度**：配备 GitHub Actions 定时测速工作流，每 6 小时自动测速并通过 Cloudflare API 刷新 `best.66688800.xyz` 的双 A 记录，客户端**终身免改节点配置**。
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
├── DEPLOY.md                   # Cloudflare Pages 部署与 GitHub Actions 密钥配置指南
├── README.md                   # 项目综合介绍
├── scripts/
│   └── update_cf_dns.py        # 自动化多线程 IP 测速与 Cloudflare DNS API 交互脚本
└── .github/
    └── workflows/
        └── speedtest-dns.yml   # GitHub Actions 每 6 小时定时调度工作流
```

---

## 🚀 极速上手

### 1. 部署网页与自动化系统
请参考详细图文指南：**[DEPLOY.md](./DEPLOY.md)**
* 在 Cloudflare Pages 上线你的生成器前端；
* 在 GitHub Secrets 中填入 `CF_ZONE_ID` 与 `CF_API_TOKEN`，开启自动 DNS 优选。

### 2. 服务器一键安装命令格式
在服务器终端中执行：

```bash
# 示例：启用 Reality Vision 与 Hysteria2，使用默认优选域名
vlpt="" hypt="" bash <(curl -Ls https://raw.githubusercontent.com/Carton-qin/mybox/main/install.sh)
```

### 3. 服务器快捷运维命令
安装完成后，在服务器终端随时可输入：
* `list`：查看当前节点连接链接与二维码
* `del`：彻底卸载并清理 MyBox 核心及配置文件
* `res`：重启 Xray / Sing-box / Argo 核心守护服务
* `upx`：升级 Xray 内核至最新官方版本
* `ups`：升级 Sing-box 内核至最新官方版本

---

## 🤝 鸣谢与声明
本项目仅供个人网络技术研究与合法管理自有服务器使用。
感谢开源生态中的 [Xray-core](https://github.com/XTLS/Xray-core)、[Sing-box](https://github.com/SagerNet/sing-box) 与 [Cloudflared](https://github.com/cloudflare/cloudflared) 团队。
