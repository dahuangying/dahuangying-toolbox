#!/bin/bash

# 设置颜色
GREEN="\033[0;32m"  # 绿色
NC="\033[0m"        # 重置颜色

# 显示主菜单
show_menu() {
    clear
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱菜单-Docker 管理脚本${NC}"
    echo -e "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}==================================${NC}"
    echo "1. 查看 Docker 容器和镜像状态"
    echo "2. 停止所有运行中的容器"
    echo "3. 删除所有容器"
    echo "4. 删除所有镜像"
    echo "5. 创建新容器"
    echo "6. 创建新镜像"
    echo "7. 清理所有未使用的资源"
    echo "8. 删除指定容器"
    echo "9. 删除指定镜像"
    echo "0. 退出"
    echo -e "${GREEN}==================================${NC}"
    read -p "请输入选项: " option
    case $option in
        1) show_docker_status ;;
        2) stop_all_containers ;;
        3) remove_all_containers ;;
        4) remove_all_images ;;
        5) create_new_container ;;
        6) create_new_image ;;
        7) clean_unused_resources ;;
        8) remove_specified_container ;;
        9) remove_specified_image ;;
        0) exit 0 ;;
        *) echo "无效的选项，请重新选择！" && sleep 2 && show_menu ;;
    esac
}

# 查看 Docker 容器和镜像状态
show_docker_status() {
    echo -e "${GREEN}==============================${NC}"
    echo -e "${GREEN}查看所有容器状态及资源使用情况：${NC}"
    
    # 获取容器状态及资源使用情况并以表格形式显示
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.CreatedAt}}" | column -t
    
    # 获取每个容器的资源使用情况
    echo -e "\n${GREEN}==============================${NC}"
    echo -e "${GREEN}容器的详细资源使用情况（CPU, 内存等）：${NC}"

    # 使用 docker stats 获取每个容器的资源使用情况并与容器状态合并
    for container in $(docker ps -q); do
        container_id=$(docker inspect --format '{{.Id}}' $container)
        container_name=$(docker inspect --format '{{.Name}}' $container | sed 's/\///g')
        container_status=$(docker inspect --format '{{.State.Status}}' $container)
        container_ports=$(docker inspect --format '{{.NetworkSettings.Ports}}' $container)
        container_memory=$(docker stats --no-stream --format "{{.MemUsage}}" $container)
        container_cpu=$(docker stats --no-stream --format "{{.CPUPerc}}" $container)

        echo -e "容器 ID: $container_id"
        echo -e "容器名称: $container_name"
        echo -e "状态: $container_status"
        echo -e "端口映射: $container_ports"
        echo -e "内存使用情况: $container_memory"
        echo -e "CPU使用情况: $container_cpu"
        echo -e "${GREEN}==============================${NC}"
    done

    # 显示镜像信息
    echo -e "\n${GREEN}==============================${NC}"
    echo -e "${GREEN}查看所有镜像状态（ID、名称、标签、创建时间、大小）：${NC}"
    docker images --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}\t{{.Size}}" | column -t

    pause
    show_menu
}

# 停止所有运行中的容器
stop_all_containers() {
    confirm_action "停止所有运行中的容器" "docker stop $(docker ps -q)"
    pause
    show_menu
}

# 删除所有容器
remove_all_containers() {
    confirm_action "删除所有容器" "docker rm $(docker ps -a -q)"
    pause
    show_menu
}

# 删除所有镜像
remove_all_images() {
    confirm_action "删除所有镜像" "docker rmi $(docker images -q)"
    pause
    show_menu
}

# 清理所有未使用的资源
clean_unused_resources() {
    confirm_action "清理所有未使用的资源" "docker system prune -a --volumes"
    pause
    show_menu
}

# 删除指定容器
remove_specified_container() {
    read -p "请输入要删除的容器 ID 或名称: " container_id
    confirm_action "删除容器 $container_id" "docker rm -f $container_id"
    pause
    show_menu
}

# 删除指定镜像
remove_specified_image() {
    read -p "请输入要删除的镜像 ID 或名称: " image_id
    confirm_action "删除镜像 $image_id" "docker rmi -f $image_id"
    pause
    show_menu
}

# 创建新容器
create_new_container() {
    read -p "请输入新容器的镜像名称: " image_name
    read -p "请输入新容器的名称（可选）: " container_name
    confirm_action "创建新容器" "docker run -d --name $container_name $image_name"
    pause
    show_menu
}

# 创建新镜像
create_new_image() {
    read -p "请输入要创建镜像的容器 ID 或名称: " container_id
    read -p "请输入镜像标签（可选）: " image_tag
    confirm_action "创建镜像 $image_tag" "docker commit $container_id $image_tag"
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


