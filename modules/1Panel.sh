#!/bin/bash

# 1Panel 安装管理脚本
# Version: 1.0
# Author: ChatGPT

# 配置项
PANEL_INSTALL_DIR="/root/1panel_installation"  # 1Panel 安装目录
PANEL_CONFIG_FILE="/root/1panel_config.txt"    # 配置文件路径
PANEL_LOG_DIR="/var/log/1panel"                 # 日志目录
PANEL_SERVICE_FILE="/etc/systemd/system/1panel.service"  # 服务文件路径
PANEL_CLI="/usr/local/bin/1pctl"                # 1pctl 工具路径

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
    read -p "您确定要卸载 1Panel 并删除所有相关文件吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "正在卸载 1Panel..."

        # 停止服务并禁用启动
        systemctl stop 1panel
        systemctl disable 1panel

        # 删除 1Panel 安装目录
        echo "删除安装目录..."
        rm -rf "$PANEL_INSTALL_DIR"
        echo "已删除安装目录 $PANEL_INSTALL_DIR"

        # 删除配置文件
        echo "删除配置文件..."
        rm -f "$PANEL_CONFIG_FILE"
        echo "已删除配置文件 $PANEL_CONFIG_FILE"

        # 删除日志文件
        echo "删除日志文件..."
        rm -rf "$PANEL_LOG_DIR"
        echo "已删除日志文件 $PANEL_LOG_DIR"

        # 删除服务文件
        echo "删除服务文件..."
        rm -f "$PANEL_SERVICE_FILE"
        echo "已删除服务文件 $PANEL_SERVICE_FILE"

        # 删除 1pctl 工具
        echo "删除 1pctl 工具..."
        rm -f "$PANEL_CLI"
        echo "已删除 1pctl 工具 $PANEL_CLI"

        echo "1Panel 卸载完成！"
    else
        echo "取消卸载。"
    fi
    sleep 2
    show_menu
}

# 启动脚本
show_menu






