#!/usr/bin/env bash
#=============================================================================
# MyBox: 现代化多协议代理 & Cloudflare 智能优选节点一键管理脚本
# 项目主页: https://github.com/your-username/my-box
# 默认优选: best.66688800.xyz
#=============================================================================

export LANG=en_US.UTF-8
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

MYBOX_DIR="/etc/mybox"
MYBOX_BIN_DIR="/usr/local/bin"
ENV_FILE="${MYBOX_DIR}/config.env"
XRAY_BIN="${MYBOX_BIN_DIR}/mybox-xray"
SINGBOX_BIN="${MYBOX_BIN_DIR}/mybox-singbox"
ARGO_BIN="${MYBOX_BIN_DIR}/mybox-cloudflared"

# 默认变量
cfip="${cfip:-best.66688800.xyz}"
reym="${reym:-apple.com}"
name="${name:-MyBox}"
uuid="${uuid:-}"
sub="${sub:-}"
subid="${subid:-}"
subpt="${subpt:-}"
argo="${argo:-}"
agn="${agn:-}"
agk="${agk:-}"
warp="${warp:-}"
ippz="${ippz:-}"
oap="${oap:-}"
alns="${alns:-}"
hyjpt="${hyjpt:-}"
cdnym="${cdnym:-}"

# 协议端口默认空
vlpt="${vlpt:-}"
xhpt="${xhpt:-}"
vxpt="${vxpt:-}"
vwpt="${vwpt:-}"
xupt="${xupt:-}"
xcpt="${xcpt:-}"
tupt="${tupt:-}"
anpt="${anpt:-}"
arpt="${arpt:-}"
hypt="${hypt:-}"

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[错误] 必须使用 root 用户权限运行此脚本！${PLAIN}"
        exit 1
    fi
}

# 架构检测
detect_arch() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            ARCH="amd64"
            ARCH_XRAY="64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ARCH_XRAY="arm64-v8a"
            ;;
        *)
            echo -e "${RED}[错误] 暂不支持当前 CPU 架构: ${arch}${PLAIN}"
            exit 1
            ;;
    esac
}

# 获取随机可用端口 (10000-65000)
get_random_port() {
    local port
    while true; do
        port=$((RANDOM % 55000 + 10000))
        if ! ss -tuln | grep -q ":${port} "; then
            echo "$port"
            break
        fi
    done
}

