#!/bin/bash

# Docker 一键管理脚本
# 功能版本 v1.2
# 原始作者：kejilion
# 修改日期：2023-10-20

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
PLAIN="\033[0m"

show_menu() {
    echo -e "${BLUE}Docker 管理脚本${PLAIN}"
    echo -e "${GREEN}1.${PLAIN} 安装 Docker"
    echo -e "${GREEN}2.${PLAIN} 卸载 Docker"
    echo -e "${GREEN}3.${PLAIN} 启动 Docker"
    echo -e "${GREEN}4.${PLAIN} 停止 Docker"
    echo -e "${GREEN}5.${PLAIN} 重启 Docker"
    echo -e "${GREEN}6.${PLAIN} 查看 Docker 状态"
    echo -e "${GREEN}7.${PLAIN} 查看所有容器"
    echo -e "${GREEN}8.${PLAIN} 查看所有镜像"
    echo -e "${GREEN}9.${PLAIN} 清理无用镜像/容器"
    echo -e "${GREEN}10.${PLAIN} 退出脚本"
    echo
    read -rp "请输入选项 [1-10]: " choice
}

install_docker() {
    echo -e "${BLUE}开始安装 Docker...${PLAIN}"
    curl -fsSL https://get.docker.com | bash -s docker
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}Docker 安装完成！${PLAIN}"
    docker --version
}

uninstall_docker() {
    echo -e "${RED}开始卸载 Docker...${PLAIN}"
    systemctl stop docker
    apt-get purge docker-ce docker-ce-cli containerd.io -y
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
    echo -e "${GREEN}Docker 已卸载！${PLAIN}"
}

clean_docker() {
    echo -e "${YELLOW}开始清理无用资源...${PLAIN}"
    docker system prune -af
    echo -e "${GREEN}清理完成！${PLAIN}"
}

while true; do
    show_menu
    case $choice in
        1) install_docker ;;
        2) uninstall_docker ;;
        3) systemctl start docker && echo -e "${GREEN}Docker 已启动${PLAIN}" ;;
        4) systemctl stop docker && echo -e "${GREEN}Docker 已停止${PLAIN}" ;;
        5) systemctl restart docker && echo -e "${GREEN}Docker 已重启${PLAIN}" ;;
        6) systemctl status docker ;;
        7) docker ps -a ;;
        8) docker images ;;
        9) clean_docker ;;
        10) break ;;
        *) echo -e "${RED}无效选项，请重新输入！${PLAIN}" ;;
    esac
    echo
    read -rp "按回车键继续..."
done

echo -e "${BLUE}脚本已退出${PLAIN}"





