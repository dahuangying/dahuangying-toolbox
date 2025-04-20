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

    # 询问用户是否需要修改密码
    read -p "是否修改面板密码？[y/n]: " modify_password
    if [[ "$modify_password" == "y" || "$modify_password" == "Y" ]]; then
        # 用户输入新密码
        read -sp "请输入新密码: " new_password
        echo
        read -sp "请再次输入新密码确认: " confirm_password
        echo

        # 判断两次密码是否一致
        if [[ "$new_password" == "$confirm_password" ]]; then
            # 修改密码
            echo "$new_password" | 1pctl update password
            echo "密码修改成功！"
        else
            echo "密码确认不一致，请重新尝试。"
        fi
    fi

    sleep 2
    show_menu
}

# 函数：卸载 1Panel
uninstall_panel() {
    read -p "您确定要卸载 1Panel 吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "正在卸载 1Panel..."
        # 执行卸载命令，假设删除安装路径和配置文件
        rm -rf /root/1panel_installation
        rm -f $PANEL_CONFIG_PATH
        echo "1Panel 卸载完成！"
    else
        echo "取消卸载。"
    fi
    sleep 2
    show_menu
}

# 启动脚本
show_menu


