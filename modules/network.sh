#!/bin/bash

# 启用 BBR 加速
enable_bbr() {
    echo "正在启用 BBR 加速..."
    modprobe tcp_bbr
    echo "tcp_bbr" | tee -a /etc/modules-load.d/modules.conf
    sysctl -w net.core.default_qdisc=fq
    sysctl -w net.ipv4.tcp_congestion_control=bbr
    sysctl -p
    echo "BBR 加速已启用。"
}

# 查询 TCP 拥塞控制算法
check_tcp_congestion() {
    algo=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    echo "当前 TCP 拥塞控制算法: $algo"
}

# 主菜单
echo "网络优化模块："
echo "1. 启用 BBR 加速"
echo "2. 查询 TCP 拥塞控制算法"
echo "0. 返回主菜单"
read -p "请输入选项编号: " choice
case $choice in
    1) enable_bbr ;;
    2) check_tcp_congestion ;;
    0) exit 0 ;;
    *) echo "无效输入。" ;;
esac
