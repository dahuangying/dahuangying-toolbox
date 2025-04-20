#!/bin/bash

# 1Panel 安装管理脚本
# Version: 1.0
# Author: ChatGPT

# 配置项
PANEL_INSTALL_DIR="/root/1panel_installation"  # 1Panel 安装目录
PANEL_CONFIG_FILE="/root/1panel_config.txt"    # 配置文件路径

# 函数：显示菜单
show_menu() {
    clear
    echo "========================="
    echo " 1Panel 安装管理脚本"
    echo "========================="
    echo "1. 安装 1Panel"
    echo "2. 查看面板信息"
    echo "3. 修改密码"
    echo "4. 卸载 1Panel"
    echo "0. 退出"
    echo "========================="
    read -p "请输入选项: " option
    case $option in
        1) install_panel ;;
        2) view_panel_info ;;
        3) update_password ;;
        4) uninstall_panel ;;
        0) exit 0 ;;
        *) echo "无效的选项，请重新选择！" && sleep 2 && show_menu ;;
    esac
}

# 函数：安装 1Panel
install_panel() {
    echo "开始安装 1Panel..."

    # 执行官方安装脚本
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

# 函数：修改密码
update_password() {
    echo "正在修改密码..."
    # 通过官方命令修改密码
    1pctl update password
    sleep 2
    show_menu
}

# 函数：卸载 1Panel
uninstall_panel() {
    read -p "您确定要卸载 1Panel 并删除所有相关文件吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "正在卸载 1Panel..."

        # 查找并删除 1Panel 相关文件
        echo "查找并删除 1Panel 相关文件..."
        sudo find / -name "1panel*" -exec sudo rm -f {} \;

        # 删除服务文件
        echo "检查并删除服务文件..."
        sudo rm -f /root/1panel-v1.10.29-lts-linux-amd64/1panel.service

        # 检查并禁用服务
        echo "检查并禁用服务..."
        sudo systemctl list-units --type=service | grep 1panel
        sudo systemctl stop 1panel
        sudo systemctl disable 1panel
        sudo rm -f /etc/systemd/system/1panel.service

        # 确认删除所有文件
        echo "确认所有相关文件已删除..."
        sudo find / -name "1panel*"

        # 清理日志文件
        echo "清理日志文件..."
        sudo rm -f /var/log/1panel.log

        echo "1Panel 卸载完成！"
    else
        echo "取消卸载。"
    fi
    sleep 2
    show_menu
}

# 启动脚本
show_menu










