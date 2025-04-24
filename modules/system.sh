#!/bin/bash

# 设置颜色
GREEN="\033[0;32m"  # 绿色
NC="\033[0m"        # 重置颜色

# 检查root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误：此脚本必须以root权限运行！${NC}" >&2
        exit 1
    fi
}

# 显示主菜单
show_menu() {
    clear
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱菜单-Docker 系统工具${NC}"
    echo -e "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}====================================================${NC}"
    echo -e "1. 启用ROOT密码登录模式"
    echo -e "2. 禁用ROOT密码登录模式"
    echo -e "3. 修改ROOT登录密码"
    echo -e "${BLUE}---------------------------------------${NC}"
    echo -e "4. 查看端口占用状态"
    echo -e "5. 开放所有端口${RED}（危险）${NC}"
    echo -e "6. 关闭所有端口${RED}（危险）${NC}"
    echo -e "7. 开放指定端口"
    echo -e "8. 关闭指定端口"
    echo -e "${BLUE}---------------------------------------${NC}"
    echo -e "9. 文件权限设置"
    echo -e "10. 重置文件权限为默认"
    echo -e "${BLUE}---------------------------------------${NC}"
    echo -e "0. 退出"
    echo -n "请输入选项数字: "
}

# SSH服务管理
restart_ssh_service() {
    if systemctl list-unit-files | grep -q 'sshd.service'; then
        systemctl restart sshd
    elif systemctl list-unit-files | grep -q 'ssh.service'; then
        systemctl restart ssh
    elif [ -f /etc/init.d/ssh ]; then
        /etc/init.d/ssh restart
    else
        echo -e "${RED}无法确定SSH服务名称，请手动重启！${NC}"
        return 1
    fi
}

# 1. 启用ROOT密码登录
enable_root_login() {
    echo -e "${YELLOW}=== 启用ROOT密码登录模式 ===${NC}"
    
    # 使用系统passwd命令修改密码
    echo -e "${BLUE}请设置ROOT用户的新密码：${NC}"
    passwd root
    if [ $? -ne 0 ]; then
        echo -e "${RED}密码设置失败，请检查！${NC}"
        return 1
    fi

    # 启用SSH的ROOT登录
    echo -e "${BLUE}正在启用SSH的ROOT登录...${NC}"
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

    # 重启SSH服务（兼容不同系统）
    if systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null; then
        echo -e "${GREEN}ROOT密码登录已成功启用！${NC}"
    else
        echo -e "${RED}SSH服务重启失败，请手动执行：systemctl restart sshd${NC}"
        return 1
    fi
}

# 2. 禁用ROOT密码登录
disable_root_login() {
    echo -e "${YELLOW}=== 禁用ROOT密码登录 ===${NC}"
    sed -i 's/^#*PermitRootLogin.*/#PermitRootLogin no/g' /etc/ssh/sshd_config
    restart_ssh_service
    echo -e "${GREEN}ROOT密码登录已禁用！${NC}"
}

# 3. 修改ROOT密码
change_root_password() {
    echo -e "${YELLOW}=== 修改ROOT密码 ===${NC}"
    passwd root
    [ $? -eq 0 ] && echo -e "${GREEN}密码修改成功！${NC}" || echo -e "${RED}密码修改失败！${NC}"
}

# 4. 查看端口状态
show_port_status() {
    echo -e "${YELLOW}=== 端口占用状态 ===${NC}"
    echo -e "${BLUE}活动连接：${NC}"
    ss -tulnp
    echo -e "\n${BLUE}防火墙规则：${NC}"
    if command -v ufw >/dev/null; then
        ufw status
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --list-all
    else
        iptables -L -n
    fi
}

# 5. 开放所有端口
open_all_ports() {
    echo -e "${RED}=== 警告：这将开放所有端口！ ===${NC}"
    read -p "确定继续吗？(y/n): " confirm
    [ "$confirm" != "y" ] && return
    
    if command -v ufw >/dev/null; then
        ufw disable
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --zone=public --add-port=1-65535/tcp --permanent
        firewall-cmd --zone=public --add-port=1-65535/udp --permanent
        firewall-cmd --reload
    else
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -F
    fi
    echo -e "${GREEN}所有端口已开放！${NC}"
}

# 6. 关闭所有端口
close_all_ports() {
    echo -e "${RED}=== 警告：这将关闭所有端口！ ===${NC}"
    read -p "确定继续吗？(y/n): " confirm
    [ "$confirm" != "y" ] && return
    
    if command -v ufw >/dev/null; then
        ufw enable
        ufw default deny
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --zone=public --remove-port=1-65535/tcp --permanent
        firewall-cmd --zone=public --remove-port=1-65535/udp --permanent
        firewall-cmd --reload
    else
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
        iptables -F
    fi
    echo -e "${GREEN}所有端口已关闭！${NC}"
    echo -e "${YELLOW}注意：您可能需要通过控制台重新开放SSH端口！${NC}"
}

