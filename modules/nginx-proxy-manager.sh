#!/bin/bash

# Nginx Proxy Manager 管理脚本
# 支持多系统(Debian/Ubuntu/CentOS/Alpine)
# 原生版和Docker版共存

# 设置颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无色

# 全局变量
NPM_DIR="/opt/nginx-proxy-manager"
DEFAULT_PORT=81
LOG_FILE="/var/log/npm-install.log"
OS=""
PM2_PATH="/usr/bin/pm2"

# 初始化日志
init_log() {
    echo "=== Nginx Proxy Manager 安装日志 ===" > "$LOG_FILE"
    date >> "$LOG_FILE"
    echo "操作系统: $(uname -a)" >> "$LOG_FILE"
}

# 记录日志
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 检测操作系统
detect_os() {
    if [ -f /etc/alpine-release ]; then
        OS="alpine"
    elif [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
        OS="centos"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        OS="unknown"
    fi
    log "检测到操作系统: $OS"
}

# 安装必要依赖
install_dependencies() {
    log "开始安装系统依赖"
    case "$OS" in
        debian|ubuntu)
            apt-get update >> "$LOG_FILE" 2>&1
            apt-get install -y curl ufw sudo git nginx openssl >> "$LOG_FILE" 2>&1
            ;;
        centos)
            yum install -y curl ufw sudo git nginx openssl >> "$LOG_FILE" 2>&1
            ;;
        alpine)
            apk add --no-cache curl ufw sudo git nginx openssl >> "$LOG_FILE" 2>&1
            ;;
        *)
            echo -e "${RED}不支持的操作系统!${NC}"
            exit 1
            ;;
    esac
    
    if [ $? -ne 0 ]; then
        log "依赖安装失败"
        echo -e "${RED}依赖安装失败，请检查日志: $LOG_FILE${NC}"
        exit 1
    fi
    log "系统依赖安装完成"
}

# 安装Node.js
install_nodejs() {
    log "开始安装Node.js"
    if command -v node >/dev/null 2>&1; then
        log "Node.js 已安装，跳过安装"
        return 0
    fi

    case "$OS" in
        debian|ubuntu)
            curl -fsSL https://deb.nodesource.com/setup_16.x | bash - >> "$LOG_FILE" 2>&1
            apt-get install -y nodejs >> "$LOG_FILE" 2>&1
            ;;
        centos)
            curl -fsSL https://rpm.nodesource.com/setup_16.x | bash - >> "$LOG_FILE" 2>&1
            yum install -y nodejs >> "$LOG_FILE" 2>&1
            ;;
        alpine)
            apk add --no-cache nodejs npm >> "$LOG_FILE" 2>&1
            ;;
    esac

    if ! command -v node >/dev/null 2>&1; then
        log "Node.js 安装失败"
        echo -e "${RED}Node.js 安装失败!${NC}"
        exit 1
    fi
    log "Node.js 安装完成"
}

# 安装PM2进程管理器
install_pm2() {
    log "开始安装PM2"
    if command -v pm2 >/dev/null 2>&1; then
        log "PM2 已安装，跳过安装"
        return 0
    fi

    npm install -g pm2 >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "PM2 安装失败"
        echo -e "${RED}PM2 安装失败!${NC}"
        exit 1
    fi
    
    # 创建符号链接确保全局可用
    if [ ! -f "$PM2_PATH" ]; then
        ln -s "$(which pm2)" "$PM2_PATH" >> "$LOG_FILE" 2>&1
    fi
    log "PM2 安装完成"
}

# 检查端口是否可用
check_port() {
    local port=$1
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":$port "; then
            return 1
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -tuln | grep -q ":$port "; then
            return 1
        fi
    fi
    return 0
}

