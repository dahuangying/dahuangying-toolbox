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

# 显示菜单
show_menu() {
    clear
    echo -e "${GREEN}=======================================${NC}"
    echo -e "          Linux 系统管理一键脚本         "
    echo -e "${GREEN}=======================================${NC}"
    echo -e "1. 启用ROOT密码登录模式"
    echo -e "2. 禁用ROOT密码登录模式"
    echo -e "3. 修改ROOT登录密码"
    echo -e "${GREEN}---------------------------------------${NC}"
    echo -e "4. 查看端口占用状态"
    echo -e "5. 开放所有端口（谨慎使用）"
    echo -e "6. 关闭所有端口（谨慎使用）"
    echo -e "7. 开放指定端口"
    echo -e "8. 关闭指定端口"
    echo -e "${GREEN}---------------------------------------${NC}"
    echo -e "9. 文件权限安全设置（755/644）"
    echo -e "10. 重置文件权限为默认"
    echo -e "${GREEN}---------------------------------------${NC}"
    echo -e "0. 退出脚本"
    echo -e "${GREEN}=======================================${NC}"
    echo -n "请输入选项数字: "
}

# 启用ROOT密码登录
enable_root_login() {
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
    systemctl restart sshd
    echo -e "${GREEN}已启用ROOT密码登录模式${NC}"
}

# 禁用ROOT密码登录
disable_root_login() {
    sed -i 's/^PermitRootLogin.*/#PermitRootLogin no/g' /etc/ssh/sshd_config
    systemctl restart sshd
    echo -e "${GREEN}已禁用ROOT密码登录模式${NC}"
}

# 修改ROOT密码
change_root_password() {
    passwd root
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}ROOT密码修改成功${NC}"
    else
        echo -e "${RED}ROOT密码修改失败${NC}"
    fi
}

# 查看端口占用
show_port_status() {
    echo -e "${YELLOW}活动的监听端口：${NC}"
    ss -tulnp | grep LISTEN
    echo -e "\n${YELLOW}防火墙状态：${NC}"
    if command -v ufw &> /dev/null; then
        ufw status numbered
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --list-all
    else
        iptables -L -n
    fi
}

# 开放所有端口（危险操作）
open_all_ports() {
    echo -e "${RED}警告：这将开放所有端口，存在重大安全风险！${NC}"
    read -p "确定要继续吗？(y/n): " confirm
    if [ "$confirm" == "y" ]; then
        if command -v ufw &> /dev/null; then
            ufw disable
        elif command -v firewall-cmd &> /dev/null; then
            firewall-cmd --zone=public --add-port=1-65535/tcp --permanent
            firewall-cmd --zone=public --add-port=1-65535/udp --permanent
            firewall-cmd --reload
        else
            iptables -P INPUT ACCEPT
            iptables -P FORWARD ACCEPT
            iptables -P OUTPUT ACCEPT
            iptables -F
        fi
        echo -e "${GREEN}已开放所有端口${NC}"
    else
        echo -e "${YELLOW}操作已取消${NC}"
    fi
}

# 关闭所有端口（危险操作）
close_all_ports() {
    echo -e "${RED}警告：这将关闭所有端口，可能导致系统无法远程访问！${NC}"
    read -p "确定要继续吗？(y/n): " confirm
    if [ "$confirm" == "y" ]; then
        if command -v ufw &> /dev/null; then
            ufw enable
            ufw default deny
        elif command -v firewall-cmd &> /dev/null; then
            firewall-cmd --zone=public --remove-port=1-65535/tcp --permanent
            firewall-cmd --zone=public --remove-port=1-65535/udp --permanent
            firewall-cmd --reload
        else
            iptables -P INPUT DROP
            iptables -P FORWARD DROP
            iptables -P OUTPUT ACCEPT
            iptables -F
        fi
        echo -e "${GREEN}已关闭所有端口${NC}"
        echo -e "${YELLOW}注意：您可能需要通过控制台重新开放SSH端口！${NC}"
    else
        echo -e "${YELLOW}操作已取消${NC}"
    fi
}