# 7. 开放指定端口
open_specific_port() {
    echo -e "${YELLOW}=== 开放指定端口 ===${NC}"
    read -p "输入端口号: " port
    read -p "协议类型(tcp/udp，默认tcp): " protocol
    protocol=${protocol:-tcp}
    
    [[ ! $port =~ ^[0-9]+$ ]] && echo -e "${RED}无效端口号！${NC}" && return
    [[ $port -lt 1 || $port -gt 65535 ]] && echo -e "${RED}端口范围1-65535！${NC}" && return
    
    if command -v ufw >/dev/null; then
        ufw allow $port/$protocol
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --zone=public --add-port=$port/$protocol --permanent
        firewall-cmd --reload
    else
        iptables -A INPUT -p $protocol --dport $port -j ACCEPT
    fi
    echo -e "${GREEN}端口 $port/$protocol 已开放！${NC}"
}

# 8. 关闭指定端口
close_specific_port() {
    echo -e "${YELLOW}=== 关闭指定端口 ===${NC}"
    read -p "输入端口号: " port
    read -p "协议类型(tcp/udp，默认tcp): " protocol
    protocol=${protocol:-tcp}
    
    [[ ! $port =~ ^[0-9]+$ ]] && echo -e "${RED}无效端口号！${NC}" && return
    
    if command -v ufw >/dev/null; then
        ufw delete allow $port/$protocol
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --zone=public --remove-port=$port/$protocol --permanent
        firewall-cmd --reload
    else
        iptables -D INPUT -p $protocol --dport $port -j ACCEPT
    fi
    echo -e "${GREEN}端口 $port/$protocol 已关闭！${NC}"
}

# 9. 文件权限设置
file_permission_settings() {
    while true; do
        clear
        echo -e "${GREEN}=== 文件权限设置 ===${NC}"
        echo -e "1. rwxr-xr-x (755)"
        echo -e "2. rw-r--r-- (644)"
        echo -e "3. rwx------ (700)"
        echo -e "4. r-xr-xr-x (555)"
        echo -e "5. r-------- (400)"
        echo -e "0. 返回主菜单"
        echo -n "请选择权限模式: "
        read choice
        
        case $choice in
            1) perm=755; desc="rwxr-xr-x (755)"; ;;
            2) perm=644; desc="rw-r--r-- (644)"; ;;
            3) perm=700; desc="rwx------ (700)"; ;;
            4) perm=555; desc="r-xr-xr-x (555)"; ;;
            5) perm=400; desc="r-------- (400)"; ;;
            0) return ;;
            *) echo -e "${RED}无效选择！${NC}"; sleep 1; continue ;;
        esac
        
        echo -n "输入文件/目录路径（回车取消）: "
        read path
        [ -z "$path" ] && continue
        [ ! -e "$path" ] && echo -e "${RED}路径不存在！${NC}" && sleep 1 && continue
        
        echo -e "即将设置: ${YELLOW}$path${NC} -> ${BLUE}$desc${NC}"
        read -p "确认操作？(y/n): " confirm
        [ "$confirm" != "y" ] && continue
        
        if [ -d "$path" ]; then
            find "$path" -type d -exec chmod $perm {} \; 2>/dev/null
            find "$path" -type f -exec chmod $perm {} \; 2>/dev/null
        else
            chmod $perm "$path"
        fi
        echo -e "${GREEN}权限设置完成！${NC}"
        sleep 2
    done
}

# 10. 重置文件权限
reset_file_permissions() {
    echo -e "${YELLOW}=== 重置文件权限 ===${NC}"
    read -p "输入要重置的路径: " path
    [ ! -e "$path" ] && echo -e "${RED}路径不存在！${NC}" && return
    
    echo -e "${RED}警告：这将递归重置所有权限！${NC}"
    read -p "确认重置？(y/n): " confirm
    [ "$confirm" != "y" ] && return
    
    if [ -d "$path" ]; then
        find "$path" -type d -exec chmod 755 {} \; 2>/dev/null
        find "$path" -type f -exec chmod 644 {} \; 2>/dev/null
    else
        chmod 644 "$path"
    fi
    echo -e "${GREEN}权限已重置为默认！${NC}"
}

# 主循环
main() {
    check_root
    while true; do
        show_menu
        read option
        case $option in
            1) enable_root_login ;;
            2) disable_root_login ;;
            3) change_root_password ;;
            4) show_port_status ;;
            5) open_all_ports ;;
            6) close_all_ports ;;
            7) open_specific_port ;;
            8) close_specific_port ;;
            9) file_permission_settings ;;
            10) reset_file_permissions ;;
            0) echo -e "${GREEN}脚本已退出${NC}"; exit 0 ;;
            *) echo -e "${RED}无效选项！${NC}"; sleep 1 ;;
        esac
        echo -e "\n${GREEN}操作完成,按回车键继续...${NC}"
    done
}

# 暂停，按任意键继续
pause() {
    # 设置绿色文本颜色
    echo -e "\033[0;32m操作完成，按任意键继续...\033[0m"
    read -n 1 -s -r
}

# 启动脚本
show_menu


