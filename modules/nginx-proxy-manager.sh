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

# 官网介绍
show_intro() {
    echo -e "${GREEN}Nginx Proxy Manager - 简易安装与管理面板${NC}"
    echo -e "官网介绍: https://nginxproxymanager.com/"
    echo -e "${GREEN}------------------------${NC}"
}

# 提示卸载已有环境
uninstall_advice() {
    echo -e "${RED}如果您已经安装了其他面板或者LDNMP建站环境，建议先卸载，再安装 npm！${NC}"
    pause
}

# 用户确认
confirm_action() {
    echo -e "${RED}你确定要继续吗？（y/n）${NC}"
    read confirmation
    if [[ $confirmation != "y" && $confirmation != "Y" ]]; then
        echo -e "${GREEN}操作已取消。${NC}"
        return 1
    fi
    return 0
}

# 安装 Nginx Proxy Manager
install_nginx_proxy_manager() {
    uninstall_advice
    if ! confirm_action; then return; fi
    echo -e "${GREEN}开始安装 Nginx Proxy Manager...${NC}"
    # 安装命令：使用 docker 安装 Nginx Proxy Manager
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
    if ! confirm_action; then return; fi
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
    if ! confirm_action; then return; fi
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
    echo -e "${GREEN}Nginx Proxy Manager 管理菜单${NC}"
    echo "1. 安装"
    echo "2. 更新"
    echo "3. 卸载"
    echo "4. 添加域名访问"
    echo "5. 删除域名访问"
    echo "6. 允许IP+端口访问"
    echo "7. 阻止IP+端口访问"
    echo "0. 返回上一级选单"
    read -p "请输入选项编号: " choice
    case $choice in
        1)
            install_nginx_proxy_manager
            ;;
        2)
            update_nginx_proxy_manager
            ;;
        3)
            uninstall_nginx_proxy_manager
            ;;
        4)
            add_domain_access
            ;;
        5)
            delete_domain_access
            ;;
        6)
            allow_ip_port_access
            ;;
        7)
            block_ip_port_access
            ;;
        0)
            echo "返回上一级选单"
            return
            ;;
        *)
            echo "无效输入，请重试。"
            ;;
    esac
}

# 欢迎信息
show_intro

# 主程序入口
while true; do
    show_menu
done

