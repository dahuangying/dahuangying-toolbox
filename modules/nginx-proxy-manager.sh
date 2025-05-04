#!/bin/bash

# 日志文件路径
LOG_FILE="/var/log/nginx_proxy_manager_install.log"

# 输出日志函数
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# 设置颜色
GREEN='\033[0;32m'
NC='\033[0m' # 无颜色

# 检查操作系统并选择合适的安装命令
detect_os() {
    if [ -f /etc/debian_version ]; then
        DISTRO="debian"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="redhat"
    elif [ -f /etc/centos-release ]; then
        DISTRO="centos"
    else
        echo "不支持的操作系统！"
        exit 1
    fi
    log_message "检测到操作系统: $DISTRO"
}

# 检查依赖并安装
check_dependencies() {
    log_message "检查并安装必要的依赖项..."
    dependencies=("curl" "git" "ufw")

    # 判断是否已安装依赖
    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &>/dev/null; then
            echo "$dep 未安装，正在安装..."
            install_dependency $dep
        else
            echo "$dep 已安装"
        fi
    done
}

# 安装依赖函数
install_dependency() {
    local dep=$1
    if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
        sudo apt-get install -y $dep
    elif [[ "$DISTRO" == "redhat" || "$DISTRO" == "centos" ]]; then
        sudo yum install -y $dep
    else
        echo "不支持的操作系统！"
        exit 1
    fi
    log_message "成功安装 $dep"
}

# 配置防火墙
configure_firewall() {
    log_message "配置防火墙..."
    
    echo "请选择要开放的端口："
    echo "1. HTTP (80)"
    echo "2. HTTPS (443)"
    echo "3. 自定义端口"
    
    read -p "请输入选项 (1/2/3): " choice
    case $choice in
        1)
            sudo ufw allow 80/tcp
            log_message "开放 HTTP 端口 80"
            ;;
        2)
            sudo ufw allow 443/tcp
            log_message "开放 HTTPS 端口 443"
            ;;
        3)
            read -p "请输入自定义端口: " custom_port
            sudo ufw allow $custom_port/tcp
            log_message "开放自定义端口 $custom_port"
            ;;
        *)
            echo "无效选择，退出..."
            exit 1
            ;;
    esac
    sudo ufw enable
    log_message "防火墙配置完成"
}

# 安装 Docker
install_docker() {
    log_message "开始安装 Docker..."
    
    if [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    elif [[ "$DISTRO" == "redhat" || "$DISTRO" == "centos" ]]; then
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
    fi
    
    # 启动 Docker 并设置开机启动
    sudo systemctl start docker
    sudo systemctl enable docker
    log_message "Docker 安装并启动成功"
}

# 安装原生版
install_native() {
    log_message "安装原生版 Nginx Proxy Manager..."
    # 在此添加原生版安装的命令（非 Docker 版）
    echo "正在安装原生版 Nginx Proxy Manager..."
    # 示例：sudo apt-get install nginx
    log_message "原生版 Nginx Proxy Manager 安装完成"
}

# 更新原生版
update_native() {
    log_message "更新原生版 Nginx Proxy Manager..."
    # 在此添加更新原生版的命令
    echo "正在更新原生版 Nginx Proxy Manager..."
    # 示例：sudo apt-get update nginx
    log_message "原生版 Nginx Proxy Manager 更新完成"
}

# 卸载原生版
uninstall_native() {
    log_message "卸载原生版 Nginx Proxy Manager..."
    # 在此添加卸载原生版的命令
    echo "正在卸载原生版 Nginx Proxy Manager..."
    # 示例：sudo apt-get remove nginx
    log_message "原生版 Nginx Proxy Manager 卸载完成"
}

# 安装 Docker 版
install_docker_version() {
    log_message "安装 Docker 版 Nginx Proxy Manager..."
    sudo docker run -d -p 80:80 -p 443:443 --name nginx-proxy-manager \
        -v /srv/nginx/data:/data \
        -v /srv/nginx/letsencrypt:/etc/letsencrypt \
        jlesage/nginx-proxy-manager
    log_message "Docker 版 Nginx Proxy Manager 安装完成"
}

# 更新 Docker 版
update_docker_version() {
    log_message "更新 Docker 版 Nginx Proxy Manager..."
    sudo docker pull jlesage/nginx-proxy-manager
    sudo docker stop nginx-proxy-manager
    sudo docker rm nginx-proxy-manager
    sudo docker run -d -p 80:80 -p 443:443 --name nginx-proxy-manager \
        -v /srv/nginx/data:/data \
        -v /srv/nginx/letsencrypt:/etc/letsencrypt \
        jlesage/nginx-proxy-manager
    log_message "Docker 版 Nginx Proxy Manager 更新完成"
}

# 卸载 Docker 版
uninstall_docker_version() {
    log_message "卸载 Docker 版 Nginx Proxy Manager..."
    sudo docker stop nginx-proxy-manager
    sudo docker rm nginx-proxy-manager
    sudo docker rmi jlesage/nginx-proxy-manager
    log_message "Docker 版 Nginx Proxy Manager 卸载完成"
}

# 查看状态
check_status() {
    log_message "查看 Nginx Proxy Manager 状态..."
    # 检查原生版或 Docker 版的状态
    docker_status=$(sudo docker ps -a | grep nginx-proxy-manager)
    if [ -z "$docker_status" ]; then
        echo "Docker 版 Nginx Proxy Manager 未安装或未运行"
    else
        echo "Docker 版 Nginx Proxy Manager 正在运行"
    fi
}

# 用户交互和主菜单
main_menu() {
    echo -e "${GREEN}请选择操作:${NC}"
    echo "1. 安装原生版"
    echo "2. 更新原生版"
    echo "3. 卸载原生版"
    echo "4. 安装Docker版"
    echo "5. 更新Docker版"
    echo "6. 卸载Docker版"
    echo "7. 查看状态"
    echo "0. 退出"
    echo "=============="

    read -p "请输入选项 (0-7): " choice
    case $choice in
        1)
            detect_os
            check_dependencies
            install_native
            ;;
        2)
            detect_os
            update_native
            ;;
        3)
            uninstall_native
            ;;
        4)
            detect_os
            check_dependencies
            install_docker
            install_docker_version
            ;;
        5)
            update_docker_version
            ;;
        6)
            uninstall_docker_version
            ;;
        7)
            check_status
            ;;
        0)
            echo "确认退出？(y/n)"
            read -p "请输入： " confirm_exit
            if [[ "$confirm_exit" == "y" ]]; then
                echo "退出脚本"
                exit 0
            else
                main_menu
            fi
            ;;
        *)
            echo "无效选择，请重新输入"
            main_menu
            ;;
    esac
}

# 执行主菜单
main_menu

