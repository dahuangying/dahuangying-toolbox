#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 检查root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}✖ 此脚本必须使用root权限运行！${NC}" >&2
        exit 1
    fi
}

# 获取面板信息（使用1pctl官方命令）
get_panel_info() {
    echo -e "\n${CYAN}🔍 正在获取面板信息...${NC}"
    
    if ! command -v 1pctl &> /dev/null; then
        echo -e "${RED}✖ 1Panel未安装或未在PATH中找到1pctl命令！${NC}"
        return 1
    fi

    # 获取核心信息
    PANEL_INFO=$(1pctl user-info 2>/dev/null)
    PANEL_STATUS=$(1pctl status 2>/dev/null)

    # 解析信息
    PANEL_USER=$(echo "$PANEL_INFO" | grep -oP '"username":"\K[^"]+')
    PANEL_PASS=$(echo "$PANEL_INFO" | grep -oP '"password":"\K[^"]+')
    PANEL_PORT=$(echo "$PANEL_STATUS" | grep -oP 'port \K[0-9]+')
    PANEL_PATH=$(grep -oP 'server.context-path=\K\S+' /opt/1panel/conf/app.conf 2>/dev/null || echo "/")
    PUBLIC_IP=$(curl -s --connect-timeout 3 ifconfig.me || hostname -I | awk '{print $1}')

    # 输出信息
    echo -e "${BLUE}════════ 1Panel 访问信息 ════════${NC}"
    echo -e "${GREEN}🌐 外部访问: ${YELLOW}http://${PUBLIC_IP}:${PANEL_PORT}${PANEL_PATH}${NC}"
    echo -e "${GREEN}🔒 内部访问: ${YELLOW}http://$(hostname -I | awk '{print $1}'):${PANEL_PORT}${PANEL_PATH}${NC}"
    echo -e "${GREEN}👤 面板用户: ${YELLOW}${PANEL_USER}${NC}"
    echo -e "${GREEN}🔑 面板密码: ${YELLOW}${PANEL_PASS}${NC}"
    echo -e "${BLUE}══════════════════════════════${NC}"
    echo -e "${CYAN}💡 提示: ${GREEN}1pctl update password ${CYAN}可修改密码${NC}"
}

# 安装1Panel（官方脚本）
install_1panel() {
    echo -e "${CYAN}📦 正在安装1Panel...${NC}"
    
    # 检查是否已安装
    if command -v 1pctl &> /dev/null; then
        echo -e "${YELLOW}⚠ 检测到1Panel已安装！${NC}"
        get_panel_info
        return
    fi

    # 官方安装命令
    if curl -sSL https://resource.1panel.pro/quick_start.sh -o /tmp/quick_start.sh && bash /tmp/quick_start.sh; then
        echo -e "${GREEN}✔ 安装成功！${NC}"
        rm -f /tmp/quick_start.sh
        get_panel_info
    else
        echo -e "${RED}✖ 安装失败！请检查：${NC}"
        echo "1. 网络连接是否正常"
        echo "2. 尝试手动执行: curl -sSL https://resource.1panel.pro/quick_start.sh | bash"
        exit 1
    fi
}

# 卸载1Panel（带二次确认）
uninstall_1panel() {
    echo -e "${RED}⚠️ █████████████████████████████████████${NC}"
    echo -e "${RED}⚠️  警告：将彻底卸载1Panel并删除所有数据！  ⚠️${NC}"
    echo -e "${RED}⚠️ █████████████████████████████████████${NC}"
    
    read -p "是否继续？(输入大写的YES确认): " confirm
    if [ "$confirm" != "YES" ]; then
        echo -e "${GREEN}✅ 已取消卸载${NC}"
        return
    fi

    echo -e "${CYAN}🗑️ 正在卸载1Panel...${NC}"
    if 1pctl uninstall; then
        echo -e "${GREEN}✔ 卸载完成！${NC}"
    else
        echo -e "${RED}✖ 卸载失败！请尝试手动执行: ${GREEN}1pctl uninstall${NC}"
    fi
}

# 修改密码（整合1pctl命令）
change_password() {
    echo -e "${CYAN}🔐 密码修改向导${NC}"
    echo -e "${YELLOW}请输入新密码（密码将隐藏输入）：${NC}"
    
    # 使用stty隐藏输入
    stty -echo
    read -p "新密码: " new_pass
    echo
    read -p "确认密码: " confirm_pass
    stty echo
    echo

    if [ "$new_pass" != "$confirm_pass" ]; then
        echo -e "${RED}✖ 两次输入密码不一致！${NC}"
        return 1
    fi

    if ! 1pctl update password <<< "$new_pass"; then
        echo -e "${RED}✖ 密码修改失败！请检查：${NC}"
        echo "1. 确保1Panel服务正在运行"
        echo "2. 密码复杂度要求：至少8位，含大小写字母和数字"
        return 1
    fi

    echo -e "${GREEN}✔ 密码修改成功！${NC}"
    echo -e "${BLUE}══════════════════════════════${NC}"
    echo -e "${CYAN}💡 新密码已生效，请妥善保存！${NC}"
}

# 主菜单
main_menu() {
    clear
    echo -e "${BLUE}════════ 1Panel 终极管理脚本 ════════${NC}"
    echo -e "${GREEN}1️⃣ 安装1Panel${NC}"
    echo -e "${RED}2️⃣ 卸载1Panel${NC}"
    echo -e "${YELLOW}3️⃣ 修改密码${NC}"
    echo -e "${CYAN}4️⃣ 查看信息${NC}"
    echo -e "${BLUE}0️⃣ 退出脚本${NC}"
    echo -e "${BLUE}════════════════════════════════════${NC}"
    
    read -p "请选择操作 [0-4]: " choice
    case $choice in
        1) install_1panel ;;
        2) uninstall_1panel ;;
        3) change_password ;;
        4) get_panel_info ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效输入！请输入数字0-4${NC}" ;;
    esac
    
    read -p "按回车键返回主菜单..."
    main_menu
}

# 初始化
check_root
main_menu



