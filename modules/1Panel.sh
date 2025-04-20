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

# 获取1Panel配置（修复端口和路径获取问题）
get_1panel_config() {
    # 1. 获取端口（优先从 systemd 或配置文件读取）
    PANEL_PORT=$(grep -oP "server.port=\K[0-9]+" /opt/1panel/conf/app.conf 2>/dev/null || \
                 grep -oP "ListenPort\":\K[0-9]+" /opt/1panel/db/1Panel.db 2>/dev/null || \
                 echo "2096")  # 默认端口

    # 2. 获取安全入口路径（如 /qazwsx）
    PANEL_PATH=$(grep -oP "server.context-path=\K\S+" /opt/1panel/conf/app.conf 2>/dev/null || \
                grep -oP "SecurityEntrance\":\"\K[^\"]+" /opt/1panel/db/1Panel.db 2>/dev/null || \
                echo "")  # 默认为空

    # 3. 获取IP地址
    PUBLIC_IP=$(curl -s ifconfig.me || ip a | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -n1)
    PRIVATE_IP=$(hostname -I | awk '{print $1}')

    # 4. 获取密码
    PANEL_PASS=$(cat /opt/1panel/credentials/password.txt 2>/dev/null || \
                grep -oP "\\\"password\\\":\\\"\K[^\"]+" /opt/1panel/db/1Panel.db 2>/dev/null || \
                echo "${RED}未找到密码${NC}")
}

# 显示面板信息（修复版）
show_info() {
    get_1panel_config  # 调用配置获取函数

    echo -e "\n${BLUE}========== 1Panel 访问信息 ==========${NC}"
    echo -e "${GREEN}● 面板地址：${NC}"
    echo -e "  外部访问: ${YELLOW}http://${PUBLIC_IP}:${PANEL_PORT}${PANEL_PATH}${NC}"
    echo -e "  内部访问: ${YELLOW}http://${PRIVATE_IP}:${PANEL_PORT}${PANEL_PATH}${NC}"
    echo -e "${GREEN}● 默认用户: ${YELLOW}admin${NC}"
    echo -e "${GREEN}● 当前密码: ${YELLOW}${PANEL_PASS}${NC}"
    echo -e "${BLUE}● 修改密码命令: ${GREEN}1pctl update password${NC}"
}

# 安装1Panel
install_1panel() {
    echo -e "${GREEN}▶ 正在安装 1Panel...${NC}"
    curl -sSL https://resource.1panel.pro/quick_start.sh -o quick_start.sh && bash quick_start.sh
    [ $? -eq 0 ] && echo -e "${GREEN}✔ 安装成功！${NC}" && show_info || echo -e "${RED}✖ 安装失败！${NC}"
}

# 卸载1Panel
uninstall_1panel() {
    read -p "${RED}⚠ 确认卸载？此操作不可逆！(y/N): ${NC}" confirm
    [[ "$confirm" =~ [yY] ]] && 1pctl uninstall && echo -e "${GREEN}✔ 已卸载${NC}" || echo -e "${YELLOW}已取消${NC}"
}

# 修改密码
change_password() {
    1pctl update password && echo -e "${GREEN}✔ 密码已修改${NC}" || echo -e "${RED}✖ 修改失败${NC}"
}

# 主菜单
main_menu() {
    clear
    echo -e "${BLUE}===== 1Panel 管理脚本 ====="
    echo "1. 安装 1Panel"
    echo "2. 卸载 1Panel"
    echo "3. 修改密码"
    echo "4. 查看信息"
    echo "0. 退出"
    echo -e "==========================${NC}"
    read -p "请输入选项: " choice

    case $choice in
        1) install_1panel ;;
        2) uninstall_1panel ;;
        3) change_password ;;
        4) show_info ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项！${NC}" ;;
    esac
    read -p "按回车继续..."
    main_menu
}

# 启动脚本
check_root
main_menu
