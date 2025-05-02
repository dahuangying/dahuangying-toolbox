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
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱菜单 - 系统工具${NC}"
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
    echo -e "${BLUE}---------------------------------------${NC}"
	echo -e "16. 重启服务器"
    echo -e "${BLUE}---------------------------------------${NC}"
    echo -e "17. 创建目录"
    echo -e "18. 创建文件"
    echo -e "19. 删除目录/文件"
    echo -e "20. 编辑文件"
    echo -e "21. 查找文件/目录"
    echo -e "${BLUE}---------------------------------------${NC}"
    echo -e "0. 退出"
    echo -n "请输入选项数字: "
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
			16) reboot_server ;; 
            17) create_directory ;;
            18) create_file ;;
            19) delete_target ;;
            20) edit_file ;;
            21) search_files ;;
            0) echo -e "${GREEN}脚本已退出${NC}"; exit 0 ;;
            *) echo -e "${RED}无效选项！${NC}"; sleep 1 ;;
        esac
    done
}

# 1. 启用ROOT密码登录模式
enable_root_login() {
    clear
    echo -e "${GREEN}=== 启用ROOT密码登录模式 ===${NC}"
    
    # 设置密码
    passwd root || { echo -e "${RED}密码设置失败${NC}"; return 1; }

    # 修改配置（兼容所有系统）
    sed -i '/^\s*#\?\s*PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config
    sed -i '/^\s*#\?\s*PasswordAuthentication/c\PasswordAuthentication yes' /etc/ssh/sshd_config
    sed -i '/^\s*#\?\s*PubkeyAuthentication/c\PubkeyAuthentication yes' /etc/ssh/sshd_config

 echo "🔄 正在尝试重启 SSH 服务..."
  if systemctl restart ssh 2>/dev/null; then
    echo "✅ 成功重启 ssh.service"
  elif systemctl restart sshd 2>/dev/null; then
    echo "✅ 成功重启 sshd.service"
  elif service ssh restart 2>/dev/null; then
    echo "✅ 成功使用 service 命令重启 ssh"
  else
    echo "❌ 无法确定 SSH 服务名，请手动重启 SSH 服务"
  fi
    
    echo -e "${GREEN}✔ 已启用ROOT登录${NC}"
    echo -e "当前配置："
    grep -E "PermitRootLogin|PasswordAuthentication|PubkeyAuthentication" /etc/ssh/sshd_config
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

    sed -i 's/^#*PermitRootLogin.*/#PermitRootLogin no/g' /etc/ssh/ssh_config
    
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

# 5. 开放所有端口（关键端口不开放）
open_all_ports() {
    clear
    echo -e "\n${RED}=== 警告：将开放非系统关键端口 ===${NC}"
    echo -e "${YELLOW}以下端口仍受保护："
    echo -e "• 53/udp    (DNS)"
    echo -e "• 161/udp   (SNMP)"
    echo -e "• 389/tcp   (LDAP)"
    echo -e "• 3306/tcp  (MySQL)"
    echo -e "• 5432/tcp  (PostgreSQL)"
    echo -e "• 6379/tcp  (Redis)"
    echo -e "• 内部网络通信端口${NC}"
    
    read -p "确定继续吗？(y/n): " confirm
    [[ "$confirm" != "y" ]] && return

    # 自动检测内部网络
    auto_detect_internal_network() {
        echo -e "${YELLOW}正在自动检测内部网络...${NC}"
        detected_nets=$(ip -o -4 addr show | awk '
            /^[0-9]+: (eth|en|wl|em)[0-9]/ && !/(docker|virbr|veth|br-)/ {
                split($4, ip, "/")
                if (ip[2] >= 24) print $4
            }' | sort -u | xargs | tr ' ' ',')
        
        [ -z "$detected_nets" ] && detected_nets="10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
        
        read -p "使用检测网络：${detected_nets} [Y/n]? " confirm
        [[ "$confirm" =~ ^[Nn] ]] && read -p "输入自定义网络(CIDR逗号分隔): " detected_nets
        
        INTERNAL_NETWORK="${detected_nets// /,}"
    }

    if [ -z "$INTERNAL_NETWORK" ]; then
        auto_detect_internal_network
    else
        echo -e "${GREEN}使用预定义内部网络：$INTERNAL_NETWORK${NC}"
    fi

    # 防火墙规则配置
    if command -v ufw >/dev/null; then
        echo -e "${GREEN}使用 UFW 配置...${NC}"
        ufw --force reset
        ufw default allow incoming

        # 允许内部网络
        for net in $(tr ',' ' ' <<< "$INTERNAL_NETWORK"); do
            ufw allow from "$net"
        done

        # 逐个拒绝关键端口（外部）
        for port in 53 161 389 3306 5432 6379; do
            ufw deny proto tcp to any port "$port"
            [ $port -le 161 ] && ufw deny proto udp to any port "$port"
        done

        ufw --force enable
        ufw reload

    elif command -v firewall-cmd >/dev/null; then
        echo -e "${GREEN}使用 Firewalld 配置...${NC}"
        # 创建可信区域
        firewall-cmd --permanent --new-zone=trusted_internal >/dev/null 2>&1
        firewall-cmd --permanent --zone=trusted_internal --set-target=ACCEPT
        firewall-cmd --permanent --zone=trusted_internal --add-source="$INTERNAL_NETWORK"

        # 公共区域限制
        firewall-cmd --permanent --zone=public --set-target=ACCEPT
        for port in 53 161 389 3306 5432 6379; do
            firewall-cmd --permanent --zone=public --add-rich-rule="rule family='ipv4' port port='$port' protocol='tcp' reject"
            [ $port -le 161 ] && firewall-cmd --permanent --zone=public --add-rich-rule="rule family='ipv4' port port='$port' protocol='udp' reject"
        done
        firewall-cmd --reload

    else
        echo -e "${GREEN}使用 iptables 配置...${NC}"
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -F

        # 允许内部网络
        for net in $(tr ',' ' ' <<< "$INTERNAL_NETWORK"); do
            iptables -A INPUT -s "$net" -j ACCEPT
        done

        # 拒绝外部访问关键端口
        iptables -A INPUT -p tcp -m multiport --dports 53,161,389,3306,5432,6379 -j DROP
        iptables -A INPUT -p udp -m multiport --dports 53,161 -j DROP

        # 持久化规则
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4
        ip6tables-save > /etc/iptables/rules.v6
    fi

    # 显示配置结果
    echo -e "\n${GREEN}配置完成！当前开放状态：${NC}"
    if command -v ufw >/dev/null; then
        ufw status numbered | grep -E '\[允许|拒绝\]'
    elif command -v firewall-cmd >/dev/null; then
        echo "[公共区域]"
        firewall-cmd --zone=public --list-all
        echo -e "\n[内部区域]"
        firewall-cmd --zone=trusted_internal --list-all
    else
        iptables -L INPUT -n -v --line-numbers | grep -E 'DROP|ACCEPT'
    fi
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
    echo -e "\n${GREEN}=== 开启防火墙（默认开放 22 端口） ===${NC}"
    
    local firewall_type=$(detect_firewall)
    
    case $firewall_type in
        ufw)
            echo -e "${YELLOW}检测到使用 UFW 防火墙${NC}"
            if ! ufw allow 22/tcp; then
                echo -e "${RED}错误：无法添加 22 端口规则！${NC}" >&2
                wait_key
                return 1
            fi
            if ufw enable; then
                echo -e "${GREEN}UFW 已启用，22 端口已开放！${NC}"
            else
                echo -e "${RED}错误：UFW 启用失败！${NC}" >&2
                return 1
            fi
            ;;
        firewalld)
            echo -e "${YELLOW}检测到使用 Firewalld 防火墙${NC}"
            if ! firewall-cmd --permanent --add-service=ssh >/dev/null; then
                echo -e "${RED}错误：无法添加 SSH 服务规则！${NC}" >&2
                return 1
            fi
            if firewall-cmd --reload >/dev/null && systemctl start firewalld; then
                echo -e "${GREEN}Firewalld 已启用，SSH 服务已开放！${NC}"
            else
                echo -e "${RED}错误：Firewalld 启动失败！${NC}" >&2
                return 1
            fi
            ;;
        iptables)
            echo -e "${YELLOW}检测到使用 iptables${NC}"
            echo -e "${YELLOW}正在添加 22 端口规则...${NC}"
            iptables -A INPUT -p tcp --dport 22 -j ACCEPT
            if service iptables save &>/dev/null; then
                echo -e "${GREEN}iptables 规则已保存！${NC}"
            else
                echo -e "${RED}警告：无法自动保存 iptables 规则，请手动保存！${NC}" >&2
            fi
            if service iptables restart &>/dev/null; then
                echo -e "${GREEN}iptables 已重启，22 端口已开放！${NC}"
            else
                echo -e "${RED}错误：iptables 重启失败！${NC}" >&2
                return 1
            fi
            ;;
        none)
            echo -e "${RED}未检测到可管理防火墙！${NC}"
            wait_key
            return 1
            ;;
    esac

    echo -e "\n${YELLOW}提示：如需开放其他端口（如 80/443），请通过菜单添加！${NC}"
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

