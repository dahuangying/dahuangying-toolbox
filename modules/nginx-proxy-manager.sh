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
    echo "4. 安装 Docker 版"
    echo "5. 更新 Docker 版"
    echo "6. 卸载 Docker 版"
    echo "0. 退出"
    echo "========================"
    read -p "请输入选项: " option
    case $option in
        1) install_nginx_proxy_manager ;;
        2) update_nginx_proxy_manager ;;
        3) uninstall_nginx_proxy_manager ;;
        4) install_nginx_proxy_manager_Docker ;;
        5) update_nginx_proxy_manager_Docker ;;
        6) uninstall_nginx_proxy_manager_Docker ;;     
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

    # 更新系统
    apt update && apt upgrade -y
    apt install -y curl ufw sudo nginx

    # 启动 Nginx 服务并设置自启动
    systemctl start nginx
    systemctl enable nginx

    # 安装 Nginx Proxy Manager 需要的 Node.js 和其他依赖
    curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
    apt install -y nodejs build-essential

    # 安装 Nginx Proxy Manager 的依赖
    apt install -y git

    # 获取 Nginx Proxy Manager 源代码
    cd /opt
    git clone https://github.com/jc21/nginx-proxy-manager.git
    cd nginx-proxy-manager

    # 安装 Node.js 依赖
    npm install --production

    # 配置 Nginx Proxy Manager
    cp /opt/nginx-proxy-manager/config/production.json.sample /opt/nginx-proxy-manager/config/production.json

    # 创建 Nginx 配置文件
    cat > /etc/nginx/sites-available/nginx-proxy-manager <<EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:81/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

    # 创建符号链接
    ln -s /etc/nginx/sites-available/nginx-proxy-manager /etc/nginx/sites-enabled/

    # 重启 Nginx 服务
    systemctl restart nginx

    # 启动 Nginx Proxy Manager
    npm run start

    # 输出安装完成的提示
    echo -e "${GREEN}安装完成，请访问地址：http://【你的服务器IP】:${port}${NC}"
    echo -e "${GREEN}初始用户名: admin@example.com${NC}"
    echo -e "${GREEN}初始密码: changeme${NC}"
    sleep 2
    show_menu
}

# 更新 Nginx Proxy Manager
update_nginx_proxy_manager() {
    echo "正在更新 Nginx Proxy Manager..."
    cd /opt/nginx-proxy-manager
    git pull origin master
    npm install --production
    systemctl restart nginx
    echo "更新完成！"
    sleep 2
    show_menu
}

# 卸载 Nginx Proxy Manager
uninstall_nginx_proxy_manager() {
    confirm_action
    if [ $? -eq 0 ]; then
        remove_service
        remove_files
        remove_nginx_config
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

# 停止并删除服务
remove_service() {
    echo -e "${GREEN}正在停止 Nginx Proxy Manager 服务...${NC}"
    pkill -f "npm run start"
}

# 删除文件和依赖
remove_files() {
    echo -e "${GREEN}正在删除 Nginx Proxy Manager 文件和依赖...${NC}"
    rm -rf /opt/nginx-proxy-manager
    apt remove --purge -y nodejs build-essential git
    echo -e "${GREEN}文件和依赖已删除。${NC}"
}

# 删除 Nginx 配置
remove_nginx_config() {
    echo -e "${GREEN}正在删除 Nginx 配置...${NC}"
    rm -f /etc/nginx/sites-available/nginx-proxy-manager
    rm -f /etc/nginx/sites-enabled/nginx-proxy-manager
    systemctl restart nginx
}

# 清理防火墙规则
remove_firewall_rules() {
    echo -e "${GREEN}正在移除防火墙规则...${NC}"
    ufw status | grep -E '80|443|81' && ufw delete allow 80 && ufw delete allow 443 && ufw delete allow 81
    ufw reload
    echo -e "${GREEN}防火墙规则已移除。${NC}"
}

# 安装 Nginx Proxy Manager Docker版
install_nginx_proxy_manager_Docker() {
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
    show_menu
}

# 更新 Nginx Proxy Manager Docker版
update_nginx_proxy_manager_Docker() {
    echo "正在更新 Nginx Proxy Manager..."
    cd /opt/nginx-proxy-manager
    docker-compose pull
    docker-compose up -d
    echo "更新完成！"
    sleep 2
    show_menu
}

# 卸载 Nginx Proxy Manager Docker版
uninstall_nginx_proxy_manager_Docker() {
    confirm_action
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}正在停止并移除容器...${NC}"
        cd /opt/nginx-proxy-manager
        docker-compose down
        rm -rf /opt/nginx-proxy-manager
        echo -e "${GREEN}Nginx Proxy Manager Docker 版已成功卸载。${NC}"
    else
        echo -e "${GREEN}卸载操作已取消。${NC}"
    fi
}

# 执行主菜单
show_menu

