#!/bin/bash

# 1Panel 安装脚本
# Version: 1.0
# Author: ChatGPT

# 配置项
PANEL_URL="https://resource.1panel.pro/quick_start.sh"
INSTALL_PATH="/root/1panel_installation"

# 函数：显示菜单
show_menu() {
    clear
    echo "========================="
    echo " 1Panel 安装管理脚本"
    echo "========================="
    echo "1. 安装 1Panel"
    echo "2. 管理 1Panel"
    echo "3. 卸载 1Panel"
    echo "0. 退出"
    echo "========================="
    read -p "请输入选项: " option
    case $option in
        1) install_panel ;;
        2) manage_panel ;;
        3) uninstall_panel ;;
        0) exit 0 ;;
        *) echo "无效的选项，请重新选择！" && sleep 2 && show_menu ;;
    esac
}

# 函数：安装 1Panel
install_panel() {
    echo "开始安装 1Panel..."
    curl -sSL $PANEL_URL -o quick_start.sh && bash quick_start.sh
    echo "1Panel 安装完成！"
    echo "请使用以下命令查看面板地址："
    echo "  面板地址: http://$(curl -s ifconfig.me):端口号"
    echo "  面板用户: 默认用户名"
    echo "  面板密码: 默认密码"
    echo "您可以修改密码，使用命令：1pctl update password"
    sleep 2
    show_menu
}

# 函数：管理 1Panel
manage_panel() {
    echo "管理 1Panel..."
    # 获取 VPS 的公共 IP 地址
    VPS_IP=$(curl -s ifconfig.me)
    # 获取端口号和用户设置的后缀，假设你有保存这些信息的方式
    # 这里用假设值代替，你可以根据实际情况进行调整
    PANEL_PORT="端口号"  # 例如：8080
    URL_SUFFIX="后缀"  # 用户设置的后缀
    PANEL_USER="默认用户"  # 默认用户名
    PANEL_PASS="默认密码"  # 默认密码

    echo "============================="
    echo "面板地址: http://$VPS_IP:$PANEL_PORT$URL_SUFFIX"
    echo "面板用户: $PANEL_USER"
    echo "面板密码: $PANEL_PASS"
    echo "提示: 修改密码可执行命令: 1pctl update password"
    echo "============================="
    sleep 2
    show_menu
}

# 函数：卸载 1Panel
uninstall_panel() {
    read -p "您确定要卸载 1Panel 吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "正在卸载 1Panel..."
        # 执行卸载命令，你可以根据需要添加更多卸载步骤
        rm -rf $INSTALL_PATH
        echo "1Panel 卸载完成！"
    else
        echo "取消卸载。"
    fi
    sleep 2
    show_menu
}

# 启动脚本
show_menu