# 16. 重启服务器函数
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

# 安全确认函数
confirm_action() {
    local action=$1
    local target=$2
    echo -e "${RED}警告：即将执行 ${action} 操作目标：${YELLOW}${target}${NC}"
    read -p "确认执行？(y/n): " choice
    [[ "$choice" =~ ^[Yy]$ ]] && return 0 || return 1
}

# 17. 创建目录
create_directory() {
    read -p "输入要创建的目录路径及目录名: " dirpath
    if [ -z "$dirpath" ]; then
        echo -e "${RED}路径不能为空！${NC}"
        return
    fi
    
    if confirm_action "创建目录" "$dirpath"; then
        if mkdir -p "$dirpath"; then
            echo -e "${GREEN}目录创建成功！${NC}"
            recommend_permissions "$dirpath" "directory"
        else
            echo -e "${RED}创建失败，请检查权限！${NC}"
        fi
    else
        echo -e "${YELLOW}已取消操作${NC}"
    fi
    wait_key
}

# 18. 创建文件
create_file() {
    read -p "输入要创建的文件路径及文件名: " filepath
    if [ -z "$filepath" ]; then
        echo -e "${RED}路径不能为空！${NC}"
        return
    fi
    
    if confirm_action "创建文件" "$filepath"; then
        if touch "$filepath"; then
            echo -e "${GREEN}文件创建成功！${NC}"
            recommend_permissions "$filepath" "file"
        else
            echo -e "${RED}创建失败，请检查权限！${NC}"
        fi
    else
        echo -e "${YELLOW}已取消操作${NC}"
    fi
    wait_key
}

