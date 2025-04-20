#!/bin/bash

# 定义颜色变量
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

# 配置文件路径
PANEL_CONFIG="./panel_config.txt"

# 安装面板
install_1pane_panel() {
    echo -e "${GREEN}安装 1Pane 管理面板...${NC}"

    # 执行安装命令（你可以根据实际情况修改安装命令）
    curl -sSL https://resource.1panel.pro/quick_start.sh -o quick_start.sh && bash quick_start.sh
    
    # 提示用户安装完成后提供的面板地址和用户信息
    echo -e "${GREEN}1Panel 安装完成！${NC}"
    echo "安装完成后请通过以下信息访问面板："
    echo "面板地址: http://<VPS_IP>:12023/<SUFFIX>"
    echo "面板用户: <USER>"
    echo "面板密码: ********"
    
    # 假设安装过程中获取并保存这些信息
    read -p "请输入安装时的面板用户: " PANEL_USER
    read -sp "请输入安装时的面板密码: " PANEL_PASSWORD
    echo
    read -p "请输入安装时的端口 (默认 12023): " PANEL_PORT
    PANEL_PORT=${PANEL_PORT:-12023}
    read -p "请输入安装时的后缀 (例如 8aa2060c35): " INSTALL_SUFFIX

    # 将信息保存到配置文件
    echo "LOCAL_IP=$(curl -s ifconfig.me)" > "$PANEL_CONFIG"
    echo "PORT=$PANEL_PORT" >> "$PANEL_CONFIG"
    echo "SUFFIX=$INSTALL_SUFFIX" >> "$PANEL_CONFIG"
    echo "USER=$PANEL_USER" >> "$PANEL_CONFIG"
    echo "PASSWORD=$PANEL_PASSWORD" >> "$PANEL_CONFIG"

    echo -e "${GREEN}面板安装信息已保存！${NC}"
    pause
}

# 管理面板
manage_panel() {
    clear
    echo "1Panel 管理"

    # 从配置文件读取面板信息
    if [ -f "$PANEL_CONFIG" ]; then
        LOCAL_IP=$(grep 'LOCAL_IP' "$PANEL_CONFIG" | cut -d '=' -f2)
        PANEL_USER=$(grep 'USER' "$PANEL_CONFIG" | cut -d '=' -f2)
        PANEL_PASSWORD=$(grep 'PASSWORD' "$PANEL_CONFIG" | cut -d '=' -f2)
        PANEL_PORT=$(grep 'PORT' "$PANEL_CONFIG" | cut -d '=' -f2)
        INSTALL_SUFFIX=$(grep 'SUFFIX' "$PANEL_CONFIG" | cut -d '=' -f2)
    else
        echo "配置文件不存在！请先安装面板。"
        return
    fi
    
    # 构造面板地址
    PANEL_URL="http://$LOCAL_IP:$PANEL_PORT/$INSTALL_SUFFIX"
    
    # 显示面板信息
    echo "面板地址: $PANEL_URL"
    echo "面板用户: $PANEL_USER"
    echo "面板密码: ********"  # 为了安全起见不直接显示密码
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

# 卸载面板
uninstall_1pane_panel() {
    echo -e "${GREEN}卸载 1Pane 管理面板...${NC}"
    
    # 执行卸载命令（具体卸载命令可能根据面板不同而不同）
    curl -sSL https://resource.1panel.pro/uninstall.sh -o uninstall.sh && bash uninstall.sh
    
    # 删除配置文件
    rm -f "$PANEL_CONFIG"
    
    echo -e "${GREEN}1Pane 面板已成功卸载！${NC}"
    pause
}

# 主菜单
show_menu() {
    clear
    echo "============================="
    echo "1. 安装 1Pane 管理面板"
    echo "2. 管理 1Pane 管理面板"
    echo "3. 卸载 1Pane 管理面板"
    echo "0. 退出"
    echo "============================="
    read -p "请输入你的选择: " choice

    case $choice in
        1) install_1pane_panel ;;
        2) manage_panel ;;
        3) uninstall_1pane_panel ;;
        0) exit 0 ;;
        *) echo "无效选择，请重新选择" && sleep 2 && show_menu ;;
    esac
}

# 暂停函数
pause() {
    read -p "按任意键继续..." -n 1 -s
}

# 入口
show_menu