# 设置防火墙
setup_firewall() {
    local port=$1
    log "设置防火墙，开放端口: $port"
    
    case "$OS" in
        debian|ubuntu|centos)
            if ! command -v ufw >/dev/null 2>&1; then
                log "ufw 未安装，尝试安装"
                case "$OS" in
                    centos)
                        yum install -y ufw >> "$LOG_FILE" 2>&1
                        ;;
                    *)
                        apt-get install -y ufw >> "$LOG_FILE" 2>&1
                        ;;
                esac
                systemctl enable ufw >> "$LOG_FILE" 2>&1
                systemctl start ufw >> "$LOG_FILE" 2>&1
            fi
            
            ufw allow "$port/tcp" >> "$LOG_FILE" 2>&1
            ufw --force enable >> "$LOG_FILE" 2>&1
            ufw reload >> "$LOG_FILE" 2>&1
            ;;
        alpine)
            iptables -A INPUT -p tcp --dport "$port" -j ACCEPT >> "$LOG_FILE" 2>&1
            service iptables save >> "$LOG_FILE" 2>&1
            ;;
    esac
    log "防火墙设置完成"
}

# 安装Nginx Proxy Manager原生版
install_npm_native() {
    echo -e "${GREEN}开始安装Nginx Proxy Manager(原生版)...${NC}"
    log "开始原生版安装"
    
    # 获取安装端口
    local port
    while true; do
        read -p "请输入管理端口[默认$DEFAULT_PORT]: " port
        port=${port:-$DEFAULT_PORT}
        
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo -e "${RED}端口号必须是1-65535之间的数字!${NC}"
            continue
        fi
        
        if ! check_port "$port"; then
            echo -e "${RED}端口 $port 已被占用，请选择其他端口!${NC}"
            continue
        fi
        break
    done
    
    # 安装依赖
    detect_os
    install_dependencies
    install_nodejs
    install_pm2
    
    # 创建目录
    mkdir -p "$NPM_DIR" >> "$LOG_FILE" 2>&1
    cd "$NPM_DIR" >> "$LOG_FILE" 2>&1
    
    # 克隆仓库
    log "克隆NPM仓库"
    if [ ! -d "$NPM_DIR/.git" ]; then
        git clone https://github.com/jc21/nginx-proxy-manager.git . >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            echo -e "${RED}克隆仓库失败!${NC}"
            log "克隆仓库失败"
            exit 1
        fi
    else
        git pull origin master >> "$LOG_FILE" 2>&1
    fi
    
    # 安装依赖
    log "安装NPM依赖"
    npm install --production >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}npm依赖安装失败!${NC}"
        log "npm依赖安装失败"
        exit 1
    fi
    
    # 复制配置文件
    if [ -f "config/production.json.sample" ]; then
        cp config/production.json.sample config/production.json >> "$LOG_FILE" 2>&1
    fi
    
    # 配置Nginx反向代理
    log "配置Nginx反向代理"
    cat > /etc/nginx/conf.d/npm.conf <<EOL
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL
    
    # 测试并重启Nginx
    nginx -t >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}Nginx配置测试失败!${NC}"
        log "Nginx配置测试失败"
        exit 1
    fi
    
    systemctl restart nginx >> "$LOG_FILE" 2>&1
    
    # 设置防火墙
    setup_firewall "$port"
    
    # 启动应用
    log "启动NPM应用"
    pm2 start --name nginx-proxy-manager npm -- start >> "$LOG_FILE" 2>&1
    pm2 save >> "$LOG_FILE" 2>&1
    pm2 startup >> "$LOG_FILE" 2>&1
    
    echo -e "${GREEN}安装完成!${NC}"
    echo -e "${YELLOW}访问地址: http://你的服务器IP:$port${NC}"
    echo -e "${YELLOW}默认账号: admin@example.com${NC}"
    echo -e "${YELLOW}默认密码: changeme${NC}"
    log "原生版安装完成"
    pause
}