# 开放指定端口
open_specific_port() {
    read -p "请输入要开放的端口号: " port
    read -p "请输入协议类型(tcp/udp，默认tcp): " protocol
    protocol=${protocol:-tcp}
    
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${RED}错误：端口号必须是1-65535之间的数字${NC}"
        return
    fi
    
    if [ "$protocol" != "tcp" ] && [ "$protocol" != "udp" ]; then
        echo -e "${RED}错误：协议类型必须是tcp或udp${NC}"
        return
    fi
    
    if command -v ufw &> /dev/null; then
        ufw allow $port/$protocol
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --zone=public --add-port=$port/$protocol --permanent
        firewall-cmd --reload
    else
        iptables -A INPUT -p $protocol --dport $port -j ACCEPT
    fi
    
    echo -e "${GREEN}已开放端口 $port/$protocol${NC}"
}

# 关闭指定端口
close_specific_port() {
    read -p "请输入要关闭的端口号: " port
    read -p "请输入协议类型(tcp/udp，默认tcp): " protocol
    protocol=${protocol:-tcp}
    
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${RED}错误：端口号必须是1-65535之间的数字${NC}"
        return
    fi
    
    if [ "$protocol" != "tcp" ] && [ "$protocol" != "udp" ]; then
        echo -e "${RED}错误：协议类型必须是tcp或udp${NC}"
        return
    fi
    
    if command -v ufw &> /dev/null; then
        ufw delete allow $port/$protocol
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --zone=public --remove-port=$port/$protocol --permanent
        firewall-cmd --reload
    else
        iptables -D INPUT -p $protocol --dport $port -j ACCEPT
    fi
    
    echo -e "${GREEN}已关闭端口 $port/$protocol${NC}"
}

# 文件权限安全设置
set_file_permissions() {
    echo -e "${YELLOW}正在设置安全文件权限...${NC}"
    
    # 设置目录权限为755
    find / -type d -exec chmod 755 {} \; 2>/dev/null
    
    # 设置文件权限为644
    find / -type f -exec chmod 644 {} \; 2>/dev/null
    
    # 特殊目录权限
    chmod 700 /etc/ssh/ssh_host*key
    chmod 755 /etc /etc/ssh /var/log
    
    echo -e "${GREEN}文件权限已设置为安全模式(755/644)${NC}"
}

# 重置文件权限为默认
reset_file_permissions() {
    echo -e "${YELLOW}正在重置文件权限为默认值...${NC}"
    
    # 重置目录权限为755
    find / -type d -exec chmod 755 {} \; 2>/dev/null
    
    # 重置文件权限为644
    find / -type f -exec chmod 644 {} \; 2>/dev/null
    
    # 特殊文件权限
    chmod 755 /bin/* /sbin/* /usr/bin/* /usr/sbin/*
    chmod 755 /usr/local/bin/* /usr/local/sbin/*
    chmod 644 /etc/*.conf /etc/hosts /etc/resolv.conf
    
    echo -e "${GREEN}文件权限已重置为默认值${NC}"
}

# 主循环
main() {
    check_root
    
    while true; do
        show_menu
        read choice
        case $choice in
            1) enable_root_login ;;
            2) disable_root_login ;;
            3) change_root_password ;;
            4) show_port_status ;;
            5) open_all_ports ;;
            6) close_all_ports ;;
            7) open_specific_port ;;
            8) close_specific_port ;;
            9) set_file_permissions ;;
            10) reset_file_permissions ;;
            0) echo -e "${GREEN}退出脚本${NC}"; exit 0 ;;
            *) echo -e "${RED}无效选项，请重新输入${NC}" ;;
        esac
        echo -e "\n按Enter键继续..."
        read
    done
}

main


