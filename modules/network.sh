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
    # 填入对应的安装命令
    pause
}

# 8. NginxProxyManager 可视化面板
install_nginx_proxy_manager() {
    echo -e "${GREEN}安装 Nginx Proxy Manager 可视化面板...${NC}"
    # 填入对应的安装命令
    pause
}

# 9. AList网盘
install_alist() {
    echo -e "${GREEN}安装 AList 网盘...${NC}"
    # 填入对应的安装命令
    pause
}

# 10. 甲骨文保活脚本
install_oracle_keep_alive() {
    echo -e "${GREEN}安装甲骨文保活脚本...${NC}"
    curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh -o oalive.sh && chmod +x oalive.sh && bash oalive.sh
    pause
}

# 11. 哪吒探针
install_nezha_probe() {
    echo -e "${GREEN}安装哪吒探针...${NC}"
    # 填入对应的安装命令
    pause
}

# 12. 青龙面板定时任务
install_qinglong_cron() {
    echo -e "${GREEN}安装青龙面板定时任务...${NC}"
    # 填入对应的安装命令
    pause
}

# 13. Ubuntu远程桌面
install_ubuntu_rdp() {
    echo -e "${GREEN}安装 Ubuntu 远程桌面...${NC}"
    # 填入对应的安装命令
    pause
}

# 安装 Nginx Proxy Manager
install_nginx_proxy_manager() {
    echo -e "${RED}如果您已经安装了其他面板或者LDNMP建站环境，建议先卸载，再安装 npm！${NC}"
    echo -e "${GREEN}开始安装 Nginx Proxy Manager...${NC}"
    sudo apt-get update
    sudo apt-get install -y curl wget git
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo docker volume create nginx-proxy-manager
    sudo docker run -d -p 81:81 -p 443:443 -p 80:80 --name nginx-proxy-manager \
    -v nginx-proxy-manager:/config \
    --restart=unless-stopped jc21/nginx-proxy-manager:latest
    echo -e "${GREEN}Nginx Proxy Manager 安装完成！访问： http://<你的服务器IP>:81${NC}"
    pause
}

# 更新 Nginx Proxy Manager
update_nginx_proxy_manager() {
    echo -e "${GREEN}开始更新 Nginx Proxy Manager...${NC}"
    sudo docker pull jc21/nginx-proxy-manager:latest
    sudo docker stop nginx-proxy-manager
    sudo docker rm nginx-proxy-manager
    sudo docker run -d -p 81:81 -p 443:443 -p 80:80 --name nginx-proxy-manager \
    -v nginx-proxy-manager:/config \
    --restart=unless-stopped jc21/nginx-proxy-manager:latest
    echo -e "${GREEN}Nginx Proxy Manager 更新完成！${NC}"
    pause
}

# 卸载 Nginx Proxy Manager
uninstall_nginx_proxy_manager() {
    echo -e "${RED}你确定要卸载 Nginx Proxy Manager 吗？（y/n）${NC}"
    read confirmation
    if [[ $confirmation == "y" || $confirmation == "Y" ]]; then
        sudo docker stop nginx-proxy-manager
        sudo docker rm nginx-proxy-manager
        sudo docker volume rm nginx-proxy-manager
        echo -e "${GREEN}Nginx Proxy Manager 已卸载。${NC}"
    else
        echo -e "${GREEN}取消卸载操作。${NC}"
    fi
    pause
}

# 添加域名访问
add_domain_access() {
    echo -e "${GREEN}请输入要添加的域名：${NC}"
    read domain
    echo -e "${GREEN}添加域名访问：$domain${NC}"
    # 这里可以添加添加域名的具体命令
    pause
}

# 删除域名访问
delete_domain_access() {
    echo -e "${GREEN}请输入要删除的域名：${NC}"
    read domain
    echo -e "${GREEN}删除域名访问：$domain${NC}"
    # 这里可以添加删除域名的具体命令
    pause
}

# 允许IP+端口访问
allow_ip_port_access() {
    echo -e "${GREEN}请输入允许访问的IP地址：${NC}"
    read ip
    echo -e "${GREEN}请输入允许访问的端口：${NC}"
    read port
    echo -e "${GREEN}允许IP：$ip 访问端口：$port${NC}"
    # 这里可以添加允许IP和端口访问的具体命令
    pause
}

# 阻止IP+端口访问
block_ip_port_access() {
    echo -e "${GREEN}请输入阻止访问的IP地址：${NC}"
    read ip
    echo -e "${GREEN}请输入阻止访问的端口：${NC}"
    read port
    echo -e "${GREEN}阻止IP：$ip 访问端口：$port${NC}"
    # 这里可以添加阻止IP和端口访问的具体命令
    pause
}

# 主菜单
show_menu() {
    echo -e "${GREEN}网络相关工具菜单${NC}"
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
    echo "11. 安装 哪吒探针"
    echo "12. 安装 青龙面板定时任务"
    echo "13. 安装 Ubuntu 远程桌面"
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
            install_nginx_proxy_manager
            ;;
        9)
            install_alist
            ;;
        10)
            install_oracle_keep_alive
            ;;
        11)
            install_nezha_probe
            ;;
        12)
            install_qinglong_cron
            ;;
        13)
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