# 安装Docker
install_docker() {
    log "开始安装Docker"
    if command -v docker >/dev/null 2>&1; then
        log "Docker 已安装，跳过安装"
        return 0
    fi
    
    case "$OS" in
        debian|ubuntu)
            apt-get install -y apt-transport-https ca-certificates curl software-properties-common >> "$LOG_FILE" 2>&1
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - >> "$LOG_FILE" 2>&1
            add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >> "$LOG_FILE" 2>&1
            apt-get update >> "$LOG_FILE" 2>&1
            apt-get install -y docker-ce docker-ce-cli containerd.io >> "$LOG_FILE" 2>&1
            ;;
        centos)
            yum install -y yum-utils >> "$LOG_FILE" 2>&1
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >> "$LOG_FILE" 2>&1
            yum install -y docker-ce docker-ce-cli containerd.io >> "$LOG_FILE" 2>&1
            ;;
        alpine)
            apk add --no-cache docker >> "$LOG_FILE" 2>&1
            ;;
    esac
    
    systemctl enable docker >> "$LOG_FILE" 2>&1
    systemctl start docker >> "$LOG_FILE" 2>&1
    
    if ! command -v docker >/dev/null 2>&1; then
        log "Docker 安装失败"
        echo -e "${RED}Docker安装失败!${NC}"
        exit 1
    fi
    log "Docker 安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    log "开始安装Docker Compose"
    if command -v docker-compose >/dev/null 2>&1; then
        log "Docker Compose 已安装，跳过安装"
        return 0
    fi
    
    local compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
    chmod +x /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose >> "$LOG_FILE" 2>&1
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        log "Docker Compose 安装失败"
        echo -e "${RED}Docker Compose安装失败!${NC}"
        exit 1
    fi
    log "Docker Compose 安装完成"
}

# 安装Nginx Proxy Manager Docker版
install_npm_docker() {
    echo -e "${GREEN}开始安装Nginx Proxy Manager(Docker版)...${NC}"
    log "开始Docker版安装"
    
    # 获取安装端口
    local port
    while true; do
        read -p "请输入管理端口[默认$DEFAULT_PORT]: " port
        port=${port:-$DEFAULT_PORT}
        
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo -e "${RED}端口号必须是1-65535之间的数字!${NC}"
            continue
        fi
        
        if ! check_port "$port"; then
            echo -e "${RED}端口 $port 已被占用，请选择其他端口!${NC}"
            continue
        fi
        break
    done
    
    # 安装Docker和Docker Compose
    detect_os
    install_docker
    install_docker_compose
    
    # 创建目录结构
    mkdir -p "$NPM_DIR/data" "$NPM_DIR/letsencrypt" >> "$LOG_FILE" 2>&1
    
    # 创建docker-compose文件
    log "创建docker-compose.yml"
    cat > "$NPM_DIR/docker-compose.yml" <<EOL
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '$port:$port'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    environment:
      DISABLE_IPV6: 'true'
EOL
    
    # 启动服务
    log "启动Docker容器"
    cd "$NPM_DIR" >> "$LOG_FILE" 2>&1
    docker-compose up -d >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Docker容器启动失败!${NC}"
        log "Docker容器启动失败"
        exit 1
    fi
    
    # 设置防火墙
    setup_firewall "$port"
    
    echo -e "${GREEN}安装完成!${NC}"
    echo -e "${YELLOW}访问地址: http://你的服务器IP:$port${NC}"
    echo -e "${YELLOW}默认账号: admin@example.com${NC}"
    echo -e "${YELLOW}默认密码: changeme${NC}"
    log "Docker版安装完成"
    pause
}

# 更新Nginx Proxy Manager原生版
update_npm_native() {
    echo -e "${GREEN}更新Nginx Proxy Manager(原生版)...${NC}"
    log "开始原生版更新"
    
    if [ ! -d "$NPM_DIR" ]; then
        echo -e "${RED}未找到Nginx Proxy Manager安装目录!${NC}"
        log "更新失败，未找到安装目录"
        pause
        return
    fi
    
    cd "$NPM_DIR" >> "$LOG_FILE" 2>&1
    
    # 停止运行中的进程
    pm2 stop nginx-proxy-manager >> "$LOG_FILE" 2>&1
    
    # 更新代码
    git pull origin master >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}代码更新失败!${NC}"
        log "代码更新失败"
        pause
        return
    fi
    
    # 更新依赖
    npm install --production >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}依赖更新失败!${NC}"
        log "依赖更新失败"
        pause
        return
    fi
    
    # 重启应用
    pm2 restart nginx-proxy-manager >> "$LOG_FILE" 2>&1
    
    echo -e "${GREEN}更新完成!${NC}"
    log "原生版更新完成"
    pause
}

