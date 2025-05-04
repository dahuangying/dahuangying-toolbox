#!/bin/bash
# Nginx Proxy Manager 全平台管理脚本
# 功能：原生/Docker双模式 | 自动修复依赖 | 智能卸载
# 版本：v5.0
# 支持：Ubuntu/Debian/CentOS/RHEL/ARM

# ---------------------------- 全局配置 ----------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'
NPM_DIR="/opt/nginx-proxy-manager"
DEFAULT_PORT=81
NODE_VERSION="16"  # LTS版本

# ------------------------ 初始化检查 ------------------------
init_check() {
    # 检测root权限
    [ "$(id -u)" -ne 0 ] && {
        echo -e "${RED}❌ 请使用root用户运行此脚本！${NC}"
        exit 1
    }

    # 检测系统
    if grep -qi "ubuntu\|debian" /etc/os-release; then
        PM="apt"
        OS="debian"
    elif grep -qi "centos\|rhel" /etc/os-release; then
        PM="yum"
        OS="rhel"
    else
        echo -e "${YELLOW}⚠ 非官方支持系统，尝试通用安装...${NC}"
        PM="unknown"
    fi

    # 检测架构
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *) ARCH="unknown" ;;
    esac
}

# ------------------------ 依赖管理 ------------------------
install_deps() {
    echo -e "${GREEN}▶ 安装系统依赖...${NC}"
    
    # 公共依赖
    local common_deps=("curl" "git" "sudo")
    
    # 分系统安装
    case "$OS" in
        debian)
            apt update
            apt install -y "${common_deps[@]}" build-essential python3
            ;;
        rhel)
            yum install -y "${common_deps[@]}" make gcc-c++ python3
            ;;
        *)
            echo -e "${YELLOW}⚠ 请手动安装依赖: ${common_deps[*]}${NC}"
            ;;
    esac
}

install_nodejs() {
    echo -e "${GREEN}▶ 安装Node.js ${NODE_VERSION}...${NC}"
    
    # 已安装则跳过
    if command -v node &>/dev/null; then
        echo -e "${YELLOW}⚠ 已安装Node.js $(node -v)${NC}"
        return
    fi

    case "$OS" in
        debian)
            curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - || {
                echo -e "${YELLOW}⚠ 使用备用Node源...${NC}"
                apt install -y ca-certificates gnupg
                mkdir -p /etc/apt/keyrings
                curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
                echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
                apt update
            }
            apt install -y nodejs
            ;;
        rhel)
            curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash - || {
                echo -e "${YELLOW}⚠ 使用备用Node源...${NC}"
                yum install -y https://rpm.nodesource.com/pub_${NODE_VERSION}.x/el/7/x86_64/nodejs-${NODE_VERSION}.x-1nodesource.x86_64.rpm
            }
            ;;
        *)
            echo -e "${RED}❌ 不支持的自动安装系统${NC}"
            exit 1
            ;;
    esac
    
    # 验证安装
    if ! node --version &>/dev/null; then
        echo -e "${RED}❌ Node.js安装失败！请手动安装后重试${NC}"
        exit 1
    fi
}

# ------------------------ 原生版管理 ------------------------
setup_native_npm() {
    echo -e "${GREEN}▶ 配置原生版NPM...${NC}"
    
    # 修复npm权限
    mkdir -p /root/.npm
    chown -R $(whoami) /root/.npm
    
    # 使用国内镜像源
    npm config set registry https://registry.npmmirror.com
    npm cache clean --force
    
    # 安装依赖
    cd "$NPM_DIR"
    if ! npm install --production; then
        echo -e "${YELLOW}⚠ 正在尝试修复npm安装...${NC}"
        npm install --production --unsafe-perm || {
            echo -e "${RED}❌ npm依赖安装失败！请检查：${NC}"
            echo "1. 手动运行: cd $NPM_DIR && npm install"
            echo "2. 检查网络连接"
            exit 1
        }
    fi
}

install_native() {
    init_check
    install_deps
    install_nodejs
    
    echo -e "${GREEN}▶ 安装原生版Nginx Proxy Manager...${NC}"
    
    # 克隆仓库
    git clone https://github.com/jc21/nginx-proxy-manager.git "$NPM_DIR" || {
        echo -e "${RED}❌ 仓库克隆失败！${NC}"
        exit 1
    }
    
    # 配置依赖
    setup_native_npm
    
    # 创建服务
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
    
    echo -e "${GREEN}✔ 安装完成！访问 http://<IP>:${DEFAULT_PORT} ${NC}"
    echo -e "默认账号: ${YELLOW}admin@example.com${NC}"
    echo -e "默认密码: ${YELLOW}changeme${NC}"
}

# ------------------------ Docker版管理 ------------------------
install_docker() {
    init_check
    
    echo -e "${GREEN}▶ 安装Docker环境...${NC}"
    
    # 已安装则跳过
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | sh || {
            echo -e "${RED}❌ Docker安装失败！${NC}"
            exit 1
        }
        systemctl enable --now docker
    fi
    
    # 安装docker-compose
    if ! command -v docker-compose &>/dev/null; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    echo -e "${GREEN}▶ 配置Docker版NPM...${NC}"
    
    mkdir -p "$NPM_DIR"/{data,letsencrypt}
    
    cat > "$NPM_DIR"/docker-compose.yml <<EOF
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

    docker compose -f "$NPM_DIR"/docker-compose.yml up -d
    
    echo -e "${GREEN}✔ 安装完成！访问 http://<IP>:81 ${NC}"
    echo -e "默认账号: ${YELLOW}admin@example.com${NC}"
    echo -e "默认密码: ${YELLOW}changeme${NC}"
}

# ------------------------ 卸载管理 ------------------------
uninstall() {
    echo -e "${RED}▶ 开始卸载...${NC}"
    
    # 检测安装模式
    if [ -f "$NPM_DIR/docker-compose.yml" ]; then
        echo -e "${YELLOW}检测到Docker版安装${NC}"
        docker compose -f "$NPM_DIR"/docker-compose.yml down
        docker rmi jc21/nginx-proxy-manager &>/dev/null
    elif [ -f "/etc/systemd/system/npm.service" ]; then
        echo -e "${YELLOW}检测到原生版安装${NC}"
        systemctl stop npm
        systemctl disable npm
        rm -f /etc/systemd/system/npm.service
    fi
    
    # 清理文件
    rm -rf "$NPM_DIR"
    
    echo -e "${GREEN}✔ 卸载完成${NC}"
}

# ------------------------ 主菜单 ------------------------
show_menu() {
    clear
    echo -e "${GREEN}▌ Nginx Proxy Manager 全平台管理脚本 ${NC}"
    echo -e "${GREEN}▌ 检测到系统: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2) ${NC}"
    echo -e "${GREEN}▌ 当前架构: ${ARCH} ${NC}"
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
        3) uninstall ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项！${NC}" ;;
    esac
    echo && read -p "按回车键继续..."
done

