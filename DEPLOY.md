# MyBox 独立自建部署与配置全流程指引

如果你想**完全独立拥有属于自己的网络节点系统**，使用你自己的域名（而不是 `66688800.xyz`），请按照以下四步完成自建。

---

### 第一步：Fork 仓库并替换为你自己的域名

1. 在 GitHub 上 Fork 本项目（[Carton-qin/mybox](https://github.com/Carton-qin/mybox)）到你自己的账号；
2. 将代码克隆到本地，或直接在 GitHub 网页上修改以下几处配置：
   * **`index.html`**：
     * 将网页标题和默认优选域名 `best.66688800.xyz` 改为你的域名（如 `best.yourdomain.com`）；
     * 将 `Carton-qin` 改为你自己的 GitHub 用户名；
   * **`.github/workflows/speedtest-dns.yml`**：
     * 将 `CF_SUBDOMAIN: "best.66688800.xyz"` 中的域名改为你的子域名（如 `best.yourdomain.com`）；
   * **`scripts/update_cf_dns.py`**：
     * 将 `RECORD_NAME = "best.66688800.xyz"` 改为你自己的子域名；
3. 将修改后的代码提交并推送到你的 GitHub 仓库。

---

### 第二步：使用 Cloudflare Pages 上线你的生成器网站（完全免费）

1. 登录 [Cloudflare 控制台](https://dash.cloudflare.com/)；
2. 在左侧菜单栏点击 **Workers 和 Pages (Workers & Pages)** $\rightarrow$ **创建应用程序** $\rightarrow$ 选择 **Pages** $\rightarrow$ **连接到 Git**；
3. 授权并选择你 Fork 的 **`mybox`** 仓库，点击“开始设置”；
4. **构建设置**全部保持默认：
   * **框架预设**：`无 (None)`
   * **构建命令**：`留空`
   * **构建输出目录**：`留空或 .`
5. 点击 **保存并部署**，约 10 秒后即可生成一个公开可访问的网站（如 `https://mybox-xxx.pages.dev`）；
6. *(推荐)* 在 Pages 项目管理页面的 **自定义域** 中，绑定你自己的子域名（例如 `box.yourdomain.com`）。

---

### 第三步：配置 GitHub Secrets，激活自动测速更新 DNS

为了让你的 GitHub Actions 每 6 小时自动把测速出来的最优双 IP 刷入你自己的域名（如 `best.yourdomain.com`），需要配置两个密钥：

#### 1. 获取 `CF_ZONE_ID`（区域 ID）
1. 在 Cloudflare 控制台主页，点击你自己的根域名（如 `yourdomain.com`）；
2. 在域名的 **概述 (Overview)** 页面，往下拉到右下角，找到 **API** 栏；
3. 复制 **区域 ID (Zone ID)**。

#### 2. 创建 `CF_API_TOKEN`（API 令牌）
1. 点击 Cloudflare 控制台右上角头像 $\rightarrow$ **我的个人资料 (My Profile)** $\rightarrow$ **API 令牌 (API Tokens)**；
2. 点击 **创建令牌 (Create Token)**；
3. 找到 **编辑区域 DNS (Edit zone DNS)** 模板，点击“使用模板”；
4. 在 **区域资源 (Zone Resources)** 处：
   * 选择 **包括 (Include)** $\rightarrow$ **特定区域 (Specific zone)** $\rightarrow$ 下拉选择你自己的域名；
5. 点击页面最下方的 **继续以显示摘要** $\rightarrow$ **创建令牌**；
6. 复制生成的这一长串 API Token（只显示一次，务必妥善保存）。

#### 3. 将密钥写入你自己的 GitHub 仓库
1. 打开你 Fork 的 GitHub 仓库页面；
2. 点击 **Settings** $\rightarrow$ 左侧 **Secrets and variables** $\rightarrow$ **Actions**；
3. 点击 **New repository secret** 分别添加以下两个变量：
   * **名称**：`CF_ZONE_ID`，**Secret**：填入刚才复制的区域 ID；
   * **名称**：`CF_API_TOKEN`，**Secret**：填入刚才复制的 API 令牌。

#### 4. 立即手动运行测试一次
1. 在 GitHub 仓库上方点击 **Actions** 标签页；
2. 在左侧列表点击 **Cloudflare DNS 智能测速与自动更新**；
3. 点击右侧的 **Run workflow** $\rightarrow$ 点击绿色按钮确认执行；
4. 约 1~2 分钟后查看日志，若显示成功同步，登录 Cloudflare DNS 即可看到已自动生成了两条灰云（仅 DNS）的 A 记录！

---

### 第四步：日常使用

1. 打开你自建的生成器网页（如 `https://box.yourdomain.com`），勾选协议并设置端口；
2. 复制命令在 Linux 服务器（VPS）终端回车执行；
3. 部署完成后，在客户端（v2rayN / Clash / Sing-box 等）中：
   * 节点的 **服务器地址 (Address)** 永久保持为你自己的优选域名；
   * 你的专属 GitHub Actions 会全天候自动将该域名指向当前网络质量最好的 Cloudflare IP，终身免手动维护！
