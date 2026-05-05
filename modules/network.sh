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
    bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
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

# 7. 1Panel管理面板
install_1pane_panel() {
    echo -e "${GREEN}安装1Panel管理面板...${NC}"

# ==== 下面是完整内嵌的1Panel菜单脚本，全部塞在这里 ====
# 配置项
PANEL_INSTALL_DIR="/opt/1panel"  # 1Panel 安装目录
PANEL_SERVICE_FILE="/etc/systemd/system/1panel.service"  # 1Panel 服务文件路径

# 颜色配置
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 函数：显示菜单
show_menu() {
    clear
    
    # 检查是否已安装 1Panel
    if [ -d "$PANEL_INSTALL_DIR" ] || [ -f "$PANEL_SERVICE_FILE" ]; then
        INSTALL_STATUS="已安装"
    else
        INSTALL_STATUS="未安装"
    fi

  # 显示安装状态和安装目录（绿色）
    echo -e "${GREEN}1Panel 安装状态: $INSTALL_STATUS${NC}"
    echo -e "${GREEN}安装目录: $PANEL_INSTALL_DIR${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    # 显示菜单头部
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱菜单-1Panel${NC}"
    echo -e "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}========================================${NC}"
    
    # 主菜单选项
    echo "1. 安装 1Panel"
    echo "2. 查看面板信息"
    echo "3. 修改密码"
    echo "4. 卸载 1Panel"
    echo "0. 退出"
    read -p "请输入选项: " option
    case $option in
        1) install_panel ;;
        2) view_panel_info ;;
        3) update_password ;;
        4) uninstall_panel ;;
        0) exit 0 ;;  # 退出选项
        *) echo "无效的选项，请重新选择！" && sleep 2 && show_menu ;;
    esac
}

# 函数：安装 1Panel
install_panel() {
    echo "开始安装 1Panel..."

    # 执行官方安装脚本
    curl -sSL https://resource.1panel.pro/quick_start.sh -o quick_start.sh && bash quick_start.sh

    echo "1Panel 安装完成！"
    echo "请使用以下命令查看面板地址："
    echo "您可以通过 1pctl user-info 查看面板信息"
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
    show_menu
}

# 函数：查看面板信息
view_panel_info() {
    echo "正在获取面板信息..."
    1pctl user-info
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
    show_menu
}

# 函数：修改密码
update_password() {
    echo "正在修改密码..."
    # 通过官方命令修改密码
    1pctl update password
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
    show_menu
}

# 函数：卸载 1Panel
uninstall_panel() {
    read -p "您确定要卸载 1Panel 并删除所有相关文件吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "正在卸载 1Panel..."

        # 停止并禁用服务
        sudo systemctl stop 1panel
        sudo systemctl disable 1panel

        # 删除 1Panel 相关文件
        echo "查找并删除 1Panel 相关文件..."
        sudo find / -name "1panel*" -exec sudo rm -rf {} \;

        # 删除服务文件
        echo "检查并删除服务文件..."
        sudo rm -f /root/1panel-v1.10.29-lts-linux-amd64/1panel.service
        sudo rm -f /etc/systemd/system/1panel.service

        # 确保 1Panel 安装目录被删除
        if [ -d "$PANEL_INSTALL_DIR" ]; then
            echo "删除安装目录..."
            sudo rm -rf "$PANEL_INSTALL_DIR"
        fi

        # 确认所有相关文件已删除
        echo "确认所有相关文件已删除..."
        sudo find / -name "1panel*"

        # 清理日志文件
        echo "清理日志文件..."
        sudo rm -f /var/log/1panel.log

        echo "1Panel 卸载完成！"
    else
        echo "取消卸载。"
    fi
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
    show_menu
}

# 启动脚本
show_menu

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
    curl -fsSL "https://alist.nn.ci/v3.sh" -o v3.sh && bash v3.sh
    pause
}

# 10. 甲骨文保活脚本
install_oracle_keep_alive() {
    echo -e "${GREEN}安装甲骨文保活脚本...${NC}"
    curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh -o oalive.sh && chmod +x oalive.sh && bash oalive.sh
    pause
}

# 11. 哪吒监控面板
install_nezajiankong_cron() {
    echo -e "${GREEN}安装哪吒监控面板...${NC}"
    curl -L https://raw.githubusercontent.com/nezhahq/scripts/refs/heads/main/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh
    pause
}

# 12. dpanel可视化管理面板
install_dpanel_panel() {
    echo -e "${GREEN}安装 dpanel可视化管理面板 ${NC}"
    curl -sSL https://dpanel.cc/quick.sh -o quick.sh && sudo bash quick.sh
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
    echo "11. 安装 哪吒监控面板"
    echo "12. 安装 dpanel可视化管理面板"
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
            install_nezajiankong_cron
            ;;
        12)
            install_dpanel_panel
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
