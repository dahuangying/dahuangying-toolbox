#!/bin/bash

# 安装和配置 Halo 和 WordPress 的基本路径和变量
HALO_DIR="/opt/halo"
WORDPRESS_DIR="/opt/wordpress"
HALO_DB_NAME="halo_db"
WORDPRESS_DB_NAME="wordpress_db"

# 检查安装状态
check_status() {
    clear
    echo "========================================"
    if [ -d "$HALO_DIR" ]; then
        echo "Halo 安装状态: 已安装"
    else
        echo "Halo 安装状态: 未安装"
    fi

    if [ -d "$WORDPRESS_DIR" ]; then
        echo "WordPress 安装状态: 已安装"
    else
        echo "WordPress 安装状态: 未安装"
    fi
    echo "========================================"
    echo "大黄鹰-Linux服务器运维工具箱菜单-博客"
    echo "欢迎使用本脚本，请根据菜单选择操作："
    echo "========================================"
}

# 安装 Halo
install_halo() {
    echo "开始安装 Halo..."
    if [ -d "$HALO_DIR" ]; then
        echo "Halo 已经安装在 $HALO_DIR，跳过安装步骤."
    else
        echo "正在下载并安装 Halo..."
        git clone https://github.com/halo-dev/halo.git "$HALO_DIR"
        cd "$HALO_DIR"
        sudo apt update && sudo apt install -y openjdk-11-jdk
        echo "Halo 安装完成，配置服务..."
    fi
}

# 安装 WordPress
install_wordpress() {
    echo "开始安装 WordPress..."
    if [ -d "$WORDPRESS_DIR" ]; then
        echo "WordPress 已经安装在 $WORDPRESS_DIR，跳过安装步骤."
    else
        echo "正在下载并安装 WordPress..."
        git clone https://github.com/WordPress/WordPress.git "$WORDPRESS_DIR"
        cd "$WORDPRESS_DIR"
        sudo apt update && sudo apt install -y php php-mysql mysql-server
        cp wp-config-sample.php wp-config.php
        echo "WordPress 安装完成，配置数据库等."
    fi
}

# 更新 Halo
update_halo() {
    echo "正在更新 Halo..."
    cd "$HALO_DIR" || { echo "Halo 没有安装."; return; }
    git pull origin main
    echo "Halo 更新完成."
}

# 更新 WordPress
update_wordpress() {
    echo "正在更新 WordPress..."
    cd "$WORDPRESS_DIR" || { echo "WordPress 没有安装."; return; }
    git pull origin main
    echo "WordPress 更新完成."
}

# 卸载 Halo
uninstall_halo() {
    read -p "你确定要卸载 Halo 吗？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "正在卸载 Halo..."
        rm -rf "$HALO_DIR"
        echo "Halo 卸载完成，正在清理残余文件..."
        # 清理数据库或其他残余文件
        # sudo mysql -e "DROP DATABASE $HALO_DB_NAME;"
        echo "残余文件已彻底清除."
    else
        echo "取消卸载 Halo."
    fi
}

# 卸载 WordPress
uninstall_wordpress() {
    read -p "你确定要卸载 WordPress 吗？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "正在卸载 WordPress..."
        rm -rf "$WORDPRESS_DIR"
        echo "WordPress 卸载完成，正在清理残余文件..."
        # 清理数据库或其他残余文件
        # sudo mysql -e "DROP DATABASE $WORDPRESS_DB_NAME;"
        echo "残余文件已彻底清除."
    else
        echo "取消卸载 WordPress."
    fi
}

# 操作完成后按任意键继续
press_any_key_to_continue() {
    read -n 1 -s -r -p $'操作完成，按任意键继续...\n'
}

# 主菜单
main_menu() {
    check_status
    echo "1. 安装 Halo"
    echo "2. 安装 WordPress"
    echo "3. 更新 Halo"
    echo "4. 更新 WordPress"
    echo "5. 卸载 Halo"
    echo "6. 卸载 WordPress"
    echo "0. 退出"
    echo "========================================"
    read -p "请选择操作: " choice

    case $choice in
        1) install_halo; press_any_key_to_continue ;;
        2) install_wordpress; press_any_key_to_continue ;;
        3) update_halo; press_any_key_to_continue ;;
        4) update_wordpress; press_any_key_to_continue ;;
        5) uninstall_halo; press_any_key_to_continue ;;
        6) uninstall_wordpress; press_any_key_to_continue ;;
        0) exit 0 ;;
        *) echo "无效选项，请重新选择." ; press_any_key_to_continue ; main_menu ;;
    esac
}

# 调用主菜单
main_menu