# 更新Nginx Proxy Manager Docker版
update_npm_docker() {
    echo -e "${GREEN}更新Nginx Proxy Manager(Docker版)...${NC}"
    log "开始Docker版更新"
    
    if [ ! -f "$NPM_DIR/docker-compose.yml" ]; then
        echo -e "${RED}未找到docker-compose.yml文件!${NC}"
        log "更新失败，未找到docker-compose.yml"
        pause
        return
    fi
    
    cd "$NPM_DIR" >> "$LOG_FILE" 2>&1
    
    # 拉取最新镜像并重启容器
    docker-compose pull >> "$LOG_FILE" 2>&1
    docker-compose up -d --force-recreate >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}更新失败!${NC}"
        log "Docker版更新失败"
    else
        echo -e "${GREEN}更新完成!${NC}"
        log "Docker版更新完成"
    fi
    
    pause
}

# 卸载Nginx Proxy Manager原生版
uninstall_npm_native() {
    echo -e "${RED}准备卸载Nginx Proxy Manager(原生版)...${NC}"
    log "开始原生版卸载"
    
    if ! confirm_action "确定要卸载Nginx Proxy Manager(原生版)吗？(y/n)"; then
        log "用户取消卸载"
        return
    fi
    
    # 获取使用的端口
    local port=$(grep -oP "proxy_pass http://127.0.0.1:\K\d+" /etc/nginx/conf.d/npm.conf 2>/dev/null || echo "$DEFAULT_PORT")
    
    # 停止并删除PM2进程
    if command -v pm2 >/dev/null 2>&1; then
        pm2 delete nginx-proxy-manager >> "$LOG_FILE" 2>&1
        pm2 save >> "$LOG_FILE" 2>&1
    fi
    
    # 删除Nginx配置
    if [ -f "/etc/nginx/conf.d/npm.conf" ]; then
        rm -f /etc/nginx/conf.d/npm.conf >> "$LOG_FILE" 2>&1
        nginx -t && systemctl restart nginx >> "$LOG_FILE" 2>&1
    fi
    
    # 删除安装目录
    if [ -d "$NPM_DIR" ]; then
        rm -rf "$NPM_DIR" >> "$LOG_FILE" 2>&1
    fi
    
    # 清理防火墙规则
    case "$OS" in
        debian|ubuntu|centos)
            ufw delete allow "$port/tcp" >> "$LOG_FILE" 2>&1
            ufw reload >> "$LOG_FILE" 2>&1
            ;;
        alpine)
            iptables -D INPUT -p tcp --dport "$port" -j ACCEPT >> "$LOG_FILE" 2>&1
            service iptables save >> "$LOG_FILE" 2>&1
            ;;
    esac
    
    echo -e "${GREEN}卸载完成!${NC}"
    log "原生版卸载完成"
    pause
}

# 卸载Nginx Proxy Manager Docker版
uninstall_npm_docker() {
    echo -e "${RED}准备卸载Nginx Proxy Manager(Docker版)...${NC}"
    log "开始Docker版卸载"
    
    if ! confirm_action "确定要卸载Nginx Proxy Manager(Docker版)吗？(y/n)"; then
        log "用户取消卸载"
        return
    fi
    
    # 获取使用的端口
    local port=$(grep -oP "'\K$DEFAULT_PORT(?=:$DEFAULT_PORT')" "$NPM_DIR/docker-compose.yml" 2>/dev/null || echo "$DEFAULT_PORT")
    
    # 停止并删除容器
    if [ -f "$NPM_DIR/docker-compose.yml" ]; then
        cd "$NPM_DIR" >> "$LOG_FILE" 2>&1
        docker-compose down -v >> "$LOG_FILE" 2>&1
    fi
    
    # 删除安装目录
    if [ -d "$NPM_DIR" ]; then
        rm -rf "$NPM_DIR" >> "$LOG_FILE" 2>&1
    fi
    
    # 清理防火墙规则
    case "$OS" in
        debian|ubuntu|centos)
            ufw delete allow "$port/tcp" >> "$LOG_FILE" 2>&1
            ufw reload >> "$LOG_FILE" 2>&1
            ;;
        alpine)
            iptables -D INPUT -p tcp --dport "$port" -j ACCEPT >> "$LOG_FILE" 2>&1
            service iptables save >> "$LOG_FILE" 2>&1
            ;;
    esac
    
    echo -e "${GREEN}卸载完成!${NC}"
    log "Docker版卸载完成"
    pause
}

