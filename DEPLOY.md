# MyBox 部署与配置全流程指引

本文档指导你将 `my-box` 项目快速部署上线，并配置自动化 DNS 优选同步。

---

### 第一步：将代码推送到你自己的 GitHub 仓库

1. 在 GitHub 上新建一个公开（Public）或私有（Private）仓库，名称推荐为 **`my-box`**；
2. 打开本地终端，进入当前 `my-box` 目录并推送到 GitHub：

```bash
cd my-box
git init
git add .
git commit -m "feat: init MyBox system with auto-speedtest DNS"
git branch -M main
git remote add origin https://github.com/Carton-qin/mybox.git
git push -u origin main
```

---

### 第二步：使用 Cloudflare Pages 上线生成器前端（免费、免服务器）

1. 登录 [Cloudflare 控制台](https://dash.cloudflare.com/)；
2. 点击左侧导航栏 **Workers 和 Pages** $\rightarrow$ **创建应用程序** $\rightarrow$ 选择 **Pages** $\rightarrow$ **连接到 Git**；
3. 授权并选择刚才创建的 **`my-box`** 仓库，点击“开始设置”；
4. **构建设置**保持默认：
   * **框架预设**：`无 (None)`
   * **构建命令**：`留空`
   * **构建输出目录**：`留空或 .`
5. 点击 **保存并部署**，10 秒内即可生成专属访问网址（形如 `https://my-box-xxx.pages.dev`）；
6. *(可选推荐)* 在该 Pages 项目的 **自定义域** 中，绑定你自己的子域名（例如 `box.66688800.xyz`），之后即可通过专属域名访问该生成器。

---

### 第三步：配置 GitHub Secrets 激活自动测速更新 DNS

为了让 GitHub Actions 每 6 小时自动把测速出来的最优双 IP 刷入你的 `best.66688800.xyz`，需要配置两个密钥：

#### 1. 获取 `CF_ZONE_ID`（区域 ID）
1. 在 Cloudflare 控制台主页，点击你的域名 **`66688800.xyz`**；
2. 在域名的 **概述 (Overview)** 页面，往下拉到右下角，找到 **API** 栏；
3. 复制 **区域 ID (Zone ID)**。

#### 2. 创建 `CF_API_TOKEN`（API 令牌）
1. 点击 Cloudflare 控制台右上角头像 $\rightarrow$ **我的个人资料 (My Profile)** $\rightarrow$ **API 令牌 (API Tokens)**；
2. 点击 **创建令牌 (Create Token)**；
3. 找到 **编辑区域 DNS (Edit zone DNS)** 模板，点击“使用模板”；
4. 在 **区域资源 (Zone Resources)** 处：
   * 选择 **包括 (Include)** $\rightarrow$ **特定区域 (Specific zone)** $\rightarrow$ 下拉选择你的域名 **`66688800.xyz`**；
5. 点击页面最下方的 **继续以显示摘要** $\rightarrow$ **创建令牌**；
6. 复制生成的这一长串 API Token（只显示一次，务必复制保存）。

#### 3. 将密钥写入 GitHub 仓库
1. 打开你 GitHub 上的 `my-box` 仓库；
2. 点击 **Settings** $\rightarrow$ 左侧 **Secrets and variables** $\rightarrow$ **Actions**；
3. 点击 **New repository secret** 分别添加以下两个变量：
   * **名称**：`CF_ZONE_ID`，**Secret**：填入刚才复制的区域 ID；
   * **名称**：`CF_API_TOKEN`，**Secret**：填入刚才复制的 API 令牌。

#### 4. 立即手动运行测试一次
1. 在 GitHub 仓库上方点击 **Actions** 标签页；
2. 在左侧列表点击 **Cloudflare DNS 智能测速与自动更新**；
3. 点击右侧的 **Run workflow** $\rightarrow$ 点击绿色按钮确认执行；
4. 约 1~2 分钟后查看运行日志，若显示 `[🎉] 成功将 best.66688800.xyz 同步为最新最优双 IP`，说明系统已全自动闭环！
5. 登录 Cloudflare DNS 控制台，你会发现 `best.66688800.xyz` 已经自动生成了两条灰云（仅 DNS）的 A 记录。

---

### 第四步：日常使用

1. 打开你部署好的生成器网页，勾选协议、设置端口；
2. `cfip` 输入框已默认设定为 `best.66688800.xyz`（也可以点击旁边的 **`⚡ 智能测速优选`** 按钮实时测速选择）；
3. 复制生成命令在 Linux 服务器（VPS）终端回车执行；
4. 部署完成后，在客户端（v2rayN / Clash / Sing-box 等）中：
   * 节点的 **服务器地址 (Address)** 永久保持为 `best.66688800.xyz`；
   * **终身不需要再手动修改节点配置**，后台 GitHub Actions 会全天候自动将该域名指向当前网络质量最好的 Cloudflare 节点！
