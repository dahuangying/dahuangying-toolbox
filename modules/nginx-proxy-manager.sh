#!/bin/bash
# Nginx Proxy Manager 终极稳定版
# 修复内容：仓库克隆失败+多源备用+全平台兼容
# 版本：v5.1

# ---------------------------- 全局配置 ----------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'
NPM_DIR="/opt/nginx-proxy-manager"
REPO_SOURCES=(
    "https://github.com/jc21/nginx-proxy-manager.git"
    "https://gitee.com/mirrors/nginx-proxy-manager.git"
    "https://hub.fastgit.org/jc21/nginx-proxy-manager.git"
)
DEFAULT_PORT=81

# ------------------------ 增强版克隆函数 ------------------------
clone_repo() {
    local retries=3
    echo -e "${GREEN}▶ 尝试克隆仓库(剩余重试次数: $retries)...${NC}"
    
    for source in "${REPO_SOURCES[@]}"; do
        while [ $retries -gt 0 ]; do
            echo -e "${YELLOW}⚡ 尝试源: $source${NC}"
            git clone --depth 1 "$source" "$NPM_DIR" 2>/tmp/npm_clone.log && {
                echo -e "${GREEN}✔ 仓库克隆成功${NC}"
                return 0
            }
            
            echo -e "${YELLOW}⚠ 克隆失败，错误日志:${NC}"
            cat /tmp/npm_clone.log
            ((retries--))
            
            if [ $retries -gt 0 ]; then
                echo -e "${YELLOW}🔄 剩余重试次数: $retries${NC}"
                sleep 3
            fi
        done
        retries=3 # 重置为下一个源重试
    done
    
    echo -e "${RED}❌ 所有克隆源均失败！请检查：${NC}"
    echo "1. 网络连接状态"
    echo "2. git是否安装(运行: apt install git 或 yum install git)"
    echo "3. 手动克隆: git clone ${REPO_SOURCES[0]} $NPM_DIR"
    exit 1
}

# ------------------------ 原生版安装 ------------------------
install_native() {
    echo -e "${GREEN}▶ 开始原生版安装流程...${NC}"
    
    # 1. 系统检测
    if ! command -v git &>/dev/null; then
        echo -e "${YELLOW}⚠ 正在安装git...${NC}"
        if command -v apt &>/dev/null; then
            apt update && apt install -y git
        elif command -v yum &>/dev/null; then
            yum install -y git
        else
            echo -e "${RED}❌ 不支持的包管理器，请手动安装git${NC}"
            exit 1
        fi
    fi

    # 2. 克隆仓库（使用增强版克隆函数）
    clone_repo

    # 3. 后续安装流程
    cd "$NPM_DIR" || exit 1
    
    echo -e "${GREEN}▶ 正在安装Node.js依赖...${NC}"
    npm config set registry https://registry.npmmirror.com
    if ! npm install --production; then
        echo -e "${YELLOW}⚠ 正在修复npm安装...${NC}"
        npm cache clean --force
        if ! npm install --production --unsafe-perm; then
            echo -e "${RED}❌ 依赖安装失败，请尝试：${NC}"
            echo "1. 手动运行: cd $NPM_DIR && npm install"
            echo "2. 检查node版本(node -v 应为v16.x)"
            exit 1
        fi
    fi

    # 4. 创建系统服务
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

    echo -e "${GREEN}✔ 安装成功！访问 http://<IP>:${DEFAULT_PORT} ${NC}"
    echo -e "默认账号: ${YELLOW}admin@example.com${NC}"
    echo -e "默认密码: ${YELLOW}changeme${NC}"
}

# ------------------------ Docker版安装 ------------------------
install_docker() {
    echo -e "${GREEN}▶ 开始Docker版安装流程...${NC}"
    
    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}⚠ 正在安装Docker...${NC}"
        curl -fsSL https://get.docker.com | sh || {
            echo -e "${RED}❌ Docker安装失败！${NC}"
            exit 1
        }
        systemctl enable --now docker
    fi

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

    if ! docker compose -f "$NPM_DIR"/docker-compose.yml up -d; then
        echo -e "${RED}❌ Docker启动失败！请检查：${NC}"
        echo "1. docker服务状态: systemctl status docker"
        echo "2. 端口冲突情况: netstat -tulnp | grep -E '80|81|443'"
        exit 1
    fi

    echo -e "${GREEN}✔ 安装成功！访问 http://<IP>:81 ${NC}"
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