# 获取服务器公网 IPv4 与 IPv6
detect_ip() {
    SERVER_IP4=$(curl -s4m 4 https://api.ipify.org || curl -s4m 4 https://icanhazip.com || true)
    SERVER_IP6=$(curl -s6m 4 https://api64.ipify.org || curl -s6m 4 https://icanhazip.com || true)
    
    if [[ "$ippz" == "6" && -n "$SERVER_IP6" ]]; then
        OUT_IP="$SERVER_IP6"
    elif [[ -n "$SERVER_IP4" ]]; then
        OUT_IP="$SERVER_IP4"
    elif [[ -n "$SERVER_IP6" ]]; then
        OUT_IP="$SERVER_IP6"
    else
        OUT_IP="127.0.0.1"
    fi
}

# 安装系统依赖
install_dependencies() {
    echo -e "${BLUE}[1/5] 检查并安装基础依赖软件包...${PLAIN}"
    if command -v apt-get &>/dev/null; then
        apt-get update -y >/dev/null 2>&1
        apt-get install -y curl wget jq tar unzip openssl lsof iptables cron >/dev/null 2>&1
    elif command -v yum &>/dev/null; then
        yum install -y epel-release >/dev/null 2>&1
        yum install -y curl wget jq tar unzip openssl lsof iptables cronie >/dev/null 2>&1
    elif command -v apk &>/dev/null; then
        apk add curl wget jq tar unzip openssl lsof iptables
    fi
}

# 放行系统所有端口
configure_firewall() {
    if [[ "$oap" == "y" ]]; then
        echo -e "${YELLOW}[提示] 正在放行系统防火墙端口...${PLAIN}"
        if command -v ufw &>/dev/null; then
            ufw disable >/dev/null 2>&1 || true
        fi
        if command -v iptables &>/dev/null; then
            iptables -P INPUT ACCEPT || true
            iptables -P FORWARD ACCEPT || true
            iptables -P OUTPUT ACCEPT || true
            iptables -F || true
        fi
    fi
}

# 下载官方内核程序
install_binaries() {
    echo -e "${BLUE}[2/5] 下载并安装 Xray / Sing-box / cloudflared 官方二进制内核...${PLAIN}"
    mkdir -p "${MYBOX_DIR}" "${MYBOX_BIN_DIR}"
    
    # 1. Xray-core
    if [[ ! -f "$XRAY_BIN" ]]; then
        echo -e "正在获取 Xray 最新版本..."
        local xray_tag=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | jq -r .tag_name 2>/dev/null || echo "v24.12.31")
        [[ -z "$xray_tag" || "$xray_tag" == "null" ]] && xray_tag="v24.12.31"
        local xray_url="https://github.com/XTLS/Xray-core/releases/download/${xray_tag}/Xray-linux-${ARCH_XRAY}.zip"
        
        wget -qO /tmp/xray.zip "$xray_url" || curl -sLo /tmp/xray.zip "$xray_url"
        unzip -qo /tmp/xray.zip -d /tmp/xray_temp
        mv /tmp/xray_temp/xray "$XRAY_BIN"
        chmod +x "$XRAY_BIN"
        rm -rf /tmp/xray.zip /tmp/xray_temp
    fi

    # 2. Sing-box
    if [[ ! -f "$SINGBOX_BIN" ]]; then
        echo -e "正在获取 Sing-box 最新版本..."
        local sb_tag=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r .tag_name 2>/dev/null || echo "v1.11.4")
        [[ -z "$sb_tag" || "$sb_tag" == "null" ]] && sb_tag="v1.11.4"
        local clean_tag="${sb_tag#v}"
        local sb_url="https://github.com/SagerNet/sing-box/releases/download/${sb_tag}/sing-box-${clean_tag}-linux-${ARCH}.tar.gz"
        
        wget -qO /tmp/sb.tar.gz "$sb_url" || curl -sLo /tmp/sb.tar.gz "$sb_url"
        tar -xzf /tmp/sb.tar.gz -C /tmp/
        mv /tmp/sing-box-${clean_tag}-linux-${ARCH}/sing-box "$SINGBOX_BIN"
        chmod +x "$SINGBOX_BIN"
        rm -rf /tmp/sb.tar.gz /tmp/sing-box*
    fi

    # 3. cloudflared (若开启 Argo)
    if [[ -n "$argo" && ! -f "$ARGO_BIN" ]]; then
        echo -e "正在获取 Cloudflared 最新程序..."
        local argo_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}"
        wget -qO "$ARGO_BIN" "$argo_url" || curl -sLo "$ARGO_BIN" "$argo_url"
        chmod +x "$ARGO_BIN"
    fi
}

# 生成 Reality 密钥对
generate_reality_keys() {
    if [[ -z "$REALITY_PRIV_KEY" || -z "$REALITY_PUB_KEY" ]]; then
        local keypair=$("$XRAY_BIN" x25519 2>/dev/null || true)
        REALITY_PRIV_KEY=$(echo "$keypair" | grep -i "private" | awk '{print $NF}' | tr -d '[:space:]')
        REALITY_PUB_KEY=$(echo "$keypair" | grep -i "public" | awk '{print $NF}' | tr -d '[:space:]')
        REALITY_SHORT_ID=$(openssl rand -hex 8)
    fi
}

# 保存配置环境变量供 list/rep 读取
save_env() {
    cat > "$ENV_FILE" <<EOF
uuid="${uuid}"
cfip="${cfip}"
reym="${reym}"
alns="${alns}"
hyjpt="${hyjpt}"
cdnym="${cdnym}"
warp="${warp}"
ippz="${ippz}"
oap="${oap}"
name="${name}"
sub="${sub}"
subid="${subid}"
subpt="${subpt}"
argo="${argo}"
agn="${agn}"
agk="${agk}"
vlpt="${vlpt}"
xhpt="${xhpt}"
vxpt="${vxpt}"
vwpt="${vwpt}"
xupt="${xupt}"
xcpt="${xcpt}"
tupt="${tupt}"
anpt="${anpt}"
arpt="${arpt}"
hypt="${hypt}"
REALITY_PRIV_KEY="${REALITY_PRIV_KEY}"
REALITY_PUB_KEY="${REALITY_PUB_KEY}"
REALITY_SHORT_ID="${REALITY_SHORT_ID}"
EOF
}

