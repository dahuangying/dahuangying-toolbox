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

    # 获取 VPS 的真实 IP 地址
    VPS_IP=$(curl -s ifconfig.me)  # 获取公网 IP 地址

    # 假设面板安装信息（端口和后缀）保存在配置文件 panel_config.txt 中
    PANEL_CONFIG="./panel_config.txt"
    
    if [ -f "$PANEL_CONFIG" ]; then
        # 从配置文件读取安装端口和后缀
        PANEL_PORT=$(grep 'PORT' "$PANEL_CONFIG" | cut -d '=' -f2)
        INSTALL_SUFFIX=$(grep 'SUFFIX' "$PANEL_CONFIG" | cut -d '=' -f2)
    else
        echo "配置文件不存在！请检查安装过程中的配置文件。"
        return
    fi
    
    # 构造面板地址
    PANEL_URL="http://$VPS_IP:$PANEL_PORT/$INSTALL_SUFFIX"
    
    # 显示面板信息
    echo "面板地址: $PANEL_URL"
    echo "面板用户: $(grep 'USER' "$PANEL_CONFIG" | cut -d '=' -f2)"
    echo "面板密码: ********"  # 默认显示 ********，不直接展示密码
    echo "提示: 修改密码可执行命令: 1pctl update password"
    
    echo "---------------------------"
    echo "1. 修改面板密码"
    echo "0. 返回菜单"
    echo "---------------------------"
    
    read -p "请输入你的选择: " choice

    case $choice in
        1)
            # 提示用户输入新密码
            read -sp "请输入新密码: " new_password
            echo
            read -sp "请再次确认新密码: " confirm_password
            echo

            # 检查密码是否匹配
            if [ "$new_password" == "$confirm_password" ]; then
                echo "正在修改密码..."
                # 执行修改密码命令
                1pctl update password "$new_password"
                echo "密码已成功修改！"
                # 更新配置文件中的密码信息
                sed -i "s/PASSWORD=.*/PASSWORD=$new_password/" "$PANEL_CONFIG"
            else
                echo "密码不匹配，请重新输入！"
            fi
            ;;
        0)
            show_menu
            ;;
        *)
            echo "无效选择，请重新选择" && sleep 2 && manage_panel
            ;;
    esac

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
