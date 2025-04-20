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

# 显示主菜单
show_menu() {
    clear
    echo "========================="
    echo " Docker 管理脚本"
    echo "========================="
    echo "1. 查看 Docker 容器和镜像状态"
    echo "2. 停止所有运行中的容器"
    echo "3. 删除所有容器"
    echo "4. 删除所有镜像"
    echo "5. 清理所有未使用的资源"
    echo "6. 删除指定容器"
    echo "7. 删除指定镜像"
    echo "0. 退出"
    echo "========================="
    read -p "请输入选项: " option
    case $option in
        1) show_docker_status ;;
        2) stop_all_containers ;;
        3) remove_all_containers ;;
        4) remove_all_images ;;
        5) clean_unused_resources ;;
        6) remove_specified_container ;;
        7) remove_specified_image ;;
        0) exit 0 ;;
        *) echo "无效的选项，请重新选择！" && sleep 2 && show_menu ;;
    esac
}

# 查看 Docker 容器和镜像状态
show_docker_status() {
    echo "=============================="
    echo "查看所有容器状态"
    docker ps -a
    echo "=============================="
    echo "查看所有镜像状态"
    docker images
    sleep 3
    show_menu
}

# 停止所有运行中的容器
stop_all_containers() {
    echo "停止所有运行中的容器..."
    docker stop $(docker ps -q)
    echo "所有容器已停止！"
    sleep 2
    show_menu
}

# 删除所有容器
remove_all_containers() {
    echo "删除所有容器..."
    docker rm $(docker ps -a -q)
    echo "所有容器已删除！"
    sleep 2
    show_menu
}

# 删除所有镜像
remove_all_images() {
    echo "删除所有镜像..."
    docker rmi $(docker images -q)
    echo "所有镜像已删除！"
    sleep 2
    show_menu
}

# 清理所有未使用的资源
clean_unused_resources() {
    echo "清理所有未使用的资源..."
    docker system prune -a --volumes
    echo "未使用的资源已清理！"
    sleep 2
    show_menu
}

# 删除指定容器
remove_specified_container() {
    read -p "请输入要删除的容器 ID 或名称: " container_id
    echo "删除容器 $container_id..."
    docker rm -f $container_id
    echo "容器 $container_id 已删除！"
    sleep 2
    show_menu
}

# 删除指定镜像
remove_specified_image() {
    read -p "请输入要删除的镜像 ID 或名称: " image_id
    echo "删除镜像 $image_id..."
    docker rmi -f $image_id
    echo "镜像 $image_id 已删除！"
    sleep 2
    show_menu
}

# 欢迎信息
show_intro

# 主程序入口
while true; do
    show_menu
done
