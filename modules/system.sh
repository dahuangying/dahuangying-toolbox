#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误：此脚本必须以root权限运行！${NC}" >&2
        exit 1
    fi
}

# 启用ROOT密码登录（强制设置密码）
enable_root_login() {
    echo -e "${YELLOW}=== 启用ROOT密码登录模式 ===${NC}"
    
    # 要求用户设置密码
    while true; do
        read -sp "请输入ROOT新密码: " root_pass
        echo
        if [ -z "$root_pass" ]; then
            echo -e "${RED}错误：密码不能为空！${NC}"
            continue
        fi
        
        read -sp "再次确认ROOT密码: " root_pass_confirm
        echo
        if [ "$root_pass" != "$root_pass_confirm" ]; then
            echo -e "${RED}错误：两次输入的密码不一致！${NC}"
        else
            break
        fi
    done

    # 设置密码并启用ROOT登录
    echo "root:$root_pass" | chpasswd
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
    
    # 重启SSH服务（兼容不同系统）
    if systemctl list-unit-files | grep -q 'sshd.service'; then
        systemctl restart sshd
    elif systemctl list-unit-files | grep -q 'ssh.service'; then
        systemctl restart ssh
    else
        service ssh restart
    fi
    
    echo -e "${GREEN}ROOT密码已设置，并启用密码登录模式！${NC}"
}

# 文件权限设置子菜单
file_permission_settings() {
    while true; do
        clear
        echo -e "${GREEN}=== 文件权限设置选项 ===${NC}"
        echo -e "1. rwxr-xr-x (755) - 目录标准权限"
        echo -e "2. rw-r--r-- (644) - 文件标准权限"
        echo -e "3. rwx------ (700) - 用户私有权限"
        echo -e "4. r-xr-xr-x (555) - 只读执行权限"
        echo -e "5. r-------- (400) - 只读权限"
        echo -e "0. 返回主菜单"
        echo -n "请选择权限模式: "
        read perm_choice

        case $perm_choice in
            1) perm_mode=755; perm_desc="rwxr-xr-x (755)"; ;;
            2) perm_mode=644; perm_desc="rw-r--r-- (644)"; ;;
            3) perm_mode=700; perm_desc="rwx------ (700)"; ;;
            4) perm_mode=555; perm_desc="r-xr-xr-x (555)"; ;;
            5) perm_mode=400; perm_desc="r-------- (400)"; ;;
            0) return ;;
            *) echo -e "${RED}无效选项，请重新输入！${NC}"; sleep 1; continue ;;
        esac

        # 输入目标路径
        echo -n "请输入要设置权限的目录/文件路径（直接回车返回）: "
        read target_path

        # 如果用户直接回车，返回上一级菜单
        if [ -z "$target_path" ]; then
            echo -e "${YELLOW}已取消操作，返回菜单。${NC}"
            return
        fi

        # 检查路径是否存在
        if [ ! -e "$target_path" ]; then
            echo -e "${RED}错误：路径不存在！${NC}"
            sleep 2
            continue
        fi

        # 确认操作
        echo -e "${YELLOW}即将设置权限: ${perm_desc} -> ${target_path}${NC}"
        read -p "确认执行？(y/n): " confirm
        if [ "$confirm" != "y" ]; then
            echo -e "${YELLOW}已取消操作。${NC}"
            continue
        fi

        # 执行权限设置
        echo -e "${YELLOW}正在设置权限...${NC}"
        if [ -d "$target_path" ]; then
            find "$target_path" -type d -exec chmod $perm_mode {} \; 2>/dev/null
            find "$target_path" -type f -exec chmod $perm_mode {} \; 2>/dev/null
        else
            chmod $perm_mode "$target_path"
        fi

        echo -e "${GREEN}权限设置完成！${NC}"
        sleep 2
    done
}

# 主菜单
main_menu() {
    while true; do
        clear
        echo -e "${GREEN}=== 主菜单 ===${NC}"
        echo -e "1. 启用ROOT密码登录模式"
        echo -e "2. 文件权限设置"
        echo -e "0. 退出脚本"
        echo -n "请输入选项: "
        read choice

        case $choice in
            1) enable_root_login ;;
            2) file_permission_settings ;;
            0) echo -e "${GREEN}退出脚本。${NC}"; exit 0 ;;
            *) echo -e "${RED}无效选项，请重新输入！${NC}"; sleep 1 ;;
        esac
    done
}

# 启动脚本
check_root
main_menu


