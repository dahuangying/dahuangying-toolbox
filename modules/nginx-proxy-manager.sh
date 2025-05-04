#!/bin/bash
# Nginx Proxy Manager 全功能管理脚本
# 功能：原生版 + Docker版安装/卸载 | 自动修复依赖
# 版本：v4.0

# ---------------------------- 全局配置 ----------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'
NPM_DIR="/opt/nginx-proxy-manager"
DEFAULT_PORT=81
NODE_VERSION="16"  # 推荐Node 16 LTS

# ------------------------ 系统检测函数 ------------------------
detect_system() {
    if command -v apt &>/dev/null; then
        PM="apt"
        OS="debian"
    elif command -v dnf &>/dev/null; then
        PM="dnf"
        OS="rhel"
    elif command -v yum &>/dev/null; then
        PM="yum"
        OS="rhel"
    else
        echo -e "${RED}❌ 不支持的Linux发行版！${NC}"
        exit 1
    fi
    ARCH=$(uname -m)
    [ "$ARCH" = "x86_64" ] && ARCH="amd64"
}

# ------------------------ 依赖管理函数 ------------------------
install_nodejs() {
    echo -e "${GREEN}▶ 正在安装Node.js ${NODE_VERSION}...${NC}"
    
    if [ "$OS" = "debian" ]; then
        # Debian备用方案
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - || {
            echo -e "${YELLOW}⚠ 使用备用Node.js源...${NC}"
            apt install -y ca-certificates curl gnupg
            mkdir -p /etc/apt/keyrings
            curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
            echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
            apt update
        }
        apt install -y nodejs
    else
        # RHEL备用方案
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash - || {
            echo -e "${YELLOW}⚠ 使用备用Node.js源...${NC}"
            $PM install -y https://rpm.nodesource.com/pub_${NODE_VERSION}.x/el/7/x86_64/nodejs-${NODE_VERSION}.x-1nodesource.x86_64.rpm
        }
    fi
    [ $? -eq 0 ] && echo -e "${GREEN}✔ Node.js安装成功${NC}" || {
        echo -e "${RED}❌ Node.js安装失败！${NC}"
        exit 1
    }
}

clean_firewall() {
    local port=${1:-$DEFAULT_PORT}
    echo -e "${GREEN}▶ 清理防火墙规则...${NC}"
    if command -v ufw &>/dev/null; then
        ufw delete allow $port/tcp 2>/dev/null
        ufw reload
    elif command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --remove-port=$port/tcp 2>/dev/null
        firewall-cmd --reload
    fi
}

# ------------------------ 原生版管理 ------------------------
install_native() {
    detect_system
    echo -e "${GREEN}▶ 开始安装原生版...${NC}"
    
    # 安装依赖
    $PM install -y curl git build-essential python3
    install_nodejs
    
    # 克隆仓库
    git clone https://github.com/jc21/nginx-proxy-manager.git $NPM_DIR || {
        echo -e "${RED}❌ 仓库克隆失败！${NC}"
        exit 1
    }
    
    # 安装依赖
    cd $NPM_DIR
    npm install --production || {
        echo -e "${RED}❌ npm依赖安装失败！${NC}"
        exit 1
    }

    # 配置服务
    cat > /etc/systemd/system/npm.service <<EOF
[Unit]
Description=Nginx Proxy Manager
After=network.target

[Service]
Type=simple
WorkingDirectory=$NPM_DIR
ExecStart=/usr/bin/node index.js
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now npm

    echo -e "${GREEN}✔ 原生版安装完成！访问 http://<IP>:${DEFAULT_PORT} ${NC}"
    echo -e "默认账号: ${YELLOW}admin@example.com${NC}"
    echo -e "默认密码: ${YELLOW}changeme${NC}"
}

uninstall_native() {
    echo -e "${RED}▶ 开始卸载原生版...${NC}"
    
    # 停止服务
    systemctl stop npm 2>/dev/null
    systemctl disable npm 2>/dev/null
    rm -f /etc/systemd/system/npm.service
    
    # 清理文件
    rm -rf $NPM_DIR
    
    # 清理防火墙
    clean_firewall $DEFAULT_PORT
    
    echo -e "${GREEN}✔ 原生版已完全卸载${NC}"
}

# ------------------------ Docker版管理 ------------------------
install_docker() {
    detect_system
    echo -e "${GREEN}▶ 开始安装Docker版...${NC}"
    
    # 安装Docker
    curl -fsSL https://get.docker.com | sh || {
        echo -e "${RED}❌ Docker安装失败！${NC}"
        exit 1
    }
    systemctl enable --now docker
    
    # 准备目录
    mkdir -p $NPM_DIR/{data,letsencrypt}
    
    # 生成配置
    cat > $NPM_DIR/docker-compose.yml <<EOF
version: '3'
services:
  app:
    image: jc21/nginx-proxy-manager:latest
    restart: unless-stopped
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF

    # 启动服务
    docker compose -f $NPM_DIR/docker-compose.yml up -d
    
    echo -e "${GREEN}✔ Docker版安装完成！访问 http://<IP>:81 ${NC}"
    echo -e "默认账号: ${YELLOW}admin@example.com${NC}"
    echo -e "默认密码: ${YELLOW}changeme${NC}"
}

uninstall_docker() {
    echo -e "${RED}▶ 开始卸载Docker版...${NC}"
    
    # 获取使用的端口
    local port=$(grep -oP "^\s+-\s\"\d+:(\d+)\"" $NPM_DIR/docker-compose.yml 2>/dev/null | head -1 | cut -d':' -f2 | tr -d '"')
    port=${port:-81}
    
    # 停止并删除容器
    docker compose -f $NPM_DIR/docker-compose.yml down 2>/dev/null
    
    # 清理镜像
    docker rmi jc21/nginx-proxy-manager 2>/dev/null
    
    # 清理文件
    rm -rf $NPM_DIR
    
    # 清理防火墙
    clean_firewall $port
    
    echo -e "${GREEN}✔ Docker版已完全卸载${NC}"
}

# ------------------------ 卸载主逻辑 ------------------------
uninstall_npm() {
    if [ -f "$NPM_DIR/docker-compose.yml" ]; then
        uninstall_docker
    elif [ -f "/etc/systemd/system/npm.service" ]; then
        uninstall_native
    else
        echo -e "${YELLOW}⚠ 未检测到Nginx Proxy Manager安装${NC}"
    fi
}

# ------------------------ 主菜单 ------------------------
show_menu() {
    clear
    echo -e "${GREEN}▌ Nginx Proxy Manager 终极管理脚本 ${NC}"
    echo -e "${GREEN}▌ 当前模式: $([ -f "$NPM_DIR/docker-compose.yml" ] && echo "Docker版" || \
               [ -f "/etc/systemd/system/npm.service" ] && echo "原生版" || echo "未安装")${NC}"
    echo "1. 安装原生版"
    echo "2. 安装Docker版"
    echo "3. 卸载现有版本"
    echo "0. 退出"
    echo "------------------------"
}

# ------------------------ 执行入口 ------------------------
while true; do
    show_menu
    read -p "请输入选项: " opt
    case $opt in
        1) install_native ;;
        2) install_docker ;;
        3) uninstall_npm ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项！${NC}" ;;
    esac
    echo && read -p "按回车键返回菜单..."
done

