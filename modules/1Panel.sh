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

# 安装1Panel
install_1panel() {
    echo -e "${GREEN}▶ 正在安装 1Panel...${NC}"
    curl -sSL https://resource.1panel.pro/quick_start.sh -o quick_start.sh && bash quick_start.sh

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✔ 1Panel 安装成功！${NC}"
        show_info
    else
        echo -e "${RED}✖ 安装失败，请检查日志！${NC}"
        exit 1
    fi
}

# 卸载1Panel（需确认）
uninstall_1panel() {
    echo -e "${RED}⚠ 警告：这将彻底卸载 1Panel 并删除所有数据！${NC}"
    read -p "确定要继续吗？(y/N): " confirm
    if [[ "$confirm" =~ [yY] ]]; then
        echo -e "${YELLOW}▶ 正在卸载 1Panel...${NC}"
        1pctl uninstall
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✔ 1Panel 已卸载！${NC}"
        else
            echo -e "${RED}✖ 卸载失败，请手动执行 '1pctl uninstall'${NC}"
        fi
    else
        echo -e "${YELLOW}已取消卸载。${NC}"
    fi
}

# 修改面板密码
change_password() {
    echo -e "${YELLOW}▶ 正在修改密码...${NC}"
    1pctl update password
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✔ 密码修改成功！${NC}"
        echo -e "${BLUE}提示：新密码已生效，请妥善保存。${NC}"
    else
        echo -e "${RED}✖ 密码修改失败！${NC}"
    fi
}

# 显示面板信息
show_info() {
    echo -e "\n${BLUE}========== 1Panel 访问信息 ==========${NC}"

    # 获取关键配置
    PORT=$(grep "server.port" /opt/1panel/conf/app.conf 2>/dev/null | awk -F'=' '{print $2}')
    CONTEXT_PATH=$(grep "server.context-path" /opt/1panel/conf/app.conf 2>/dev/null | awk -F'=' '{print $2}')
    [ -z "$CONTEXT_PATH" ] && CONTEXT_PATH="/"

    # 获取IP地址
    PUBLIC_IP=$(curl -s ifconfig.me || echo "未知")
    PRIVATE_IP=$(hostname -I | awk '{print $1}' || echo "未知")

    # 获取密码
    PASSWORD=$(cat /opt/1panel/credentials/password.txt 2>/dev/null || echo "${RED}未找到密码文件${NC}")

    # 输出信息
    echo -e "${GREEN}● 面板地址：${NC}"
    echo -e "  外部访问: ${YELLOW}http://${PUBLIC_IP}:${PORT}${CONTEXT_PATH}${NC}"
    echo -e "  内部访问: ${YELLOW}http://${PRIVATE_IP}:${PORT}${CONTEXT_PATH}${NC}"
    echo -e "${GREEN}● 默认用户: ${YELLOW}admin${NC}"
    echo -e "${GREEN}● 当前密码: ${YELLOW}${PASSWORD}${NC}"
    echo -e "${BLUE}● 修改密码命令: ${GREEN}1pctl update password${NC}"
}

# 主菜单
main_menu() {
    clear
    echo -e "${BLUE}===== 1Panel 全能管理脚本 =====${NC}"
    echo "1. 安装 1Panel"
    echo "2. 卸载 1Panel"
    echo "3. 修改面板密码"
    echo "4. 查看面板信息"
    echo "0. 退出"
    echo -e "${BLUE}===============================${NC}"
    read -p "请输入选项 [0-4]: " choice

    case $choice in
        1) install_1panel ;;
        2) uninstall_1panel ;;
        3) change_password ;;
        4) show_info ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效输入，请重新选择！${NC}" ;;
    esac

    read -p "按回车键返回主菜单..." dummy
    main_menu
}

# 初始化
check_root
main_menu
