#!/bin/bash

# 设置绿色文本的颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # 默认颜色

# 设置 Halo 容器相关目录
HALO_DIR="$HOME/.halo2"
HALO_CONTAINER_NAME="halo"

# 可选镜像源（不指定版本号，拉取最新镜像）
DEFAULT_IMAGE="halohub/halo"  # 更改为 halohub/halo
# 或者
# DEFAULT_IMAGE="ghcr.io/halo-dev/halo"  # 更改为 ghcr.io/halo-dev/halo

# 检查 Docker 是否安装
check_docker_installed() {
    if ! command -v docker &>/dev/null; then
        echo "Docker 未安装，正在安装 Docker..."
        install_docker
    else
        echo -e "${GREEN}Docker 已安装${NC}"
    fi
}

# 安装 Docker
install_docker() {
    curl -fsSL https://get.docker.com | bash
    sudo systemctl start docker
    sudo systemctl enable docker
    echo -e "${GREEN}Docker 安装成功！${NC}"
}

# 检查容器是否已经安装
check_halo_installed() {
    if docker ps -a | grep -q "$HALO_CONTAINER_NAME"; then
        echo -e "Halo 容器状态: ${GREEN}已安装${NC}"
    else
        echo -e "Halo 容器状态: ${RED}未安装${NC}"
    fi
}

# 创建 Halo 容器
create_halo_container() {
    # 默认使用最新镜像
    IMAGE="$DEFAULT_IMAGE"
    echo "使用的镜像是：$IMAGE"

    docker run -it -d --name "$HALO_CONTAINER_NAME" -p 8090:8090 -v "$HALO_DIR:/root/.halo2" -e JVM_OPTS="-Xmx256m -Xms256m" "$IMAGE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Halo 安装成功！请访问 http://localhost:8090 进行管理${NC}"
        read -n 1 -s -r -p "操作完成，按任意键继续..."
        main_menu
    else
        echo -e "${RED}安装失败，请检查日志或配置.${NC}"
        read -n 1 -s -r -p "操作完成，按任意键继续..."
        main_menu
    fi
}

# 更新 Halo
update_halo() {
    check_halo_installed
    read -p "确定要更新 Halo 吗? (y/n): " confirm
    if [ "$confirm" == "y" ]; then
        echo "停止并删除旧的 Halo 容器..."
        docker stop "$HALO_CONTAINER_NAME"
        docker rm "$HALO_CONTAINER_NAME"
        
        echo "使用的镜像是：$DEFAULT_IMAGE"

        docker run -it -d --name "$HALO_CONTAINER_NAME" -p 8090:8090 -v "$HALO_DIR:/root/.halo2" -e JVM_OPTS="-Xmx256m -Xms256m" "$DEFAULT_IMAGE"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Halo 更新成功！请访问 http://localhost:8090 进行管理${NC}"
        else
            echo -e "${RED}更新失败，请检查日志或配置.${NC}"
        fi
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
        echo "正在停止并删除 Halo 容器..."
        docker stop "$HALO_CONTAINER_NAME"
        docker rm "$HALO_CONTAINER_NAME"
        
        echo "正在删除相关数据..."
        rm -rf "$HALO_DIR"
        
        echo -e "${GREEN}Halo 已成功卸载！相关容器和数据已删除${NC}"
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
        1) create_halo_container ;;
        2) update_halo ;;
        3) uninstall_halo ;;
        0) exit 0 ;;
        *) echo "无效选项，请重新选择." ; main_menu ;;
    esac
}

# 开始脚本执行时检测 Docker 是否安装
check_docker_installed

# 调用主菜单
main_menu












