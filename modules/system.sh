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

# 其他保持原样的函数（show_port_status/open_all_ports/close_all_ports/open_specific_port/close_specific_port/reset_file_permissions）
# 此处省略，实际脚本中请保留原有实现，只需在最后添加 wait_key 调用

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
            4) show_port_status; wait_key ;;
            5) open_all_ports; wait_key ;;
            6) close_all_ports; wait_key ;;
            7) open_specific_port; wait_key ;;
            8) close_specific_port; wait_key ;;
            9) file_permission_settings ;;
            10) reset_file_permissions; wait_key ;;
            0) echo -e "${GREEN}脚本已退出${NC}"; exit 0 ;;
            *) echo -e "${RED}无效选项！${NC}"; sleep 1 ;;
        esac
    done
}

main

