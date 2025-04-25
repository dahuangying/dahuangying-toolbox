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
        echo -e "${RED}错误：此脚本必须以root权限运行！${NC}" >&2
        exit 1
    fi
}

# 安全输入（可回车退出）
safe_input() {
    local prompt="$1"
    local var_name="$2"
    local is_password="${3:-n}"
    
    echo -ne "${YELLOW}${prompt}（直接回车取消）: ${NC}"
    if [ "$is_password" = "y" ]; then
        read -s "$var_name"
        echo
    else
        read "$var_name"
    fi
    
    [ -z "${!var_name}" ] && return 1
    return 0
}

# 等待任意键继续
wait_key() {
    echo -e "\n${GREEN}按任意键返回主菜单...${NC}"
    read -n 1 -s -r
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
    echo -e "5. 开放所有端口（关键端口不开放）"
    echo -e "6. 关闭所有端口（保留 22.80.443）"
    echo -e "7. 开放指定端口"
    echo -e "8. 关闭指定端口"
    echo -e "${BLUE}---------------------------------------${NC}"
    echo -e "9. 文件权限设置"
    echo -e "10. 重置文件权限为默认"
    echo -e "${BLUE}---------------------------------------${NC}"
	echo -e "11. 查看防火墙状态"
    echo -e "12. 关闭防火墙"
    echo -e "13. 开启防火墙"
    echo -e "14. 禁止防火墙开机自启"
    echo -e "15. 恢复防火墙开机自启"
    echo -e "16. 一键关闭防火墙及开机自启"[2]+[4]
    echo -e "17. 一键开启防火墙及开机自启"[3]+[5]
    echo -e "${BLUE}---------------------------------------${NC}"
	echo -e "18. 重启服务器"
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
    echo -e "\n${YELLOW}=== 启用ROOT密码登录模式 ===${NC}"
    
    # 使用系统passwd命令修改密码
    echo -e "${BLUE}请设置ROOT用户的新密码（直接回车取消）：${NC}"
    passwd root
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}已取消密码设置${NC}"
        wait_key
        return
    fi

    # 启用SSH的ROOT登录
    echo -e "${BLUE}正在启用SSH的ROOT登录...${NC}"
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

    if restart_ssh_service; then
        echo -e "${GREEN}ROOT密码登录已成功启用！${NC}"
    else
        echo -e "${RED}SSH服务重启失败，请手动执行：systemctl restart sshd${NC}"
    fi
    wait_key
}

# 2. 禁用ROOT密码登录（增加确认）
disable_root_login() {
    echo -e "\n${RED}=== 禁用ROOT密码登录 ===${NC}"
    echo -e "${YELLOW}警告：禁用后将无法直接使用ROOT密码登录系统！${NC}"
    
    read -p "确定要禁用吗？(y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}已取消操作${NC}"
        wait_key
        return
    fi

    sed -i 's/^#*PermitRootLogin.*/#PermitRootLogin no/g' /etc/ssh/sshd_config
    
    if restart_ssh_service; then
        echo -e "${GREEN}ROOT密码登录已禁用！${NC}"
    else
        echo -e "${RED}SSH服务重启失败！${NC}"
    fi
    wait_key
}

# 3. 修改ROOT密码
change_root_password() {
    echo -e "\n${YELLOW}=== 修改ROOT密码 ===${NC}"
    echo -e "${BLUE}（直接回车取消操作）${NC}"
    passwd root
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}密码修改成功！${NC}"
    else
        echo -e "${YELLOW}已取消密码修改${NC}"
    fi
    wait_key
}

# 4. 查看端口状态
show_port_status() {
    echo -e "\n${YELLOW}=== 端口占用状态 ===${NC}"
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
    wait_key
}