# 部署并构建 Xray 配置文件
build_xray_config() {
    local inbounds="[]"
    
    # Reality Vision TCP
    if [[ -n "$vlpt" ]]; then
        generate_reality_keys
        inbounds=$(echo "$inbounds" | jq --arg port "$vlpt" --arg id "$uuid" --arg dest "$reym:443" --arg serverName "$reym" --arg priv "$REALITY_PRIV_KEY" --arg shortId "$REALITY_SHORT_ID" \
        '. += [{
            "listen": "0.0.0.0",
            "port": ($port|tonumber),
            "protocol": "vless",
            "settings": {
                "clients": [{"id": $id, "flow": "xtls-rprx-vision"}],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": $dest,
                    "xver": 0,
                    "serverNames": [$serverName],
                    "privateKey": $priv,
                    "shortIds": [$shortId]
                }
            }
        }]')
    fi

    # Reality XHTTP Enc
    if [[ -n "$xhpt" ]]; then
        generate_reality_keys
        inbounds=$(echo "$inbounds" | jq --arg port "$xhpt" --arg id "$uuid" --arg dest "$reym:443" --arg serverName "$reym" --arg priv "$REALITY_PRIV_KEY" --arg shortId "$REALITY_SHORT_ID" \
        '. += [{
            "listen": "0.0.0.0",
            "port": ($port|tonumber),
            "protocol": "vless",
            "settings": {
                "clients": [{"id": $id}],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "xhttp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": $dest,
                    "xver": 0,
                    "serverNames": [$serverName],
                    "privateKey": $priv,
                    "shortIds": [$shortId]
                },
                "xhttpSettings": { "path": "/xhttp" }
            }
        }]')
    fi

    # Vless-ws-enc (CDN / Argo 隧道主力)
    if [[ -n "$vwpt" ]]; then
        inbounds=$(echo "$inbounds" | jq --arg port "$vwpt" --arg id "$uuid" \
        '. += [{
            "listen": "0.0.0.0",
            "port": ($port|tonumber),
            "protocol": "vless",
            "settings": {
                "clients": [{"id": $id}],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": { "path": "/vless-ws" }
            }
        }]')
    fi

    # Vless-xhttp-enc
    if [[ -n "$vxpt" ]]; then
        inbounds=$(echo "$inbounds" | jq --arg port "$vxpt" --arg id "$uuid" \
        '. += [{
            "listen": "0.0.0.0",
            "port": ($port|tonumber),
            "protocol": "vless",
            "settings": {
                "clients": [{"id": $id}],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "xhttp",
                "security": "none",
                "xhttpSettings": { "path": "/vxhttp" }
            }
        }]')
    fi

    # 组装完整 Xray 配置
    cat > "${MYBOX_DIR}/xray.json" <<EOF
{
    "log": { "loglevel": "warning" },
    "inbounds": ${inbounds},
    "outbounds": [{ "protocol": "freedom", "tag": "direct" }]
}
EOF
}

# 部署并构建 Singbox 配置文件
build_singbox_config() {
    local inbounds="[]"

    # Hysteria2
    if [[ -n "$hypt" ]]; then
        # 生成自签名证书
        if [[ ! -f "${MYBOX_DIR}/cert.pem" ]]; then
            openssl req -x509 -newkey rsa:2048 -nodes -sha256 -keyout "${MYBOX_DIR}/key.pem" -out "${MYBOX_DIR}/cert.pem" -days 3650 -subj "/CN=www.bing.com" >/dev/null 2>&1
        fi

        inbounds=$(echo "$inbounds" | jq --arg port "$hypt" --arg pass "$uuid" --arg cert "${MYBOX_DIR}/cert.pem" --arg key "${MYBOX_DIR}/key.pem" \
        '. += [{
            "type": "hysteria2",
            "tag": "hy2-in",
            "listen": "::",
            "listen_port": ($port|tonumber),
            "users": [{"password": $pass}],
            "tls": {
                "enabled": true,
                "certificate_path": $cert,
                "key_path": $key
            }
        }]')
    fi

    # Tuic
    if [[ -n "$tupt" ]]; then
        inbounds=$(echo "$inbounds" | jq --arg port "$tupt" --arg pass "$uuid" --arg cert "${MYBOX_DIR}/cert.pem" --arg key "${MYBOX_DIR}/key.pem" \
        '. += [{
            "type": "tuic",
            "tag": "tuic-in",
            "listen": "::",
            "listen_port": ($port|tonumber),
            "users": [{"uuid": $pass, "password": $pass}],
            "congestion_control": "bbr",
            "tls": {
                "enabled": true,
                "certificate_path": $cert,
                "key_path": $key
            }
        }]')
    fi

    # 组装完整 Sing-box 配置
    cat > "${MYBOX_DIR}/singbox.json" <<EOF
{
    "log": { "level": "warn" },
    "inbounds": ${inbounds},
    "outbounds": [{ "type": "direct", "tag": "direct" }]
}
EOF
}

