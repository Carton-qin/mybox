#!/usr/bin/env python3
"""
MyBox: Cloudflare 智能测速与 DNS A 记录自动同步脚本
- 采用 Python 原生标准库（无需额外 pip 安装）
- 并发测速 Cloudflare Anycast 候选 IP 池
- 筛选延迟最低、丢包为 0 的前 2 个 IP
- 调用 Cloudflare REST API 自动更新 best.66688800.xyz 的双 A 记录（轮询容灾）
"""

import os
import sys
import json
import time
import socket
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor

# 待测试的典型高分 Cloudflare 候选 IP 池（涵盖不同大网段与亚太直连段）
CANDIDATE_IPS = [
    "104.16.160.25", "104.17.160.25", "104.18.2.1", "104.19.2.1",
    "104.20.2.1", "104.21.2.1", "104.22.2.1", "104.24.2.1",
    "162.159.138.25", "162.159.153.1", "162.159.192.1", "162.159.200.1",
    "172.67.180.12", "172.64.100.1", "172.65.100.1", "172.66.100.1",
    "141.101.90.1", "198.41.128.1", "173.245.58.1", "188.114.96.1"
]

RECORD_NAME = "best.66688800.xyz"

def test_ip_latency(ip, port=443, rounds=3, timeout=1.5):
    """测试单个 IP 的 TCP 连接延迟（毫秒）"""
    latencies = []
    for _ in range(rounds):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        start = time.perf_counter()
        try:
            s.connect((ip, port))
            cost = (time.perf_counter() - start) * 1000
            latencies.append(cost)
        except Exception:
            pass
        finally:
            s.close()
        time.sleep(0.05)

    if not latencies:
        return ip, 9999.0, 1.0  # 全部超时

    avg_latency = sum(latencies) / len(latencies)
    loss_rate = (rounds - len(latencies)) / rounds
    return ip, avg_latency, loss_rate

def pick_best_ips(num_top=2):
    """多线程并发测速并挑选出最优的前 N 个 IP"""
    print(f"[*] 开始对 {len(CANDIDATE_IPS)} 个 Cloudflare Anycast IP 节点进行并发延迟测速...")
    results = []
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(test_ip_latency, ip) for ip in CANDIDATE_IPS]
        for f in futures:
            results.append(f.result())

    # 按丢包率升序、平均延时升序排列
    valid = [r for r in results if r[2] == 0.0]  # 只保留 0 丢包
    if not valid:
        valid = results  # 若网络极差退而求其次

    valid.sort(key=lambda x: (x[2], x[1]))

    print("\n[+] 测速榜单 Top 5 节点：")
    for rank, (ip, lat, loss) in enumerate(valid[:5], 1):
        print(f"  {rank}. IP: {ip:<16} | 平均延迟: {lat:6.1f} ms | 丢包率: {loss*100:.0f}%")

    top_ips = [r[0] for r in valid[:num_top]]
    return top_ips

def cf_api_request(url, method="GET", token="", data=None):
    """向 Cloudflare API 发起 HTTP 请求"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    body = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8")
        print(f"[-] Cloudflare API 请求失败 ({e.code}): {err_msg}")
        raise

def sync_to_cloudflare(zone_id, token, target_domain, best_ips):
    """更新或添加 DNS A 记录"""
    base_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records"
    
    print(f"\n[*] 正在查询 {target_domain} 的当前 DNS 记录...")
    query_url = f"{base_url}?type=A&name={target_domain}"
    existing_resp = cf_api_request(query_url, token=token)
    
    if not existing_resp.get("success"):
        print("[-] 查询现有 DNS 记录失败:", existing_resp.get("errors"))
        return False

    records = existing_resp.get("result", [])
    print(f"[+] 找到现有 A 记录 {len(records)} 条")

    # 1. 更新或创建前 N 条
    for idx, new_ip in enumerate(best_ips):
        payload = {
            "type": "A",
            "name": target_domain,
            "content": new_ip,
            "ttl": 60,            # 极低 TTL 方便快速生效
            "proxied": False      # 关键！必须灰色小云朵（仅 DNS），否则失去优选效果
        }
        if idx < len(records):
            # 更新已有记录
            rec_id = records[idx]["id"]
            print(f"[*] 更新记录 #{idx+1} ({rec_id}) -> {new_ip}")
            update_url = f"{base_url}/{rec_id}"
            cf_api_request(update_url, method="PUT", token=token, data=payload)
        else:
            # 创建新记录
            print(f"[*] 新增 A 记录 -> {new_ip}")
            cf_api_request(base_url, method="POST", token=token, data=payload)

    # 2. 如果之前存在的记录比我们要的更多，清理掉多余的
    if len(records) > len(best_ips):
        for old_rec in records[len(best_ips):]:
            del_id = old_rec["id"]
            print(f"[*] 清理多余历史 A 记录: {del_id} ({old_rec.get('content')})")
            del_url = f"{base_url}/{del_id}"
            cf_api_request(del_url, method="DELETE", token=token)

    print(f"\n[🎉] 成功将 {target_domain} 同步为最新最优双 IP: {', '.join(best_ips)}")
    return True

def main():
    token = os.environ.get("CF_API_TOKEN", "").strip()
    zone_id = os.environ.get("CF_ZONE_ID", "").strip()
    target_domain = os.environ.get("CF_SUBDOMAIN", RECORD_NAME).strip()

    best_ips = pick_best_ips(num_top=2)

    if not token or not zone_id:
        print("\n[!] 未提供 CF_API_TOKEN 或 CF_ZONE_ID 环境变量。")
        print("[!] 测速已完成，但跳过 Cloudflare API 同步。若需自动更新请配置 GitHub Secrets。")
        print(f"[!] 推荐手动设置 A 记录: {target_domain} -> {best_ips}")
        return

    try:
        sync_to_cloudflare(zone_id, token, target_domain, best_ips)
    except Exception as e:
        print(f"[-] 同步失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
