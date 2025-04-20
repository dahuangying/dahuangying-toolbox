#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误：此脚本必须使用 root 权限运行！${NC}"
        exit 1
    fi
}

# 获取1Panel信息（使用 1pctl user-info）
get_panel_info() {
    echo -e "${GREEN}▶ 正在获取面板信息...${NC}"
    PANEL_INFO=$(1pctl user-info 2>/dev/null)

    if [ -z "$PANEL_INFO" ]; then
        echo -e "${RED}✖ 无法获取信息，请检查1Panel是否运行！${NC}"
        return 1
    fi

    # 提取关键信息
    PANEL_USER=$(echo "$PANEL_INFO" | grep -oP '"username":"\K[^"]+')
    PANEL_PASS=$(echo "$PANEL_INFO" | grep -oP '"password":"\K[^"]+')
    PANEL_PORT=$(ss -tulnp | grep 1panel | awk '{print $5}' | awk -F':' '{print $NF}')
    PUBLIC_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    PANEL_PATH=$(grep -oP 'server.context-path=\K\S+' /opt/1panel/conf/app.conf 2>/dev/null || echo "/")

    # 输出信息
    echo -e "\n${BLUE}========== 1Panel 访问信息 ==========${NC}"
    echo -e "${GREEN}● 面板地址：${NC}"
    echo -e "  外部访问: ${YELLOW}http://${PUBLIC_IP}:${PANEL_PORT}${PANEL_PATH}${NC}"
    echo -e "  内部访问: ${YELLOW}http://$(hostname -I | awk '{print $1}'):${PANEL_PORT}${PANEL_PATH}${NC}"
    echo -e "${GREEN}● 面板用户: ${YELLOW}${PANEL_USER}${NC}"
    echo -e "${GREEN}● 面板密码: ${YELLOW}${PANEL_PASS}${NC}"
    echo -e "${BLUE}● 修改密码命令: ${GREEN}1pctl update password${NC}"
}

# 修改密码
change_password() {
    echo -e "${YELLOW}▶ 正在修改密码...${NC}"
    1pctl update password
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✔ 密码修改成功！${NC}"
        echo -e "${YELLOW}提示：请使用新密码登录面板。${NC}"
    else
        echo -e "${RED}✖ 密码修改失败！请手动执行 '1pctl update password'${NC}"
    fi
}

# 安装1Panel
install_1panel() {
    echo -e "${GREEN}▶ 正在安装 1Panel...${NC}"
    curl -sSL https://resource.1panel.pro/quick_start.sh -o quick_start.sh && bash quick_start.sh
    [ $? -eq 0 ] && echo -e "${GREEN}✔ 安装成功！${NC}" && get_panel_info || echo -e "${RED}✖ 安装失败！${NC}"
}

# 卸载1Panel
uninstall_1panel() {
    read -p "${RED}⚠ 确认卸载？此操作不可逆！(y/N): ${NC}" confirm
    [[ "$confirm" =~ [yY] ]] && 1pctl uninstall && echo -e "${GREEN}✔ 已卸载${NC}" || echo -e "${YELLOW}已取消${NC}"
}

# 主菜单
main_menu() {
    clear
    echo -e "${BLUE}===== 1Panel 终极管理脚本 ====="
    echo "1. 安装 1Panel"
    echo "2. 卸载 1Panel"
    echo "3. 修改密码"
    echo "4. 查看面板信息"
    echo "0. 退出"
    echo -e "==============================${NC}"
    read -p "请输入选项: " choice

    case $choice in
        1) install_1panel ;;
        2) uninstall_1panel ;;
        3) change_password ;;
        4) get_panel_info ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项！${NC}" ;;
    esac
    read -p "按回车返回主菜单..."
    main_menu
}

# 启动脚本
check_root
main_menu
