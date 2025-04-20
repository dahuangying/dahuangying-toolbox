#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
NC='\033[0m' # 无色
RED='\033[0;31m'

# 显示暂停，按任意键继续
pause() {
    echo -e "${GREEN}操作完成，按任意键继续...${NC}"
    read -n 1 -s -r  # 等待用户按下任意键
    echo
}

# 1. 开启自带BBR加速
bbr_acceleration() {
    echo -e "${GREEN}开启自带BBR加速...${NC}"
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    lsmod | grep bbr
    echo -e "${GREEN}BBR加速已启用！${NC}"
    pause
}

# 2. 查询 TCP 拥塞控制算法
query_tcp_congestion_control() {
    echo -e "${GREEN}查询TCP拥塞控制算法...${NC}"
    sysctl net.ipv4.tcp_congestion_control
    pause
}

# 3. BBRplus 加速
bbr_plus_acceleration() {
    echo -e "${GREEN}安装BBRplus加速...${NC}"
    wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
    pause
}

# 4. X-UI面板
install_xui_panel() {
    echo -e "${GREEN}安装X-UI面板...${NC}"
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    pause
}

# 5. 3X-UI面板
install_3xui_panel() {
    echo -e "${GREEN}安装3X-UI面板...${NC}"
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    pause
}

# 6. 极光面板
install_aurora_panel() {
    echo -e "${GREEN}安装极光面板...${NC}"
    bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh)
    pause
}

# 7. 1Pane管理面板
install_1pane_panel() {
    echo -e "${GREEN}安装1Pane管理面板...${NC}"
    bash ./modules/1Panel.sh
    pause
}

# 8. NginxProxyManager 可视化面板
install_nginx_proxy_manager_panel() {
    echo -e "${GREEN}安装 Nginx Proxy Manager 可视化面板...${NC}"
    bash modules/nginx-proxy-manager.sh
    pause
}

# 9. AList网盘
install_alist_panel() {
    echo -e "${GREEN}安装 AList 网盘...${NC}"
    bash modules/alist.sh
    pause
}

# 10. 甲骨文保活脚本
install_oracle_keep_alive() {
    echo -e "${GREEN}安装甲骨文保活脚本...${NC}"
    curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh -o oalive.sh && chmod +x oalive.sh && bash oalive.sh
    pause
}

# 11. 青龙面板定时任务
install_qinglong_cron() {
    echo -e "${GREEN}安装青龙面板定时任务...${NC}"
    # 填入对应的安装命令
    pause
}

# 12. Ubuntu远程桌面
install_ubuntu_rdp() {
    echo -e "${GREEN}安装 Ubuntu 远程桌面...${NC}"
    # 填入对应的安装命令
    pause
}

# 主菜单
show_menu() {
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱菜单-应用脚本${NC}"
    echo -e "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}==================================${NC}"
    echo "1. 开启自带BBR加速"
    echo "2. 查询 TCP 拥塞控制算法"
    echo "3. BBRplus 加速"
    echo "4. 安装 X-UI 面板"
    echo "5. 安装 3X-UI 面板"
    echo "6. 安装 极光面板"
    echo "7. 安装 1Pane 管理面板"
    echo "8. 安装 Nginx Proxy Manager 可视化面板"
    echo "9. 安装 AList 网盘"
    echo "10. 安装 甲骨文保活脚本"
    echo "11. 安装 青龙面板定时任务"
    echo "12. 安装 Ubuntu 远程桌面"
    echo "0. 退出"
    read -p "请输入选项编号: " choice
    case $choice in
        1)
            bbr_acceleration
            ;;
        2)
            query_tcp_congestion_control
            ;;
        3)
            bbr_plus_acceleration
            ;;
        4)
            install_xui_panel
            ;;
        5)
            install_3xui_panel
            ;;
        6)
            install_aurora_panel
            ;;
        7)
            install_1pane_panel
            ;;
        8)
            install_nginx_proxy_manager_panel
            ;;
        9)
            install_alist_panel
            ;;
        10)
            install_oracle_keep_alive
            ;;
        11)
            install_qinglong_cron
            ;;
        12)
            install_ubuntu_rdp
            ;;
        0)
            echo "感谢使用工具箱！"
            exit 0
            ;;
        *)
            echo "无效输入，请重试。"
            ;;
    esac
}

# 主程序入口
while true; do
    show_menu
done

