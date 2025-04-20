#!/bin/bash

# 1Panel 安装管理脚本
# Version: 1.0
# Author: ChatGPT

# 配置项
PANEL_URL="https://resource.1panel.pro/quick_start.sh"
INSTALL_PATH="/root/1panel_installation"
PANEL_CONFIG_PATH="/root/1panel_config.txt"  # 保存配置信息的文件

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

    # 这里假设安装后，1Panel的配置文件会生成，并包含必要的设置
    # 假设配置文件内容如下：
    # port=8080
    # suffix=admin
    # user=admin
    # password=default_password
    echo "请输入安装时设置的端口号（如：8080）: "
    read PANEL_PORT
    echo "请输入安装时设置的URL后缀（如：admin）: "
    read URL_SUFFIX
    echo "请输入安装时设置的面板用户名（如：admin）: "
    read PANEL_USER
    echo "请输入安装时设置的面板密码（如：default_password）: "
    read PANEL_PASS

    # 保存配置到文件
    echo "port=$PANEL_PORT" > $PANEL_CONFIG_PATH
    echo "suffix=$URL_SUFFIX" >> $PANEL_CONFIG_PATH
    echo "user=$PANEL_USER" >> $PANEL_CONFIG_PATH
    echo "password=$PANEL_PASS" >> $PANEL_CONFIG_PATH

    echo "1Panel 安装完成！"
    echo "请使用以下命令查看面板地址："
    echo "  面板地址: http://$(curl -s ifconfig.me):$PANEL_PORT/$URL_SUFFIX"
    echo "  面板用户: $PANEL_USER"
    echo "  面板密码: $PANEL_PASS"
    echo "您可以修改密码，使用命令：1pctl update password"
    sleep 2
    show_menu
}

# 函数：管理 1Panel
manage_panel() {
    echo "开始管理 1Panel..."

    # 获取 VPS 的公共 IP 地址
    VPS_IP=$(curl -s ifconfig.me)

    # 检查配置文件是否存在
    if [ ! -f "$PANEL_CONFIG_PATH" ]; then
        echo "配置文件未找到，请先安装 1Panel。"
        return
    fi

    # 从配置文件中读取端口号、后缀、用户和密码
    PANEL_PORT=$(grep "port" $PANEL_CONFIG_PATH | cut -d '=' -f2)
    URL_SUFFIX=$(grep "suffix" $PANEL_CONFIG_PATH | cut -d '=' -f2)
    PANEL_USER=$(grep "user" $PANEL_CONFIG_PATH | cut -d '=' -f2)
    PANEL_PASS=$(grep "password" $PANEL_CONFIG_PATH | cut -d '=' -f2)

    # 检查是否能正确获取配置
    if [[ -z "$PANEL_PORT" || -z "$URL_SUFFIX" || -z "$PANEL_USER" || -z "$PANEL_PASS" ]]; then
        echo "无法读取面板配置信息，请检查安装是否成功。"
        return
    fi

    # 输出面板管理信息
    echo "============================="
    echo "面板地址: http://$VPS_IP:$PANEL_PORT/$URL_SUFFIX"
    echo "面板用户: $PANEL_USER"
    echo "面板密码: $PANEL_PASS"
    echo "提示: 修改密码可执行命令: 1pctl update password"
    echo "============================="
    echo "如果要修改面板密码，请使用命令：1pctl update password"
    sleep 2
    show_menu
}

# 函数：卸载 1Panel
uninstall_panel() {
    read -p "您确定要卸载 1Panel 吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "正在卸载 1Panel..."
        # 执行卸载命令，假设删除安装路径和配置文件
        rm -rf $INSTALL_PATH
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


