#!/bin/bash

# 系统管理模块 - system.sh

# 查看当前 TCP 拥塞控制算法
function check_tcp_congestion() {
    echo "当前 TCP 拥塞控制算法为："
    sysctl net.ipv4.tcp_congestion_control
    echo ""
}

# 开启 BBR 加速
function enable_bbr() {
    echo "正在开启 BBR 加速..."
    sudo modprobe tcp_bbr
    echo "tcp_bbr" | sudo tee -a /etc/modules-load.d/modules.conf
    sudo sysctl -w net.core.default_qdisc=fq
    sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
    sudo sysctl -p
    echo ""
    echo "✅ BBR 加速已尝试开启。请使用下面的选项验证。"
}

# 查看系统信息
function system_info() {
    echo "系统信息："
    echo "-------------------------------"
    uname -a
    echo "-------------------------------"
    lsb_release -a 2>/dev/null || cat /etc/os-release
    echo "-------------------------------"
}

# 菜单入口
function system_menu() {
    while true; do
        echo ""
        echo "====== 系统管理工具 ======"
        echo "1. 查看 TCP 拥塞控制算法"
        echo "2. 开启 BBR 加速"
        echo "3. 查看系统信息"
        echo "0. 返回主菜单"
        echo "========================="
        read -rp "请输入选项: " opt
        case $opt in
            1) check_tcp_congestion ;;
            2) enable_bbr ;;
            3) system_info ;;
            0) break ;;
            *) echo "无效选项，请重试。" ;;
        esac
    done
}

# 启动菜单
system_menu

