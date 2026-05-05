#!/bin/bash
# ==============================
# 系统基础工具 - base.sh
# ==============================

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 暂停函数
pause() {
    echo -e "\n${GREEN}操作完成，按任意键返回菜单...${NC}"
    read -n 1 -s -r
    echo
}

# 系统基础功能菜单
show_base_menu() {
    clear
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN} 大黄鹰-Linux服务器运维工具箱菜单 - 系统基础功能${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${YELLOW}请选择需要执行的操作：${NC}"
    echo ""
    echo "1. 开启系统自带 BBR 加速"
    echo "2. 查询当前 TCP 拥塞控制算法"
    echo ""
    echo "0. 返回主工具箱"
    echo -e "${GREEN}=============================================${NC}"
    read -p "请输入选项编号: " choice
    case $choice in
        1) bbr_acceleration ;;
        2) query_tcp_congestion ;;
        0) exit 0 ;;
        *) 
            echo -e "${RED}无效输入，请重试！${NC}"
            sleep 1
            ;;
    esac
}

# 1. 开启BBR
bbr_acceleration() {
    echo -e "${GREEN}正在开启系统 BBR 加速...${NC}"
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    lsmod | grep bbr
    pause
}

# 2. 查询TCP算法
query_tcp_congestion() {
    echo -e "${GREEN}当前 TCP 拥塞控制算法：${NC}"
    sysctl net.ipv4.tcp_congestion_control
    pause
}

# ==============================
# 入口
# ==============================
while true; do
    show_base_menu
done
