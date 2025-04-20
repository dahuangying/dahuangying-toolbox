#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 检查root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误：此脚本必须使用 root 权限运行！${NC}"
        exit 1
    fi
}

# 安装 1Panel
install_1panel() {
    echo -e "${GREEN}正在安装 1Panel...${NC}"
    curl -sSL https://resource.1panel.pro/quick_start.sh -o quick_start.sh && bash quick_start.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}1Panel 安装完成！${NC}"
        show_info
    else
        echo -e "${RED}安装失败，请检查网络或日志！${NC}"
    fi
}

# 显示面板信息
show_info() {
    echo -e "\n${YELLOW}===== 1Panel 管理信息 =====${NC}"

    # 获取面板地址（IP + 端口）
    PANEL_PORT=$(cat /opt/1panel/conf/app.conf | grep "server.port" | awk -F'=' '{print $2}')
    SERVER_IP=$(curl -s ifconfig.me || ip a | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n1)
    PANEL_URL="http://${SERVER_IP}:${PANEL_PORT}"

    # 获取用户名和密码
    USERNAME="admin"  # 默认用户名
    PASSWORD_FILE="/opt/1panel/credentials/password.txt"
    if [ -f "$PASSWORD_FILE" ]; then
        PASSWORD=$(cat "$PASSWORD_FILE")
    else
        PASSWORD="未找到密码文件，可能已修改！"
    fi

    # 输出信息
    echo -e "${GREEN}面板地址: ${YELLOW}${PANEL_URL}${NC}"
    echo -e "${GREEN}面板用户: ${YELLOW}${USERNAME}${NC}"
    echo -e "${GREEN}面板密码: ${YELLOW}${PASSWORD}${NC}"
    echo -e "${YELLOW}提示: 修改密码可执行命令: ${GREEN}1pctl update password${NC}"
}

# 修改面板密码
change_password() {
    echo -e "${YELLOW}正在修改 1Panel 密码...${NC}"
    1pctl update password
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}密码修改成功！${NC}"
    else
        echo -e "${RED}密码修改失败！${NC}"
    fi
}

# 卸载 1Panel
uninstall_1panel() {
    echo -e "${RED}警告：这将卸载 1Panel 并删除所有数据！${NC}"
    read -p "确认卸载？(y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo -e "${YELLOW}正在卸载 1Panel...${NC}"
        1pctl uninstall
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}1Panel 已卸载！${NC}"
        else
            echo -e "${RED}卸载失败，请手动检查！${NC}"
        fi
    else
        echo -e "${YELLOW}已取消卸载。${NC}"
    fi
}

# 主菜单
main_menu() {
    clear
    echo -e "${GREEN}===== 1Panel 管理脚本 =====${NC}"
    echo "1. 安装 1Panel"
    echo "2. 查看面板信息"
    echo "3. 修改面板密码"
    echo "4. 卸载 1Panel"
    echo "0. 退出"
    read -p "请输入选项 [0-4]: " choice

    case $choice in
        1) install_1panel ;;
        2) show_info ;;
        3) change_password ;;
        4) uninstall_1panel ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项！${NC}" ;;
    esac

    read -p "按回车键返回主菜单..." dummy
    main_menu
}

# 初始化
check_root
main_menu

