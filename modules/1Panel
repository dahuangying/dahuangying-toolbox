#!/bin/bash

# 1Panel 安装、管理、卸载菜单脚本

INSTALL_URL="https://resource.1panel.pro/quick_start.sh"
LOCAL_IP=$(curl -s ifconfig.me)  # 获取本地IP地址

# 显示菜单
show_menu() {
    clear
    echo "------------------------"
    echo "1. 安装"
    echo "2. 管理"
    echo "3. 卸载"
    echo "0. 返回上一级"
    echo "------------------------"
    read -p "请选择操作: " choice
    case $choice in
        1) install_panel ;;
        2) manage_panel ;;
        3) uninstall_panel ;;
        0) exit 0 ;;
        *) echo "无效选择，请重新选择" && sleep 2 && show_menu ;;
    esac
}

# 安装 1Panel
install_panel() {
    echo "开始安装 1Panel..."
    curl -sSL $INSTALL_URL -o quick_start.sh && bash quick_start.sh
    echo "1Panel 安装完成！"
    read -p "按任意键返回菜单..." -n 1 -s
    show_menu
}

# 管理 1Panel
manage_panel() {
    clear
    echo "1Panel 管理"
    echo "面板地址: http://$LOCAL_IP:12023/8aa2060c35"
    echo "面板用户: 3523421725"
    echo "面板密码: ********"  # 密码需要从某处读取或手动输入
    echo "提示: 修改密码可执行命令: 1pctl update password"
    read -p "按任意键返回菜单..." -n 1 -s
    show_menu
}

# 卸载 1Panel
uninstall_panel() {
    clear
    echo "开始卸载 1Panel..."
    # 卸载命令（根据实际情况调整）
    bash quick_start.sh uninstall
    echo "1Panel 卸载完成！"
    read -p "按任意键返回菜单..." -n 1 -s
    show_menu
}

# 入口
show_menu