# 显示状态
show_status() {
    echo -e "${GREEN}当前Nginx Proxy Manager状态:${NC}"
    
    # 检查原生版运行状态
    if [ -d "$NPM_DIR" ] && [ ! -f "$NPM_DIR/docker-compose.yml" ]; then
        if pm2 list | grep -q nginx-proxy-manager; then
            echo -e "原生版状态: ${GREEN}运行中${NC}"
            pm2 info nginx-proxy-manager | grep -E 'status|uptime'
        else
            echo -e "原生版状态: ${RED}未运行${NC}"
        fi
    fi
    
    # 检查Docker版运行状态
    if [ -f "$NPM_DIR/docker-compose.yml" ]; then
        cd "$NPM_DIR" >> "$LOG_FILE" 2>&1
        if docker-compose ps | grep -q app; then
            echo -e "Docker版状态: ${GREEN}运行中${NC}"
            docker-compose ps
        else
            echo -e "Docker版状态: ${RED}未运行${NC}"
        fi
    fi
    
    # 检查端口监听情况
    echo -e "\n${GREEN}端口监听情况:${NC}"
    if command -v ss >/dev/null 2>&1; then
        ss -tulnp | grep -E '80|443|81'
    else
        netstat -tulnp | grep -E '80|443|81'
    fi
    
    pause
}

# 用户确认
confirm_action() {
    local prompt=${1:-"确定要继续吗？(y/n)"}
    echo -e "${RED}${prompt}${NC}"
    read -r confirmation
    if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
        return 1
    fi
    return 0
}

# 显示暂停，按任意键继续
pause() {
    echo -e "${GREEN}按任意键继续...${NC}"
    read -n 1 -s -r
    echo
}

# 显示菜单
show_menu() {
    clear
    echo -e "${GREEN}Nginx Proxy Manager 管理脚本${NC}"
    echo -e "${GREEN}===========================${NC}"
    echo -e "操作系统: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
    echo -e "脚本版本: 2.0"
    echo -e "日志文件: $LOG_FILE"
    echo -e "${GREEN}===========================${NC}"
    
    # 显示安装状态
    if [ -d "$NPM_DIR" ]; then
        if [ -f "$NPM_DIR/docker-compose.yml" ]; then
            echo -e "当前安装: ${GREEN}Docker版${NC}"
        else
            echo -e "当前安装: ${GREEN}原生版${NC}"
        fi
    else
        echo -e "当前安装: ${RED}未检测到${NC}"
    fi
    
    echo -e "${GREEN}请选择操作:${NC}"
    echo "1. 安装原生版"
    echo "2. 更新原生版"
    echo "3. 卸载原生版"
    echo "4. 安装Docker版"
    echo "5. 更新Docker版"
    echo "6. 卸载Docker版"
    echo "7. 查看状态"
    echo "0. 退出"
    echo "========================"
    read -p "请输入选项: " option
    case $option in
        1) install_npm_native ;;
        2) update_npm_native ;;
        3) uninstall_npm_native ;;
        4) install_npm_docker ;;
        5) update_npm_docker ;;
        6) uninstall_npm_docker ;;
        7) show_status ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项!${NC}"; sleep 1; show_menu ;;
    esac
}

# 主程序入口
init_log
detect_os
while true; do
    show_menu
done