# 5. 开放所有端口
open_all_ports() {
    echo -e "\n${RED}=== 警告：将开放非系统关键端口 ===${NC}"
    echo -e "${YELLOW}以下端口仍受保护："
    echo -e "• 22/tcp    (SSH)"
    echo -e "• 53/udp    (DNS)"
    echo -e "• 161/udp   (SNMP)"
    echo -e "• 389/tcp   (LDAP)"
    echo -e "• 3306/tcp  (MySQL)"
    echo -e "• 5432/tcp  (PostgreSQL)"
    echo -e "• 6379/tcp  (Redis)"
    echo -e "• 内部网络通信端口${NC}"
    
    read -p "确定继续吗？(y/n): " confirm
    [ "$confirm" != "y" ] && return
    
    if command -v ufw >/dev/null; then
        # UFW方案：先放行所有再保护关键端口
        ufw --force reset
        ufw default allow incoming
        ufw deny 22/tcp
        ufw deny 53/udp
        ufw deny 161/udp
        ufw deny 3306,5432,6379/tcp
        ufw enable
    elif command -v firewall-cmd >/dev/null; then
        # Firewalld方案：设置默认开放但拒绝关键端口
        firewall-cmd --zone=public --remove-rich-rule='rule' --permanent
        firewall-cmd --zone=public --add-rich-rule='rule port port="22" protocol="tcp" reject' --permanent
        firewall-cmd --zone=public --add-rich-rule='rule port port="3306" protocol="tcp" reject' --permanent
        firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="10.0.0.0/8" reject' --permanent
        firewall-cmd --reload
    else
        # iptables方案：先开放后限制
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -F
        # 保护关键端口
        iptables -A INPUT -p tcp --dport 22 -j DROP
        iptables -A INPUT -p tcp --dport 3306 -j DROP
        iptables -A INPUT -s 10.0.0.0/8 -j DROP
        # 保存规则
        iptables-save > /etc/iptables.rules 2>/dev/null
    fi
    
    echo -e "${GREEN}非关键端口已开放！${NC}"
    echo -e "${YELLOW}受保护的端口："
    ss -tulnp | grep -E '22|53|161|389|3306|5432|6379'
    wait_key
}

# 6. 关闭所有端口
close_all_ports() {
    echo -e "\n${RED}=== 警告：将关闭非必要端口（保留关键端口） ===${NC}"
    echo -e "${YELLOW}以下端口将被保留："
    echo -e "• 22/tcp    (SSH)"
    echo -e "• 80,443/tcp (HTTP/HTTPS)"
    echo -e "• 53/udp    (DNS)"
    echo -e "• 123/udp   (NTP时间同步)"
    echo -e "• 873/tcp   (Rsync)"
    echo -e "• 3000-4000/tcp (常见内部服务)${NC}"
    
    read -p "确定继续吗？(y/n): " confirm
    [ "$confirm" != "y" ] && return
    
    if command -v ufw >/dev/null; then
        # UFW方案：保留关键端口
        ufw --force reset
        ufw allow 22/tcp
        ufw allow 80,443/tcp
        ufw allow 53/udp
        ufw allow 123/udp
        ufw allow 873/tcp
        ufw allow 3000:4000/tcp
        ufw default deny incoming
        ufw enable
    elif command -v firewall-cmd >/dev/null; then
        # Firewalld方案
        firewall-cmd --zone=public --remove-port=1-65535/tcp --permanent
        firewall-cmd --zone=public --remove-port=1-65535/udp --permanent
        firewall-cmd --zone=public --add-port={22,80,443,873}/tcp --permanent
        firewall-cmd --zone=public --add-port={53,123}/udp --permanent
        firewall-cmd --zone=public --add-port=3000-4000/tcp --permanent
        firewall-cmd --zone=public --set-target=DROP --permanent
        firewall-cmd --reload
    else
        # iptables方案
        iptables -F
        # 保留关键端口
        iptables -A INPUT -p tcp -m multiport --dports 22,80,443,873,3000:4000 -j ACCEPT
        iptables -A INPUT -p udp --dport 53 -j ACCEPT
        iptables -A INPUT -p udp --dport 123 -j ACCEPT
        # 放行本地回环和内部通信
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT -s 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 -j ACCEPT
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
        iptables-save > /etc/iptables.rules 2>/dev/null
    fi
    
    echo -e "${GREEN}端口策略已更新！${NC}"
    echo -e "${YELLOW}当前开放端口："
    ss -tulnp | grep -E '22|80|443|53|123|873|3000|4000'
    wait_key
}

# 7. 开放指定端口
open_specific_port() {
    echo -e "\n${YELLOW}=== 开放指定端口 ===${NC}"
    if ! safe_input "输入端口号" "port"; then
        echo -e "${YELLOW}已取消操作${NC}"
        wait_key
        return
    fi
    
    if ! safe_input "协议类型(tcp/udp，默认tcp)" "protocol"; then
        protocol="tcp"
    fi
    protocol=${protocol:-tcp}
    
    [[ ! $port =~ ^[0-9]+$ ]] && echo -e "${RED}无效端口号！${NC}" && wait_key && return
    [[ $port -lt 1 || $port -gt 65535 ]] && echo -e "${RED}端口范围1-65535！${NC}" && wait_key && return
    
    if command -v ufw >/dev/null; then
        ufw allow $port/$protocol
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --zone=public --add-port=$port/$protocol --permanent
        firewall-cmd --reload
    else
        iptables -A INPUT -p $protocol --dport $port -j ACCEPT
    fi
    echo -e "${GREEN}端口 $port/$protocol 已开放！${NC}"
    wait_key
}

