#!/bin/bash

# 设置颜色
GREEN="\033[0;32m"  # 绿色
NC="\033[0m"        # 重置颜色

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
    echo "5. Docker 网络管理"
    echo "6. Docker 卷管理"
    echo "7. 清理所有未使用的资源"
    echo "0. 退出"
    read -p "请输入选项: " option
    case $option in
        1) show_docker_status ;;
        2) install_update_docker ;;
        3) docker_container_management ;;
        4) docker_image_management ;;
        5) docker_network_management ;;
        6) docker_volume_management ;;
        7) clean_unused_resources ;;
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

# Docker 容器管理
docker_container_management() {
    echo -e "${GREEN}Docker容器管理${NC}"
    echo -e "${GREEN}==============================${NC}"
    echo "1. 启动容器"
    echo "2. 停止容器"
    echo "3. 启动所有容器"
    echo "4. 停止所有容器"
    echo "5. 创建指定容器"
    echo "6. 删除指定容器"
	echo "7. 删除所有容器"
    echo "0. 返回"
    read -p "请输入选项: " container_option
    case $container_option in
        1) start_container ;;
        2) stop_container ;;
        3) start_all_containers ;;
        4) stop_all_containers ;;
        5) create_new_container ;;
        6) remove_specified_container ;;
		7) remove_all_containers ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && docker_container_management ;;
    esac
}

# 启动容器
start_container() {
    read -p "请输入要启动的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_container_management
    fi
    docker start $container_id
    echo -e "${GREEN}容器 $container_id 已启动！${NC}"
    pause
    docker_container_management
}

# 停止容器
stop_container() {
    read -p "请输入要停止的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_container_management
    fi
    docker stop $container_id
    echo -e "${GREEN}容器 $container_id 已停止！${NC}"
    pause
    docker_container_management
}

# 启动所有容器
start_all_containers() {
    docker start $(docker ps -a -q)
    echo -e "${GREEN}所有容器已启动！${NC}"
    pause
    docker_container_management
}

# 停止所有容器
stop_all_containers() {
    docker stop $(docker ps -q)
    echo -e "${GREEN}所有容器已停止！${NC}"
    pause
    docker_container_management
}

# 创建指定容器
create_new_container() {
    read -p "请输入新容器的镜像名称: " image_name
    if [ -z "$image_name" ]; then
        docker_container_management
    fi
    read -p "请输入新容器的名称（可选）: " container_name
    if [ -z "$container_name" ]; then
        docker_container_management
    fi
    docker run -d --name $container_name $image_name
    echo -e "${GREEN}新容器已创建！${NC}"
    pause
    docker_container_management
}

# 删除指定容器
remove_specified_container() {
    read -p "请输入要删除的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_container_management
    fi
    docker rm -f $container_id
    echo -e "${GREEN}容器 $container_id 已删除！${NC}"
    pause
    docker_container_management
}

# 删除所有容器
remove_all_containers() {
    read -p "您确定要删除所有容器吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker rm -f $(docker ps -a -q)  # 强制删除所有容器
        echo -e "${GREEN}所有容器已删除！${NC}"
   
    fi
    pause
    docker_container_management  # 返回容器管理菜单
}

# Docker 镜像管理
docker_image_management() {
    echo -e "${GREEN}Docker镜像管理${NC}"
    echo -e "${GREEN}==============================${NC}"
    echo "1. 删除指定镜像"
    echo "2. 创建指定容器"
    echo "3. 删除所有镜像"
    echo "0. 返回"
    read -p "请输入选项: " image_option
    case $image_option in
        1) remove_specified_image ;;
        2) create_new_container ;;
        3) remove_all_images ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && docker_image_management ;;
    esac
}

# 删除指定镜像
remove_specified_image() {
    read -p "请输入要删除的镜像 ID 或名称: " image_id
    if [ -z "$image_id" ]; then
        docker_image_management
    fi
    docker rmi -f $image_id
    echo -e "${GREEN}镜像 $image_id 已删除！${NC}"
    pause
    docker_image_management
}

# 删除所有镜像
remove_all_images() {
    docker rmi -f $(docker images -q)
    echo -e "${GREEN}所有镜像已删除！${NC}"
    pause
    docker_image_management
}

# Docker 网络管理
docker_network_management() {
    echo -e "${GREEN}Docker网络管理${NC}"
    echo -e "${GREEN}==============================${NC}"
    echo "1. 创建网络"
    echo "2. 加入网络"
    echo "3. 退出网络"
    echo "4. 删除网络"
    echo "0. 返回"
    read -p "请输入选项: " network_option
    case $network_option in
        1) create_network ;;
        2) join_network ;;
        3) leave_network ;;
        4) delete_network ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && docker_network_management ;;
    esac
}

# 创建 Docker 网络
create_network() {
    read -p "请输入要创建的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    docker network create $network_name
    echo -e "${GREEN}网络 $network_name 已创建！${NC}"
    pause
    docker_network_management
}

# 加入 Docker 网络
join_network() {
    read -p "请输入要加入的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_network_management
    fi
    read -p "请输入要加入的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    docker network connect $network_name $container_id
    echo -e "${GREEN}容器 $container_id 已加入网络 $network_name！${NC}"
    pause
    docker_network_management
}

# 退出 Docker 网络
leave_network() {
    read -p "请输入要退出的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_network_management
    fi
    read -p "请输入要退出的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    docker network disconnect $network_name $container_id
    echo -e "${GREEN}容器 $container_id 已退出网络 $network_name！${NC}"
    pause
    docker_network_management
}

# 删除 Docker 网络
delete_network() {
    read -p "请输入要删除的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    docker network rm $network_name
    echo -e "${GREEN}网络 $network_name 已删除！${NC}"
    pause
    docker_network_management
}

# Docker 卷管理
docker_volume_management() {
    echo -e "${GREEN}Docker卷管理${NC}"
    echo -e "${GREEN}==============================${NC}"
    echo "1. 创建新卷"
    echo "2. 删除指定卷"
    echo "3. 删除所有卷"
    echo "0. 返回"
    read -p "请输入选项: " volume_option
    case $volume_option in
        1) create_volume ;;
        2) delete_specified_volume ;;
        3) delete_all_volumes ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && docker_volume_management ;;
    esac
}

# 创建新卷
create_volume() {
    read -p "请输入要创建的新卷名称: " volume_name
    if [ -z "$volume_name" ]; then
        docker_volume_management
    fi
    docker volume create $volume_name
    echo -e "${GREEN}新卷 $volume_name 已创建！${NC}"
    pause
    docker_volume_management
}

# 删除指定卷
delete_specified_volume() {
    read -p "请输入要删除的卷名称: " volume_name
    if [ -z "$volume_name" ]; then
        docker_volume_management
    fi
    docker volume rm $volume_name
    echo -e "${GREEN}卷 $volume_name 已删除！${NC}"
    pause
    docker_volume_management
}

# 删除所有卷
delete_all_volumes() {
    docker volume rm $(docker volume ls -q)
    echo -e "${GREEN}所有卷已删除！${NC}"
    pause
    docker_volume_management
}

# 清理所有未使用的资源
clean_unused_resources() {
    confirm_action "清理所有未使用的资源" "docker system prune -a --volumes"
    pause
    show_menu
}

# 确认操作
confirm_action() {
    action_description=$1
    command_to_run=$2

    read -p "您确定要执行以下操作？$action_description [y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "正在执行操作..."
        eval $command_to_run
        echo "$action_description 已执行！"
    else
        echo "操作已取消。"
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