# 配置 Systemd 守护服务
setup_systemd() {
    echo -e "${BLUE}[4/5] 创建并配置 Systemd 系统守护进程...${PLAIN}"
    
    # Xray 守护
    cat > /etc/systemd/system/mybox-xray.service <<EOF
[Unit]
Description=MyBox Xray Core Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=${XRAY_BIN} run -c ${MYBOX_DIR}/xray.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    # Sing-box 守护
    cat > /etc/systemd/system/mybox-singbox.service <<EOF
[Unit]
Description=MyBox Sing-box Core Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=${SINGBOX_BIN} run -c ${MYBOX_DIR}/singbox.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable mybox-xray >/dev/null 2>&1 || true
    systemctl enable mybox-singbox >/dev/null 2>&1 || true
    systemctl restart mybox-xray || true
    systemctl restart mybox-singbox || true

    # Argo 隧道守护
    if [[ -n "$argo" ]]; then
        local target_port="${vwpt:-$vxpt}"
        if [[ -n "$target_port" ]]; then
            if [[ -n "$agk" ]]; then
                # 固定隧道
                cat > /etc/systemd/system/mybox-argo.service <<EOF
[Unit]
Description=MyBox Cloudflare Argo Fixed Tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=${ARGO_BIN} tunnel --no-autoupdate run --token ${agk}
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
            else
                # 临时隧道
                cat > /etc/systemd/system/mybox-argo.service <<EOF
[Unit]
Description=MyBox Cloudflare Argo Quick Tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=${ARGO_BIN} tunnel --no-autoupdate --url http://127.0.0.1:${target_port}
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
            fi
            systemctl daemon-reload
            systemctl enable mybox-argo >/dev/null 2>&1 || true
            systemctl restart mybox-argo || true
        fi
    fi
}

