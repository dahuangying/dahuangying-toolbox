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

# 判断 Nginx Proxy Manager 是否已安装
check_nginx_installed() {
    if [ -d "/opt/nginx-proxy-manager" ]; then
        return 0  # 已安装
    else
        return 1  # 未安装
    fi
}

# Nginx菜单
show_menu() {
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱菜单-Nginx${NC}"
    clear
    echo -e "${GREEN}==================================${NC}"
    if check_nginx_installed; then
        echo "Nginx Proxy Manager 已安装"
    else
        echo "Nginx Proxy Manager 未安装"
    fi
    echo -e "${GREEN}==================================${NC}"
    echo -e "欢迎使用本脚本，请根据菜单选择操作："
    echo "=================================="
    echo "1. 安装"
    echo "2. 更新"
    echo "3. 卸载"
    echo "0. 退出"
    echo "========================"
    read -p "请输入选项: " option
    case $option in
        1) install_nginx_proxy_manager ;;
        2) update_nginx_proxy_manager ;;
        3) uninstall_nginx_proxy_manager ;;
        0) exit 0 ;;
        *) echo "无效选项，请重新选择！" ; sleep 2 ; show_menu ;;
    esac
}

# 安装 Nginx Proxy Manager
install_nginx_proxy_manager() {
    echo "正在安装 Nginx Proxy Manager..."

    # 设置防火墙
    read -p "请输入应用对外服务端口，回车默认使用81端口: " port
    port=${port:-81}
    ufw allow $port
    ufw reload

    # 安装 Docker 和 Docker Compose
    apt update && apt upgrade -y
    apt install -y curl ufw sudo
    curl -fsSL https://get.docker.com | bash
    systemctl start docker
    systemctl enable docker

    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # 创建目录并配置 Docker Compose
    mkdir -p /opt/nginx-proxy-manager/data
    mkdir -p /opt/nginx-proxy-manager/letsencrypt
    cat > /opt/nginx-proxy-manager/docker-compose.yml <<EOL
version: '3'

services:
  app:
    image: 'docker.io/jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - "80:80"
      - "$port:$port"
      - "443:443"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOL

    # 启动服务
    cd /opt/nginx-proxy-manager
    docker-compose up -d

    # 输出安装完成的提示
    echo -e "${GREEN}安装完成，请访问地址：http://【你的服务器IP】:${port}${NC}"
    echo -e "${GREEN}初始用户名: admin@example.com${NC}"
    echo -e "${GREEN}初始密码: changeme${NC}"
    sleep 2
    pause
}

# 更新 Nginx Proxy Manager
update_nginx_proxy_manager() {
    echo "正在更新 Nginx Proxy Manager..."
    cd /opt/nginx-proxy-manager
    docker-compose pull
    docker-compose up -d
    echo "更新完成！"
    sleep 2
    pause
}

# 卸载 Nginx Proxy Manager
uninstall_nginx_proxy_manager() {
    confirm_action
    if [ $? -eq 0 ]; then
        remove_container
        remove_image
        remove_files
        remove_firewall_rules
        echo -e "${GREEN}Nginx Proxy Manager 已成功卸载。${NC}"
    else
        echo -e "${GREEN}卸载操作已取消。${NC}"
    fi
}

# 用户确认
confirm_action() {
    echo -e "${RED}你确定要卸载 Nginx Proxy Manager 吗？（y/n）${NC}"
    read confirmation
    if [[ $confirmation != "y" && $confirmation != "Y" ]]; then
        echo -e "${GREEN}操作已取消。${NC}"
        return 1
    fi
    return 0
}

# 停止并删除容器
remove_container() {
    container_id=$(docker ps -a -q --filter "name=nginx-proxy-manager")
    if [ -n "$container_id" ]; then
        echo -e "${GREEN}正在停止并删除容器...${NC}"
        docker stop $container_id
        docker rm $container_id
    else
        echo -e "${GREEN}未找到 Nginx Proxy Manager 容器，无需删除。${NC}"
    fi
}

# 删除镜像
remove_image() {
    image_id=$(docker images -q "jc21/nginx-proxy-manager")
    if [ -n "$image_id" ]; then
        echo -e "${GREEN}正在删除镜像...${NC}"
        docker rmi -f $image_id
    else
        echo -e "${GREEN}未找到 Nginx Proxy Manager 镜像，无需删除。${NC}"
    fi
}

# 删除 Docker Compose 配置和数据
remove_files() {
    echo -e "${GREEN}正在删除 Docker Compose 配置和数据文件...${NC}"
    rm -rf /opt/nginx-proxy-manager
    echo -e "${GREEN}配置和数据文件已删除。${NC}"
}

# 清理防火墙规则
remove_firewall_rules() {
    echo -e "${GREEN}正在移除防火墙规则...${NC}"
    ufw status | grep -E '80|443|81' && ufw delete allow 80 && ufw delete allow 443 && ufw delete allow 81
    ufw reload
    echo -e "${GREEN}防火墙规则已移除。${NC}"
    pause
}

# 欢迎信息
show_intro() {
    echo -e "${GREEN}欢迎使用 Nginx Proxy Manager 反代脚本${NC}"
}

# 主程序入口
while true; do
    show_menu
done
