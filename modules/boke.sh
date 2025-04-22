#!/bin/bash

# 设置绿色文本的颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # 默认颜色

# 设置 Halo 和 MySQL 容器相关目录
HALO_DIR="/opt/halo"
COMPOSE_FILE="docker-compose.yml"

# 检查 Docker 是否安装
check_docker_installed() {
    if ! command -v docker &>/dev/null; then
        echo "Docker 未安装，正在安装 Docker..."
        install_docker
    else
        echo -e "${GREEN}Docker 已安装${NC}"
    fi
}

# 检查 Docker Compose 是否安装
check_docker_compose_installed() {
    if ! command -v docker-compose &>/dev/null; then
        echo "Docker Compose 未安装，正在安装 Docker Compose..."
        install_docker_compose
    else
        echo -e "${GREEN}Docker Compose 已安装${NC}"
    fi
}

# 安装 Docker
install_docker() {
    # 使用官方脚本安装 Docker
    curl -fsSL https://get.docker.com | bash
    sudo systemctl start docker
    sudo systemctl enable docker
    echo -e "${GREEN}Docker 安装成功！${NC}"
}

# 安装 Docker Compose
install_docker_compose() {
    # 安装 Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose 安装成功！${NC}"
}

# 检查 Halo 是否已安装
check_halo_installed() {
    if docker ps -a | grep -q "halo"; then
        echo -e "Halo 安装状态: ${GREEN}已安装${NC}"
    else
        echo -e "Halo 安装状态: ${RED}未安装${NC}"
    fi
}

# 创建 Docker Compose 配置文件
create_docker_compose() {
    echo "正在创建 Docker Compose 配置文件..."

    cat <<EOF > "$COMPOSE_FILE"
version: '3.7'

services:
  halo:
    image: halo-run/halo:latest
    container_name: halo
    environment:
      - HALO_ADMIN_PASSWORD=admin # 默认管理员密码（可以修改）
      - HALO_DB_URL=jdbc:mysql://db:3306/halo
      - HALO_DB_USERNAME=root
      - HALO_DB_PASSWORD=example
    ports:
      - "8080:8080"
    depends_on:
      - db
    restart: always
    volumes:
      - halo_data:/opt/halo

  db:
    image: mysql:5.7
    container_name: halo-db
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: halo
    volumes:
      - db_data:/var/lib/mysql
    restart: always

volumes:
  halo_data:
  db_data:
EOF
    echo "Docker Compose 配置文件创建完成."
}

# 启动 Docker 服务
start_docker_services() {
    echo "正在启动 Docker 服务..."

    docker-compose up -d
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}服务启动成功! Halo: http://localhost:8080${NC}"
    else
        echo "服务启动失败，请查看日志."
        exit 1
    fi
}

# 停止并清除容器、镜像和卷
stop_and_cleanup() {
    echo "正在停止并清除 Halo 容器、镜像和数据卷..."

    docker-compose down -v
    docker system prune -af
    docker volume prune -f
    echo "容器、镜像和数据卷已清除。"
}

# 安装 Halo
install_halo() {
    check_halo_installed
    read -p "确定要安装 Halo 吗? (y/n): " confirm
    if [ "$confirm" == "y" ]; then
        create_docker_compose
        start_docker_services
        echo -e "${GREEN}Halo 安装成功！请访问 http://localhost:8080 进行管理${NC}"
        read -n 1 -s -r -p "操作完成，按任意键继续..."
        main_menu
    else
        echo "取消安装 Halo."
        read -n 1 -s -r -p "操作完成，按任意键继续..."
        main_menu
    fi
}

# 更新 Halo
update_halo() {
    check_halo_installed
    read -p "确定要更新 Halo 吗? (y/n): " confirm
    if [ "$confirm" == "y" ]; then
        echo "正在更新 Halo..."
        stop_and_cleanup
        create_docker_compose
        start_docker_services
        echo -e "${GREEN}Halo 更新成功！请访问 http://localhost:8080 进行管理${NC}"
        read -n 1 -s -r -p "操作完成，按任意键继续..."
        main_menu
    else
        echo "取消更新 Halo."
        read -n 1 -s -r -p "操作完成，按任意键继续..."
        main_menu
    fi
}

# 卸载 Halo
uninstall_halo() {
    check_halo_installed
    read -p "确定要卸载 Halo 吗? (y/n): " confirm
    if [ "$confirm" == "y" ]; then
        stop_and_cleanup
        echo -e "${GREEN}Halo 卸载成功，相关容器、镜像和数据已删除${NC}"
        read -n 1 -s -r -p "操作完成，按任意键继续..."
        main_menu
    else
        echo "取消卸载 Halo."
        read -n 1 -s -r -p "操作完成，按任意键继续..."
        main_menu
    fi
}

# 主菜单
main_menu() {
    clear
    echo -e "${GREEN}========================================${NC}"
    echo "大黄鹰-Linux服务器运维工具箱菜单-Halo Docker版"
    echo "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}========================================${NC}"

    check_halo_installed

    echo "1. 安装 Halo"
    echo "2. 更新 Halo"
    echo "3. 卸载 Halo"
    echo "0. 退出"
    echo -e "${GREEN}========================================${NC}"

    read -p "请选择操作: " choice

    case $choice in
        1) install_halo ;;
        2) update_halo ;;
        3) uninstall_halo ;;
        0) exit 0 ;;
        *) echo "无效选项，请重新选择." ; main_menu ;;
    esac
}

# 开始脚本执行时检测 Docker 和 Docker Compose 是否安装
check_docker_installed
check_docker_compose_installed

# 调用主菜单
main_menu











