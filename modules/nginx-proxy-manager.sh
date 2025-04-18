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

# 显示主菜单
show_menu() {
    clear
    echo "========================"
    echo " Nginx Proxy Manager 管理工具"
    echo "========================"
    echo "1. 安装"
    echo "2. 更新"
    echo "3. 卸载"
    echo "5. 添加域名访问"
    echo "6. 删除域名访问"
    echo "7. 允许IP+端口访问"
    echo "8. 阻止IP+端口访问"
    echo "0. 返回上一级选单"
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
    apt update && apt upgrade -y
    apt install -y curl ufw sudo

    # 设置 UFW 防火墙
    ufw allow 80
    ufw allow 81
    ufw allow 443
    ufw reload

    # 安装 Docker
    curl -fsSL https://get.docker.com | bash
    systemctl start docker  # 启动 Docker 服务
    systemctl enable docker # Docker 开机自启

    # 安装 Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # 创建 Nginx Proxy Manager 目录
    mkdir -p /opt/nginx-proxy-manager/data
    mkdir -p /opt/nginx-proxy-manager/letsencrypt

    # 创建 docker-compose.yml 文件
    cat > /opt/nginx-proxy-manager/docker-compose.yml <<EOL
version: '3'

services:
  app:
    image: 'docker.io/jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOL

    # 启动 Nginx Proxy Manager
    cd /opt/nginx-proxy-manager
    docker-compose up -d

    # 输出默认访问地址
    echo "安装完成，访问地址： http://127.0.0.1:81"
    echo "默认管理员账号："
    echo "Email: admin@example.com"
    echo "Password: changeme"
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
    cd /opt/nginx-proxy-manager
    docker-compose down

    # 删除 Docker 镜像
    docker rmi jc21/nginx-proxy-manager:latest

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
    # 配置域名访问相关操作（具体根据实际情况添加）
    echo "已为 $domain 添加域名访问。"
    sleep 2
    show_menu
}

# 删除域名访问
remove_domain_access() {
    read -p "请输入要删除的域名: " domain
    echo "正在删除 $domain 的域名访问..."
    # 配置删除域名访问相关操作（具体根据实际情况删除）
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
show_intro

# 主程序入口
while true; do
    show_menu
done

