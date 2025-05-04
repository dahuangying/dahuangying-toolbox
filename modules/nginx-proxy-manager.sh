#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
NC='\033[0m' # 无色
RED='\033[0;31m'

# 全局变量
NPM_DIR="/opt/nginx-proxy-manager"
DEFAULT_PORT=81

# 显示暂停，按任意键继续
pause() {
    echo -e "${GREEN}操作完成，按任意键继续...${NC}"
    read -n 1 -s -r
    echo
}

# 判断 Nginx Proxy Manager 是否已安装
check_nginx_installed() {
    if [ -d "$NPM_DIR" ]; then
        return 0  # 已安装
    else
        return 1  # 未安装
    fi
}

# 用户确认
confirm_action() {
    local prompt=${1:-"你确定要继续吗？（y/n）"}
    echo -e "${RED}${prompt}${NC}"
    read confirmation
    if [[ $confirmation != "y" && $confirmation != "Y" ]]; then
        echo -e "${GREEN}操作已取消。${NC}"
        return 1
    fi
    return 0
}

# 清理防火墙规则
remove_firewall_rules() {
    local port=${1:-$DEFAULT_PORT}
    echo -e "${GREEN}正在移除防火墙规则...${NC}"
    ufw status | grep -q "$port" && ufw delete allow "$port"
    ufw reload
    echo -e "${GREEN}防火墙规则已移除。${NC}"
}

# 安装 Nginx Proxy Manager
install_nginx_proxy_manager() {
    echo "正在安装 Nginx Proxy Manager..."

    # 设置防火墙
    read -p "请输入应用对外服务端口，回车默认使用${DEFAULT_PORT}端口: " port
    port=${port:-$DEFAULT_PORT}
    ufw allow "$port"
    ufw reload

    # 更新系统
    if ! apt update && apt upgrade -y; then
        echo -e "${RED}系统更新失败，请检查网络连接!${NC}"
        return 1
    fi
    
    # 安装依赖
    if ! apt install -y curl ufw sudo nginx git; then
        echo -e "${RED}依赖安装失败!${NC}"
        return 1
    fi

    # 启动 Nginx 服务并设置自启动
    systemctl start nginx
    systemctl enable nginx

    # 安装 Node.js
    if ! curl -fsSL https://deb.nodesource.com/setup_14.x | bash -; then
        echo -e "${RED}Node.js 源添加失败!${NC}"
        return 1
    fi
    
    if ! apt install -y nodejs build-essential; then
        echo -e "${RED}Node.js 安装失败!${NC}"
        return 1
    fi

    # 获取 Nginx Proxy Manager 源代码
    mkdir -p "$NPM_DIR"
    if ! git clone https://github.com/jc21/nginx-proxy-manager.git "$NPM_DIR"; then
        echo -e "${RED}克隆 Nginx Proxy Manager 仓库失败!${NC}"
        return 1
    fi

    cd "$NPM_DIR" || return 1

    # 安装 Node.js 依赖
    if ! npm install --production; then
        echo -e "${RED}npm 依赖安装失败!${NC}"
        return 1
    fi

    # 配置 Nginx Proxy Manager
    if [ -f "config/production.json.sample" ]; then
        cp config/production.json.sample config/production.json
    fi

    # 配置 Nginx 为反向代理
    cat > /etc/nginx/sites-available/nginx-proxy-manager <<EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:${port}/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

    # 启用 Nginx 配置并重启服务
    ln -sf /etc/nginx/sites-available/nginx-proxy-manager /etc/nginx/sites-enabled/
    nginx -t && systemctl restart nginx

    # 启动 Nginx Proxy Manager (建议使用PM2等进程管理工具)
    nohup npm run start > "$NPM_DIR/npm.log" 2>&1 &

    echo -e "${GREEN}安装完成，请访问地址：http://[你的服务器IP]:${port}${NC}"
    echo -e "${GREEN}初始用户名: admin@example.com${NC}"
    echo -e "${GREEN}初始密码: changeme${NC}"
    echo -e "${GREEN}日志文件: ${NPM_DIR}/npm.log${NC}"
    pause
}

# 更新 Nginx Proxy Manager
update_nginx_proxy_manager() {
    if [ ! -d "$NPM_DIR" ]; then
        echo -e "${RED}Nginx Proxy Manager 未安装，请先安装!${NC}"
        pause
        return 1
    fi

    echo "正在更新 Nginx Proxy Manager..."
    cd "$NPM_DIR" || return 1
    
    # 停止运行中的进程
    pkill -f "npm run start"
    
    if ! git pull origin master; then
        echo -e "${RED}更新代码失败!${NC}"
        return 1
    fi
    
    if ! npm install --production; then
        echo -e "${RED}npm 依赖更新失败!${NC}"
        return 1
    fi
    
    systemctl restart nginx
    nohup npm run start > "$NPM_DIR/npm.log" 2>&1 &
    
    echo -e "${GREEN}更新完成!${NC}"
    pause
}

# 卸载 Nginx Proxy Manager
uninstall_nginx_proxy_manager() {
    if [ ! -d "$NPM_DIR" ]; then
        echo -e "${RED}Nginx Proxy Manager 未安装!${NC}"
        pause
        return 1
    fi

    confirm_action "你确定要卸载 Nginx Proxy Manager 吗？（y/n）" || return 0

    # 停止进程
    echo -e "${GREEN}正在停止 Nginx Proxy Manager 服务...${NC}"
    pkill -f "npm run start"

    # 获取使用的端口
    local port=$(grep -oP "proxy_pass http://localhost:\K\d+" /etc/nginx/sites-available/nginx-proxy-manager 2>/dev/null || echo "$DEFAULT_PORT")

    # 删除文件和依赖
    echo -e "${GREEN}正在删除 Nginx Proxy Manager 文件和依赖...${NC}"
    rm -rf "$NPM_DIR"
    
    # 只移除我们创建的Nginx配置
    echo -e "${GREEN}正在删除 Nginx 配置...${NC}"
    rm -f /etc/nginx/sites-available/nginx-proxy-manager
    rm -f /etc/nginx/sites-enabled/nginx-proxy-manager
    nginx -t && systemctl restart nginx

    # 清理防火墙规则
    remove_firewall_rules "$port"

    echo -e "${GREEN}Nginx Proxy Manager 已成功卸载。${NC}"
    pause
}

# 安装 Nginx Proxy Manager_Docker
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

# 更新 Nginx Proxy Manager_Docker
update_nginx_proxy_manager_Docker() {
    echo "正在更新 Nginx Proxy Manager..."
    cd /opt/nginx-proxy-manager
    docker-compose pull
    docker-compose up -d
    echo "更新完成！"
    sleep 2
    show_menu
}

# 卸载 Nginx Proxy Manager
uninstall_nginx_proxy_manager_Docker() {
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
}

# 显示菜单
show_menu() {
    clear
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱菜单-Nginx${NC}"
    echo -e "${GREEN}==================================${NC}"
    if check_nginx_installed; then
        echo -e "Nginx Proxy Manager 状态: ${GREEN}已安装${NC}"
    else
        echo -e "Nginx Proxy Manager 状态: ${RED}未安装${NC}"
    fi
    echo -e "${GREEN}==================================${NC}"
    echo -e "请选择操作："
    echo "1. 安装b"
    echo "2. 更新"
    echo "3. 卸载"
    echo "4. 安装Docker版"
    echo "5. 更新Docker版"
    echo "6. 卸载Docker版"
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
        *) echo -e "${RED}无效选项，请重新选择!${NC}" ; sleep 1 ; show_menu ;;
    esac
}

# 主程序入口
while true; do
    show_menu
done

