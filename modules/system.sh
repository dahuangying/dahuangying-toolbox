#!/bin/bash

# 系统管理模块

# 查看当前 TCP 拥塞控制算法
function check_tcp_congestion() {
    echo "当前 TCP 拥塞控制算法："
    sysctl net.ipv4.tcp_congestion_control
}

# 开启 BBR 加速
function enable_bbr() {
    echo "正在开启 BBR..."
    # 加载 BBR 模块
    modprobe tcp_bbr
    # 设置加载 tcp_bbr
    echo "tcp_bbr" | tee -a /etc/modules-load.d/modules.conf
    # 配置 BBR 加速
    sysctl -w net.core.default_qdisc=fq
    sysctl -w net.ipv4.tcp_congestion_control=bbr
    # 重新加载系统配置
    sysctl -p
    echo "✅ BBR 已尝试开启。"
}

# 查看系统信息
function system_info() {
    echo "系统信息："
    uname -a
    lsb_release -a 2>/dev/null || cat /etc/os-release
}

# 菜单入口
function system_menu() {
    while true; do
        echo "====== 系统优化工具 ======"
        echo "1. 查看 TCP 拥塞算法"
        echo "2. 开启 BBR 加速"
        echo "3. 查看系统信息"
        echo "0. 返回主菜单"
        read -rp "选择操作: " choice
        case $choice in
            1) check_tcp_congestion ;;
            2) enable_bbr ;;
            3) system_info ;;
            0) break ;;
            *) echo "无效输入" ;;
        esac
    done
}

system_menu  # 确保调用菜单