# 8. 关闭指定端口
close_specific_port() {
    echo -e "\n${YELLOW}=== 关闭指定端口 ===${NC}"
    if ! safe_input "输入端口号" "port"; then
        echo -e "${YELLOW}已取消操作${NC}"
        wait_key
        return
    fi
    
    if ! safe_input "协议类型(tcp/udp，默认tcp)" "protocol"; then
        protocol="tcp"
    fi
    protocol=${protocol:-tcp}
    
    [[ ! $port =~ ^[0-9]+$ ]] && echo -e "${RED}无效端口号！${NC}" && wait_key && return
    
    if command -v ufw >/dev/null; then
        ufw delete allow $port/$protocol
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --zone=public --remove-port=$port/$protocol --permanent
        firewall-cmd --reload
    else
        iptables -D INPUT -p $protocol --dport $port -j ACCEPT
    fi
    echo -e "${GREEN}端口 $port/$protocol 已关闭！${NC}"
    wait_key
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
        
        if ! safe_input "请选择权限模式" "choice"; then
            return
        fi

        case $choice in
            1) perm=755; desc="rwxr-xr-x (755)"; ;;
            2) perm=644; desc="rw-r--r-- (644)"; ;;
            3) perm=700; desc="rwx------ (700)"; ;;
            4) perm=555; desc="r-xr-xr-x (555)"; ;;
            5) perm=400; desc="r-------- (400)"; ;;
            0) return ;;
            *) echo -e "${RED}无效选择！${NC}"; sleep 1; continue ;;
        esac

        if ! safe_input "请输入文件/目录路径" "path"; then
            continue
        fi

        if [ ! -e "$path" ]; then
            echo -e "${RED}路径不存在！${NC}"
            sleep 1
            continue
        fi

        echo -e "即将设置: ${YELLOW}$path${NC} -> ${BLUE}$desc${NC}"
        if ! safe_input "确认修改？(y/n)" "confirm"; then
            continue
        fi

        if [ "$confirm" = "y" ]; then
            if [ -d "$path" ]; then
                find "$path" -type d -exec chmod $perm {} \; 2>/dev/null
                find "$path" -type f -exec chmod $perm {} \; 2>/dev/null
            else
                chmod $perm "$path"
            fi
            echo -e "${GREEN}权限设置成功！${NC}"
        else
            echo -e "${YELLOW}已取消操作${NC}"
        fi
        wait_key
    done
}

# 10. 重置文件权限
reset_file_permissions() {
    echo -e "\n${YELLOW}=== 重置文件权限 ===${NC}"
    if ! safe_input "输入要重置的路径" "path"; then
        echo -e "${YELLOW}已取消操作${NC}"
        wait_key
        return
    fi
    
    [ ! -e "$path" ] && echo -e "${RED}路径不存在！${NC}" && wait_key && return
    
    echo -e "${RED}警告：这将递归重置所有权限！${NC}"
    if ! safe_input "确认重置？(y/n)" "confirm"; then
        echo -e "${YELLOW}已取消操作${NC}"
        wait_key
        return
    fi

    if [ "$confirm" = "y" ]; then
        if [ -d "$path" ]; then
            find "$path" -type d -exec chmod 755 {} \; 2>/dev/null
            find "$path" -type f -exec chmod 644 {} \; 2>/dev/null
        else
            chmod 644 "$path"
        fi
        echo -e "${GREEN}权限已重置为默认！${NC}"
    fi
    wait_key
}

#  检测防火墙类型
detect_firewall() {
    if command -v ufw >/dev/null; then
        echo "ufw"
    elif command -v firewall-cmd >/dev/null; then
        echo "firewalld"
    elif command -v iptables >/dev/null; then
        echo "iptables"
    else
        echo "none"
    fi
}

# 11. 防火墙状态查看
show_firewall_status() {
    echo -e "\n${YELLOW}=== 防火墙状态 ===${NC}"
    case $(detect_firewall) in
        ufw)
            ufw status verbose
            ;;
        firewalld)
            firewall-cmd --state
            firewall-cmd --list-all
            ;;
        iptables)
            iptables -L -n -v
            ;;
        none)
            echo -e "${RED}未检测到常用防火墙！${NC}"
            ;;
    esac
    wait_key
}

# 12. 关闭防火墙
stop_firewall() {
    echo -e "\n${RED}=== 关闭防火墙 ===${NC}"
    case $(detect_firewall) in
        ufw)
            ufw disable
            ;;
        firewalld)
            systemctl stop firewalld
            ;;
        iptables)
            iptables -F
            iptables -X
            iptables -Z
            ;;
        none)
            echo -e "${YELLOW}无活跃防火墙可关闭${NC}"
            wait_key
            return
            ;;
    esac
    echo -e "${GREEN}防火墙已关闭！${NC}"
    wait_key
}

