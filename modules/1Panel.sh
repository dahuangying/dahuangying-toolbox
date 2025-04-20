#!/bin/bash

# 1Panel 安装管理脚本
# Version: 1.0
# Author: ChatGPT

# 配置项
PANEL_CONFIG_PATH="/root/1panel_config.txt"  # 配置文件路径

# 函数：显示菜单
show_menu() {
    clear
    echo "========================="
    echo " 1Panel 安装管理脚本"
    echo "========================="
    echo "1. 安装 1Panel"
    echo "2. 查看面板信息"
    echo "3. 卸载 1Panel"
    echo "0. 退出"
    echo "========================="
    read -p "请输入选项: " option
    case $option in
        1) install_panel ;;
        2) view_panel_info ;;
        3) uninstall_panel ;;
        0) exit 0 ;;
        *) echo "无效的选项，请重新选择！" && sleep 2 && show_menu ;;
    esac
}

# 函数：安装 1Panel
install_panel() {
    echo "开始安装 1Panel..."
    curl -sSL https://resource.1panel.pro/quick_start.sh -o quick_start.sh && bash quick_start.sh

    echo "1Panel 安装完成！"
    echo "请使用以下命令查看面板地址："
    echo "您可以通过 1pctl user-info 查看面板信息"
    sleep 2
    show_menu
}

# 函数：查看面板信息
view_panel_info() {
    echo "正在获取面板信息..."
    1pctl user-info
    sleep 2
    show_menu
}

# 函数：卸载 1Panel
uninstall_panel() {
    read -p "您确定要卸载 1Panel 吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "正在卸载 1Panel..."

        # 假设安装目录和配置文件路径
        INSTALL_DIR="/root/1panel_installation"
        PANEL_CONFIG_PATH="/root/1panel_config.txt"
        
        # 停止相关服务
        systemctl stop 1panel  # 如果 1Panel 有服务，可以使用 systemctl 停止它
        systemctl disable 1panel  # 如果 1Panel 是开机启动服务

        # 删除 1Panel 安装文件和配置文件
        if [ -d "$INSTALL_DIR" ]; then
            rm -rf "$INSTALL_DIR"
            echo "已删除安装目录 $INSTALL_DIR"
        fi

        if [ -f "$PANEL_CONFIG_PATH" ]; then
            rm -f "$PANEL_CONFIG_PATH"
            echo "已删除配置文件 $PANEL_CONFIG_PATH"
        fi

        # 如果有其他可能的服务或文件需要删除，可以根据需要添加
        # 例如，删除 1Panel 的服务文件
        # rm -f /etc/systemd/system/1panel.service

        echo "1Panel 卸载完成！"
    else
        echo "取消卸载。"
    fi
    sleep 2
    show_menu
}

# 启动脚本
show_menu






