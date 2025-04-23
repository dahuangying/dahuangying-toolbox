#!/bin/bash

# 设置颜色
GREEN="\033[0;32m"  # 绿色
NC="\033[0m"        # 重置颜色

# 检测系统类型
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO=$ID
fi

# 显示主菜单
show_menu() {
    clear
    # 获取当前环境数据
    containers=$(docker ps -a -q | wc -l)
    images=$(docker images -q | wc -l)
    networks=$(docker network ls -q | wc -l)
    volumes=$(docker volume ls -q | wc -l)

    # 显示环境状态
    echo -e "${GREEN}环境状态： 容器: $containers  镜像: $images  网络: $networks  卷: $volumes ${NC}"
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱菜单-Docker 管理脚本${NC}"
    echo -e "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}====================================================${NC}"
    echo "1. 查看 Docker 容器、镜像、卷和网络状态"
    echo "2. 安装/更新 Docker 环境"
    echo "3. Docker 容器管理"
    echo "4. Docker 镜像管理"
    echo "5. 删除 Docker"
    echo "6. Docker 网络管理"
    echo "7. Docker 卷管理"
    echo "8. 清理所有未使用的资源"
    echo "0. 退出"
    read -p "请输入选项: " option
    case $option in
        1) show_docker_status ;;
        2) install_update_docker ;;
        3) docker_container_management ;;
        4) docker_image_management ;;
        5) delete_docker ;;
        6) docker_network_management ;;
        7) docker_volume_management ;;
        8) clean_unused_resources ;;
        0) exit 0 ;;
        *) echo "无效的选项，请重新选择！" && sleep 2 && show_menu ;;
    esac
}

# 查看 Docker 容器、镜像、卷和网络状态
show_docker_status() {
    echo -e "${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker版本${NC}"
    docker --version
    echo -e "\n${GREEN}Docker Compose版本${NC}"
    docker-compose --version

    echo -e "\n${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker镜像: $(docker images -q | wc -l)${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}"

    echo -e "\n${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker容器: $(docker ps -a -q | wc -l)${NC}"
    docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"

    echo -e "\n${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker卷: $(docker volume ls -q | wc -l)${NC}"
    docker volume ls --format "table {{.Driver}}\t{{.Name}}"

    echo -e "\n${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker网络: $(docker network ls -q | wc -l)${NC}"
    docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}"

    pause
    show_menu
}

# 安装或更新 Docker 环境
install_update_docker() {
    echo "正在安装或更新 Docker..."

    # 更新系统
    sudo apt-get update -y

    # 安装 Docker
    sudo apt-get install -y docker.io

    # 启动 Docker 服务
    sudo systemctl enable --now docker

    # 安装 Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/2.35.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    echo -e "${GREEN}Docker 和 Docker Compose 安装/更新完成！${NC}"
    pause
    show_menu
}

# 删除 Docker
delete_docker() {
    echo -e "${GREEN}正在卸载 Docker...${NC}"

    # 停止并删除 Docker 容器和镜像
    clean_docker_containers_images

    # 卸载 Docker 对应的包
    uninstall_docker

    # 删除 Docker 相关文件和目录
    delete_docker_files

    # 删除 Docker 用户和组（可选）
    delete_docker_user_group

    # 删除 Docker 安装脚本文件（如果存在）
    delete_docker_install_script

    echo -e "${GREEN}Docker 已卸载并清理完成！${NC}"
    pause
    show_menu
}

# 停止并删除 Docker 容器和镜像
clean_docker_containers_images() {
    echo "停止并删除所有容器和镜像..."
    sudo docker stop $(sudo docker ps -a -q)
    sudo docker rm $(sudo docker ps -a -q)
    sudo docker rmi $(sudo docker images -q)
}

# 卸载 Docker 对应的包
uninstall_docker() {
    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
        echo "卸载 Docker（适用于 Ubuntu/Debian）..."
        sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
    elif [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]]; then
        echo "卸载 Docker（适用于 CentOS/RHEL）..."
        sudo yum remove -y docker-ce docker-ce-cli containerd.io
    else
        echo "不支持的操作系统。"
        exit 1
    fi
}

# 删除 Docker 相关文件和目录
delete_docker_files() {
    echo "删除 Docker 配置和数据文件..."
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    sudo rm -rf /etc/docker
    sudo rm -rf /var/run/docker
}

# 删除 Docker 用户和组（可选）
delete_docker_user_group() {
    echo "删除 Docker 用户和组..."
    sudo deluser docker
    sudo delgroup docker
}

# 删除 Docker 安装脚本文件（如果存在）
delete_docker_install_script() {
    if [[ -f /get-docker.sh ]]; then
        echo "删除 Docker 安装脚本文件..."
        sudo rm -f /get-docker.sh
    fi
}

# 暂停，按任意键继续
pause() {
    # 设置绿色文本颜色
    echo -e "\033[0;32m操作完成，按任意键继续...\033[0m"
    read -n 1 -s -r
}

# 启动脚本
show_menu