# 显示配置节点与订阅链接
show_list() {
    [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
    detect_ip

    echo -e ""
    echo -e "${GREEN}======================================================${PLAIN}"
    echo -e "${GREEN}  🎉 MyBox 节点部署完成！连接与配置信息如下：${PLAIN}"
    echo -e "${GREEN}======================================================${PLAIN}"
    echo -e "  默认优选/连接域名: ${BLUE}${cfip}${PLAIN}"
    echo -e "  UUID / 密码:       ${BLUE}${uuid}${PLAIN}"
    echo -e "  服务器真实 IP:     ${SERVER_IP4:-$SERVER_IP6}"
    echo -e "------------------------------------------------------"

    # Reality Vision TCP 节点
    if [[ -n "$vlpt" ]]; then
        local link="vless://${uuid}@${OUT_IP}:${vlpt}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${reym}&fp=chrome&pbk=${REALITY_PUB_KEY}&sid=${REALITY_SHORT_ID}&type=tcp#${name}-Reality-Vision"
        echo -e "${YELLOW}[1] Vless-tcp-reality-vision 直连:${PLAIN}"
        echo -e "${link}"
        echo -e ""
    fi

    # Reality XHTTP Enc 节点
    if [[ -n "$xhpt" ]]; then
        local link="vless://${uuid}@${OUT_IP}:${xhpt}?encryption=none&security=reality&sni=${reym}&fp=chrome&pbk=${REALITY_PUB_KEY}&sid=${REALITY_SHORT_ID}&type=xhttp&path=%2Fxhttp#${name}-Reality-XHTTP"
        echo -e "${YELLOW}[2] Vless-xhttp-reality-enc 直连:${PLAIN}"
        echo -e "${link}"
        echo -e ""
    fi

    # Vless-ws CDN / Argo 优选节点
    if [[ -n "$vwpt" ]]; then
        local sni_domain="${cdnym:-$agn}"
        [[ -z "$sni_domain" ]] && sni_domain="${cfip}"
        local link="vless://${uuid}@${cfip}:80?encryption=none&security=none&type=ws&host=${sni_domain}&path=%2Fvless-ws#${name}-CF-优选WS"
        echo -e "${YELLOW}[3] Vless-ws-enc (Cloudflare CDN / Argo 优选节点):${PLAIN}"
        echo -e "  * 地址 (Address): ${BLUE}${cfip}${PLAIN} (已预设最优 IP 域名)"
        echo -e "  * 伪装域名 (Host): ${BLUE}${sni_domain}${PLAIN}"
        echo -e "${link}"
        echo -e ""
    fi

    # Hysteria2 节点
    if [[ -n "$hypt" ]]; then
        local link="hysteria2://${uuid}@${OUT_IP}:${hypt}/?insecure=1&sni=www.bing.com#${name}-Hysteria2"
        echo -e "${YELLOW}[4] Hysteria2 (高速突破丢包):${PLAIN}"
        echo -e "${link}"
        echo -e ""
    fi

    # Tuic 节点
    if [[ -n "$tupt" ]]; then
        local link="tuic://${uuid}:${uuid}@${OUT_IP}:${tupt}?congestion_control=bbr&alpn=h3&sni=www.bing.com&allow_insecure=1#${name}-Tuic"
        echo -e "${YELLOW}[5] Tuic (QUIC):${PLAIN}"
        echo -e "${link}"
        echo -e ""
    fi

    echo -e "${GREEN}======================================================${PLAIN}"
    echo -e "  快捷管理方式："
    echo -e "  - 查看节点信息: ${YELLOW}bash <(curl -Ls https://raw.githubusercontent.com/your-username/my-box/main/install.sh) list${PLAIN}"
    echo -e "  - 重启所有服务: ${YELLOW}systemctl restart mybox-xray mybox-singbox${PLAIN}"
    echo -e "  - 彻底卸载脚本: ${YELLOW}bash <(curl -Ls https://raw.githubusercontent.com/your-username/my-box/main/install.sh) del${PLAIN}"
    echo -e "${GREEN}======================================================${PLAIN}"
}

# 卸载脚本
uninstall_all() {
    echo -e "${YELLOW}正在彻底停止并卸载 MyBox 服务...${PLAIN}"
    systemctl stop mybox-xray mybox-singbox mybox-argo >/dev/null 2>&1 || true
    systemctl disable mybox-xray mybox-singbox mybox-argo >/dev/null 2>&1 || true
    rm -f /etc/systemd/system/mybox-*
    systemctl daemon-reload
    rm -rf "${MYBOX_DIR}"
    rm -f "${XRAY_BIN}" "${SINGBOX_BIN}" "${ARGO_BIN}"
    echo -e "${GREEN}MyBox 已经成功彻底卸载！${PLAIN}"
}

# 主执行流程
main() {
    check_root
    detect_arch

    case "$1" in
        list)
            show_list
            exit 0
            ;;
        del)
            uninstall_all
            exit 0
            ;;
        res)
            systemctl restart mybox-xray mybox-singbox mybox-argo 2>/dev/null || true
            echo -e "${GREEN}已成功重启 MyBox 核心守护服务！${PLAIN}"
            exit 0
            ;;
        upx)
            rm -f "$XRAY_BIN"
            install_binaries
            systemctl restart mybox-xray
            echo -e "${GREEN}Xray-core 已经升级至最新官方版本！${PLAIN}"
            exit 0
            ;;
        ups)
            rm -f "$SINGBOX_BIN"
            install_binaries
            systemctl restart mybox-singbox
            echo -e "${GREEN}Sing-box 已经升级至最新官方版本！${PLAIN}"
            exit 0
            ;;
    esac

    # 默认随机端口分配
    [[ -z "$uuid" ]] && uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16)
    [[ -z "$vlpt" && -z "$xhpt" && -z "$vxpt" && -z "$vwpt" && -z "$hypt" && -z "$tupt" ]] && vlpt=$(get_random_port)
    [[ -n "$vwpt" && "$vwpt" == "" ]] && vwpt=$(get_random_port)
    [[ -n "$vlpt" && "$vlpt" == "" ]] && vlpt=$(get_random_port)
    [[ -n "$xhpt" && "$xhpt" == "" ]] && xhpt=$(get_random_port)
    [[ -n "$hypt" && "$hypt" == "" ]] && hypt=$(get_random_port)
    [[ -n "$tupt" && "$tupt" == "" ]] && tupt=$(get_random_port)

    echo -e "${BLUE}======================================================${PLAIN}"
    echo -e "${BLUE}        🚀 正在开始部署 MyBox 现代代理节点...        ${PLAIN}"
    echo -e "${BLUE}======================================================${PLAIN}"

    install_dependencies
    configure_firewall
    install_binaries
    
    echo -e "${BLUE}[3/5] 构建 Xray & Sing-box 核心配置文件...${PLAIN}"
    build_xray_config
    build_singbox_config
    save_env

    setup_systemd
    show_list
}

main "$@"
