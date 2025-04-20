#!/bin/bash

# =======================================
# 1Panel 新一代管理面板 安装脚本
# =======================================

# 功能菜单
function show_menu() {
    clear
    echo "============================="
    echo "   1Panel 安装与管理菜单"
    echo "============================="
    echo "1. 安装 1Panel"
    echo "2. 查看面板信息"
    echo "3. 修改密码"
    echo "4. 卸载 1Panel"
    echo "5. 退出"
    echo "============================="
    read -p "请输入选项 (1-5): " option
    case $option in
        1) install_1panel ;;
        2) view_panel_info ;;
        3) update_password ;;
        4) uninstall_1panel ;;
        5) exit 0 ;;
        *) echo "无效选项，请重新输入"; show_menu ;;
    esac
}

# 安装 1Panel
function install_1panel() {
    echo "正在安装 1Panel..."
    
    # 更新系统
    sudo apt-get update -y
    sudo apt-get upgrade -y

    # 安装必要依赖
    sudo apt-get install -y curl wget

    # 下载并安装 1Panel 官方脚本
    curl -sSL https://resource.1panel.pro/quick_start.sh -o quick_start.sh && bash quick_start.sh

    # 提示安装完成
    echo "1Panel 安装完成！"
    echo "------------------------------------------------"
    echo "1Panel 服务已启动。"
    echo "访问面板: http://<你的服务器IP>:8888"
    echo "------------------------------------------------"
    show_menu
}

# 查看面板信息
function view_panel_info() {
    echo "要查看面板信息，请运行以下命令:"
    echo "1pctl user-info"
    echo "------------------------------------------------"
    show_menu
}

# 修改密码
function update_password() {
    echo "要修改密码，请运行以下命令:"
    echo "1pctl update password"
    echo "------------------------------------------------"
    show_menu
}

# 卸载 1Panel
function uninstall_1panel() {
    echo "正在卸载 1Panel..."

    # 卸载 1Panel
    curl -sSL https://resource.1panel.pro/uninstall.sh | bash

    # 提示卸载完成
    echo "1Panel 卸载完成！"
    echo "------------------------------------------------"
    show_menu
}

# 显示菜单
show_menu









