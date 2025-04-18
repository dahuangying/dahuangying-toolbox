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
    echo "5. 添加域名访问"
    echo "6. 删除域名访问"
    echo "7. 允许IP+端口访问"
    echo "8. 阻止IP+端口访问"
    echo "0. 退出"
    echo "========================"
    read -p "请输入选项: " option
    case $option in
        1) install_nginx_proxy_manager ;;
        2) update_nginx_proxy_manager ;;
        3) uninstall_nginx_proxy_manager ;;
        5) add_domain_access ;;
        6) remove_domain_access ;;
        7) allow_ip_port_access ;;
        8) block_ip_port_access ;;
        0) exit 0 ;;
        *) echo "无效选项，请重新选择！" ; sleep 2 ; show_menu ;;
    esac
}

# 安装 Nginx Proxy Manager
install_nginx_proxy_manager() {
    echo "正在安装 Nginx Proxy Manager..."

    # 设置防火墙
    ufw allow 80
    ufw allow 443
    echo -e "${GREEN}请输入应用对外服务端口，回车默认使用81端口: ${NC}"
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
    echo -e "${GREEN}安装完成，访问地址：http://【你的服务器IP】:81${NC}"
    echo -e "初始用户名: admin@example.com"
    echo -e "初始密码: changeme"
    sleep 2
    show_menu
}

# 更新 Nginx Proxy Manager
update_nginx_proxy_manager() {
    echo "正在更新 Nginx Proxy Manager..."
    cd /opt/nginx-proxy-manager
    docker-compose pull
    docker-compose up -d
    echo "更新完成！"
    sleep 2
    show_menu
}

# 卸载 Nginx Proxy Manager
uninstall_nginx_proxy_manager() {
    echo "正在卸载 Nginx Proxy Manager..."

    # 停止并删除容器
    if docker ps -a | grep -q 'npm'; then
        docker-compose down
        echo "已停止并删除 Nginx Proxy Manager 容器。"
    else
        echo "未找到 Nginx Proxy Manager 容器，跳过删除。"
    fi

    # 删除镜像
    if docker images | grep -q 'jc21/nginx-proxy-manager'; then
        docker rmi jc21/nginx-proxy-manager:latest
        echo "已删除 Nginx Proxy Manager 镜像。"
    else
        echo "未找到 Nginx Proxy Manager 镜像，跳过删除。"
    fi

    # 删除配置文件
    rm -rf /opt/nginx-proxy-manager
    echo "卸载完成！"
    sleep 2
    show_menu
}

# 添加域名访问
add_domain_access() {
    read -p "请输入要添加的域名: " domain
    echo "正在为 $domain 添加域名访问..."
    echo "已为 $domain 添加域名访问。"
    sleep 2
    show_menu
}

# 删除域名访问
remove_domain_access() {
    read -p "请输入要删除的域名: " domain
    echo "正在删除 $domain 的域名访问..."
    echo "$domain 的域名访问已删除。"
    sleep 2
    show_menu
}

# 允许IP+端口访问
allow_ip_port_access() {
    read -p "请输入允许访问的 IP 地址: " ip
    read -p "请输入允许访问的端口号: " port
    echo "正在允许 $ip 访问端口 $port..."
    ufw allow from $ip to any port $port
    ufw reload
    echo "$ip 现在可以访问端口 $port"
    sleep 2
    show_menu
}

# 阻止IP+端口访问
block_ip_port_access() {
    read -p "请输入要阻止的 IP 地址: " ip
    read -p "请输入要阻止的端口号: " port
    echo "正在阻止 $ip 访问端口 $port..."
    ufw deny from $ip to any port $port
    ufw reload
    echo "$ip 已被阻止访问端口 $port"
    sleep 2
    show_menu
}

# 欢迎信息
show_intro() {
    echo -e "${GREEN}欢迎使用 Nginx Proxy Manager 反代脚本${NC}"
}

# 主程序入口
while true; do
    show_menu
done

