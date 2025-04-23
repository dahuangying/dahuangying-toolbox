#!/bin/bash

# 变量定义
HALO_CONTAINER_NAME="halo"
HALO_IMAGE="halo/halo:latest"

# 检测 Docker 是否安装
function check_docker {
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，正在安装 Docker..."
        # 安装 Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "Docker 安装完成！"
    else
        echo "Docker 已安装。"
    fi
}

# 安装 Halo
function install_halo {
    check_docker
    echo "正在拉取 Halo Docker 镜像..."
    docker pull $HALO_IMAGE
    echo "正在启动 Halo 容器..."
    docker run -d --name $HALO_CONTAINER_NAME -p 8080:8080 $HALO_IMAGE
    echo "Halo 安装完成！访问地址：http://<你的服务器IP>:8080"
}

# 更新 Halo
function update_halo {
    echo "正在更新 Halo..."
    # 确保容器不会丢失数据，使用 Docker 卷挂载
    docker stop $HALO_CONTAINER_NAME
    docker rm $HALO_CONTAINER_NAME
    docker pull $HALO_IMAGE
    docker run -d --name $HALO_CONTAINER_NAME -p 8080:8080 $HALO_IMAGE
    echo "Halo 更新完成！"
}

# 卸载 Halo
function uninstall_halo {
    read -p "确定要卸载 Halo 吗？（y/n）：" confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "正在卸载 Halo..."
        docker stop $HALO_CONTAINER_NAME
        docker rm $HALO_CONTAINER_NAME
        docker rmi $HALO_IMAGE
        echo "Halo 已卸载，相关容器和镜像已删除。"
    else
        echo "取消卸载。"
    fi
}

# 主菜单
while true; do
    clear
    echo "========================================"
    echo "欢迎使用 Halo 一键安装脚本"
    echo "========================================"
    echo "1. 安装 Halo"
    echo "2. 更新 Halo"
    echo "3. 卸载 Halo"
    echo "0. 退出"
    read -p "请输入选择: " choice

    case $choice in
        1)
            install_halo
            read -p "按任意键继续..."
            ;;
        2)
            update_halo
            read -p "按任意键继续..."
            ;;
        3)
            uninstall_halo
            read -p "按任意键继续..."
            ;;
        0)
            exit 0
            ;;
        *)
            echo "无效选择，请重新输入。"
            read -p "按任意键继续..."
            ;;
    esac
done