# 13. 开启防火墙
start_firewall() {
    echo -e "\n${GREEN}=== 开启防火墙 ===${NC}"
    case $(detect_firewall) in
        ufw)
            ufw enable
            ;;
        firewalld)
            systemctl start firewalld
            ;;
        iptables)
            echo -e "${YELLOW}iptables需要手动配置规则${NC}"
            ;;
        none)
            echo -e "${RED}未检测到可管理防火墙！${NC}"
            wait_key
            return
            ;;
    esac
    echo -e "${GREEN}防火墙已启动！${NC}"
    wait_key
}

# 14. 禁止防火墙开机自启
disable_firewall_autostart() {
    echo -e "\n${YELLOW}=== 禁用防火墙开机自启 ===${NC}"
    case $(detect_firewall) in
        ufw)
            ufw disable
            ;;
        firewalld)
            systemctl disable firewalld
            ;;
        iptables)
            echo -e "${YELLOW}iptables需自行处理开机脚本${NC}"
            ;;
        none)
            echo -e "${RED}未检测到可管理防火墙！${NC}"
            wait_key
            return
            ;;
    esac
    echo -e "${GREEN}已禁止防火墙开机自启！${NC}"
    wait_key
}

# 15. 恢复防火墙开机自启
enable_firewall_autostart() {
    echo -e "\n${GREEN}=== 启用防火墙开机自启 ===${NC}"
    case $(detect_firewall) in
        ufw)
            ufw enable
            ;;
        firewalld)
            systemctl enable --now firewalld
            ;;
        iptables)
            echo -e "${YELLOW}iptables需自行配置开机启动${NC}"
            ;;
        none)
            echo -e "${RED}未检测到可管理防火墙！${NC}"
            wait_key
            return
            ;;
    esac
    echo -e "${GREEN}已恢复防火墙开机自启！${NC}"
    wait_key
}

# 16. 一键关闭防火墙及开机自启
onekey_disable_firewall() {
    echo -e "\n${RED}=== 一键关闭防火墙 ===${NC}"
    case $(detect_firewall) in
        ufw)
            ufw disable
            ;;
        firewalld)
            systemctl stop firewalld
            systemctl disable firewalld
            ;;
        iptables)
            iptables -F
            iptables -X
            iptables -Z
            echo -e "${YELLOW}请手动处理iptables开机启动${NC}"
            ;;
        none)
            echo -e "${YELLOW}无活跃防火墙可关闭${NC}"
            wait_key
            return
            ;;
    esac
    echo -e "${GREEN}防火墙已关闭并禁用开机启动！${NC}"
    wait_key
}

# 17. 一键开启防火墙及开机自启
onekey_enable_firewall() {
    echo -e "\n${GREEN}=== 一键开启防火墙 ===${NC}"
    case $(detect_firewall) in
        ufw)
            ufw enable
            ;;
        firewalld)
            systemctl enable --now firewalld
            ;;
        iptables)
            echo -e "${YELLOW}请手动配置iptables规则和开机启动${NC}"
            ;;
        none)
            echo -e "${RED}未检测到可管理防火墙！${NC}"
            wait_key
            return
            ;;
    esac
    echo -e "${GREEN}防火墙已开启并设置开机启动！${NC}"
    wait_key
}

# 18. 重启服务器函数
reboot_server() {
    echo -e "\n${RED}=== 重启服务器 ===${NC}"
    echo -e "${YELLOW}警告：这将导致服务器立即重启！${NC}"
    
    # 确认操作
    read -p "确定要重启服务器吗？(y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}已取消重启操作${NC}"
        wait_key
        return
    fi

    # 倒计时提示
    for i in {5..1}; do
        echo -ne "${RED}服务器将在 ${i} 秒后重启...${NC}\033[0K\r"
        sleep 1
    done

    # 执行重启
    echo -e "\n${GREEN}正在重启服务器...${NC}"
    shutdown -r now
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
			11) show_firewall_status ;;
            12) stop_firewall ;;
            13) start_firewall ;;
            14) disable_firewall_autostart ;;
            15) enable_firewall_autostart ;;
            16) onekey_disable_firewall ;;
            17) onekey_enable_firewall ;;
			18) reboot_server ;; 
            0) echo -e "${GREEN}脚本已退出${NC}"; exit 0 ;;
            *) echo -e "${RED}无效选项！${NC}"; sleep 1 ;;
        esac
    done
}

main