# 19. 删除目录/文件
delete_target() {
    read -p "输入要删除的目录或文件的路径: " target
    if [ -z "$target" ]; then
        echo -e "${RED}路径不能为空！${NC}"
        return
    fi
    
    if [ ! -e "$target" ]; then
        echo -e "${RED}目标不存在！${NC}"
        return
    fi
    
    if confirm_action "删除" "$target"; then
        if [ -d "$target" ]; then
            rm -r "$target" && echo -e "${GREEN}目录删除成功！${NC}" || echo -e "${RED}删除失败！${NC}"
        else
            rm "$target" && echo -e "${GREEN}文件删除成功！${NC}" || echo -e "${RED}删除失败！${NC}"
        fi
    else
        echo -e "${YELLOW}已取消操作${NC}"
    fi
    wait_key
}

# 20. 编辑文件
edit_file() {
    read -p "输入要编辑的文件路径:（编辑模式：Vim：按 ESC → 输入 :wq → 回车  Nano：按 Ctrl+O 保存 → Ctrl+X 退出 ） " filepath
    if [ -z "$filepath" ]; then
        echo -e "${RED}路径不能为空！${NC}"
        return
    fi
    
    if [ ! -f "$filepath" ]; then
        echo -e "${RED}文件不存在或不是普通文件！${NC}"
        return
    fi
    
    if [ ! -w "$filepath" ]; then
        echo -e "${RED}无写权限，尝试获取权限...${NC}"
        if ! sudo chmod u+w "$filepath"; then
            echo -e "${RED}无法获取写权限！${NC}"
            return
        fi
    fi
    
    # 检测可用编辑器
    editor=${EDITOR:-nano}
    command -v $editor >/dev/null || editor="vi"
    
    $editor "$filepath"
    echo -e "${GREEN}编辑完成！${NC}"
    wait_key
}

# 21. 查找文件/目录
search_files() {
    read -p "输入查找路径（默认当前目录）: " searchpath
    read -p "输入查找名称（支持通配符）: " pattern
    
    searchpath=${searchpath:-.}
    
    if [ -z "$pattern" ]; then
        echo -e "${RED}搜索模式不能为空！${NC}"
        return
    fi
    
    echo -e "${BLUE}搜索结果：${NC}"
    find "$searchpath" -name "$pattern" -print | while read result; do
        if [ -d "$result" ]; then
            echo -e "${GREEN}[目录] ${result}${NC}"
        else
            echo -e "${YELLOW}[文件] ${result}${NC}"
        fi
    done
    
    wait_key
}

# 权限建议函数
recommend_permissions() {
    local target=$1
    local type=$2
    
    echo -e "\n${BLUE}权限建议：${NC}"
    case $type in
        "directory")
            echo -e "• 普通目录： ${GREEN}755 (drwxr-xr-x)${NC}"
            echo -e "• 敏感目录： ${GREEN}700 (drwx------)${NC}"
            echo -e "当前权限： $(stat -c "%a %A" "$target")"
            ;;
        "file")
            echo -e "• 配置文件： ${GREEN}644 (-rw-r--r--)${NC}"
            echo -e "• 可执行文件： ${GREEN}755 (-rwxr-xr-x)${NC}"
            echo -e "• 敏感文件： ${GREEN}600 (-rw-------)${NC}"
            echo -e "当前权限： $(stat -c "%a %A" "$target")"
            ;;
    esac
}

main

