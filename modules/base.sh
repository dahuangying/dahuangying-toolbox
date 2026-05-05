#!/bin/bash
# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 暂停函数
pause() {
    echo -e "\n${GREEN}操作完成，按任意键返回菜单...${NC}"
    read -n 1 -s -r
    echo
}

wait_key() {
    pause
}

# SSH重启函数
restart_ssh_service() {
    echo -e "${YELLOW}正在重启SSH服务...${NC}"
    if systemctl restart ssh 2>/dev/null || \
       systemctl restart sshd 2>/dev/null || \
       service ssh restart 2>/dev/null || \
       service sshd restart 2>/dev/null; then
        echo -e "${GREEN}服务重启成功${NC}"
        return 0
    else
        echo -e "${RED}服务重启失败${NC}"
        return 1
    fi
}

# 系统工具功能菜单
show_base_menu() {
    clear
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}  大黄鹰-Linux服务器运维工具箱菜单-系统工具  ${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${YELLOW}请选择需要执行的操作：${NC}"
    echo ""
    echo "1. 开启系统自带 BBR 加速"
    echo "2. 查询当前 TCP 拥塞控制算法"
    echo "3. 启用ROOT密码登录模式"
    echo "4. 禁用ROOT密码登录"
    echo "5. 修改ROOT密码"
    echo ""
    echo "0. 返回主工具箱"
    echo -e "${GREEN}=============================================${NC}"
    read -p "请输入选项编号: " choice
    case $choice in
        1) bbr_acceleration ;;
        2) query_tcp_congestion ;;
        3) enable_root_login ;;
        4) disable_root_login ;;
        5) change_root_password ;;
        0) exit 0 ;;
        *) 
            echo -e "${RED}无效输入，请重试！${NC}"
            sleep 1
            ;;
    esac
}

# 1. 开启BBR
bbr_acceleration() {
    clear
    echo -e "${GREEN}正在开启系统 BBR 加速...${NC}"
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    lsmod | grep bbr
    pause
}

# 2. 查询TCP算法
query_tcp_congestion() {
    clear
    echo -e "${GREEN}当前 TCP 拥塞控制算法：${NC}"
    sysctl net.ipv4.tcp_congestion_control
    pause
}

# 3. 启用ROOT密码登录模式
enable_root_login() {
    clear
    echo -e "${GREEN}=== 启用ROOT密码登录模式 ===${NC}"

    # 设置 root 密码
    if ! passwd root; then
        echo -e "${RED}密码设置失败${NC}" 
        wait_key
        return 1
    fi

    # 修改主配置文件
    sed -i '/^\s*#\?\s*PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config
    sed -i '/^\s*#\?\s*PasswordAuthentication/c\PasswordAuthentication yes' /etc/ssh/sshd_config
    sed -i '/^\s*#\?\s*PubkeyAuthentication/c\PubkeyAuthentication yes' /etc/ssh/sshd_config

    # 修复 sshd_config.d/*.conf 中的 PasswordAuthentication no
    # 在脚本开头定义（设为true时显示，false时静默）
    VERBOSE=false
    if [ -d /etc/ssh/sshd_config.d ]; then
        for file in /etc/ssh/sshd_config.d/*.conf; do
            [ -f "$file" ] || continue
            if grep -qE "^\s*PasswordAuthentication\s+no" "$file"; then
                $VERBOSE && echo -e "${YELLOW}检测到 $file 中禁用了密码登录，正在修改为允许...${NC}"
                sed -i 's/^\s*PasswordAuthentication\s\+no/PasswordAuthentication yes/' "$file" $($VERBOSE || echo ">/dev/null")
            fi
        done
    fi
    

    # 输出当前有效配置
    echo -e "${GREEN}✔ 已启用ROOT登录${NC}"
    echo -e "当前配置文件中内容："
    grep -E "PermitRootLogin|PasswordAuthentication|PubkeyAuthentication" /etc/ssh/sshd_config
    echo -e "\n当前 sshd 实际加载配置："
    sshd -T 2>/dev/null | grep -E "permitrootlogin|passwordauthentication|pubkeyauthentication" || \
        echo -e "${YELLOW}警告：无法获取运行时配置，请确保sshd -T命令可用${NC}"
    
    wait_key

# 4. 禁用ROOT密码登录（增加确认）
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

# 5. 修改ROOT密码
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

# ==============================
# 程序入口
# ==============================
while true; do
    show_base_menu
done
