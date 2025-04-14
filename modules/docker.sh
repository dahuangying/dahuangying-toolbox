#!/bin/bash

# 安装 Docker（支持 Debian/Ubuntu）
install_docker() {
    echo "安装 Docker 中..."
    curl -fsSL https://get.docker.com | bash -s docker
    echo "Docker 安装完成。"
}

# 安装极光面板
install_jg_panel() {
    echo "正在安装极光面板..."
    docker run -d       --name jgpanel       --restart always       -p 5678:5678       -v /etc/jg:/etc/jg       -v /etc/jglog:/etc/jglog       -v /etc/jgbackup:/etc/jgbackup       jerrykuku/jgpanel
    echo "极光面板部署完成，访问端口: 5678"
}

# 主菜单
echo "Docker 管理模块："
echo "1. 安装 Docker"
echo "2. 部署极光面板 (Aurora Panel)"
echo "0. 返回主菜单"
read -p "请输入选项编号: " choice
case $choice in
    1) install_docker ;;
    2) install_jg_panel ;;
    0) exit 0 ;;
    *) echo "无效输入。" ;;
esac
