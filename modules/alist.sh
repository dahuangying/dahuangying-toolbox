#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
NC='\033[0m' # 无色
RED='\033[0;31m'

# 显示暂停，按任意键继续
pause() {
    echo -e "${GREEN}操作完成，按任意键继续...${NC}"
    read -n 1 -s -r  # 等待用户按下任意键
    echo
}

# 官网介绍
show_intro() {
    echo -e "${GREEN}Alist - 多存储文件管理系统${NC}"
    echo -e "官网介绍: https://alist.nn.ci/zh/"
    echo -e "${GREEN}------------------------${NC}"
}

# 安装 Alist
install_alist() {
    echo -e "${GREEN}开始安装 Alist...${NC}"
    if ! confirm_action; then return; fi
    # 下载并安装 Alist
    wget https://github.com/Xhofe/alist/releases/download/v2.0.0/alist-linux-amd64.tar.gz -O /tmp/alist.tar.gz
    tar -xvzf /tmp/alist.tar.gz -C /tmp
    mv /tmp/alist /usr/local/bin/
    mkdir -p /etc/alist
    echo -e "${GREEN}Alist 安装完成！启动 Alist：${NC} alist -conf /etc/alist"
    pause
}

# 更新 Alist
update_alist() {
    echo -e "${GREEN}开始更新 Alist...${NC}"
    if ! confirm_action; then return; fi
    # 更新 Alist
    wget https://github.com/Xhofe/alist/releases/latest/download/alist-linux-amd64.tar.gz -O /tmp/alist.tar.gz
    tar -xvzf /tmp/alist.tar.gz -C /tmp
    mv /tmp/alist /usr/local/bin/
    echo -e "${GREEN}Alist 更新完成！${NC}"
    pause
}

# 卸载 Alist
uninstall_alist() {
    echo -e "${RED}你确定要卸载 Alist 吗？（y/n）${NC}"
    if ! confirm_action; then return; fi
    sudo rm -f /usr/local/bin/alist
    sudo rm -rf /etc/alist
    echo -e "${GREEN}Alist 已卸载。${NC}"
    pause
}

# 添加域名访问
add_domain_access() {
    echo -e "${GREEN}请输入要添加的域名：${NC}"
    read domain
    echo -e "${GREEN}添加域名访问：$domain${NC}"
    # 这里可以添加实际配置域名的命令（例如 Nginx 配置）
    pause
}

# 删除域名访问
delete_domain_access() {
    echo -e "${GREEN}请输入要删除的域名：${NC}"
    read domain
    echo -e "${GREEN}删除域名访问：$domain${NC}"
    # 这里可以添加实际删除域名配置的命令（例如 Nginx 配置）
    pause
}

# 允许IP+端口访问
allow_ip_port_access() {
    echo -e "${GREEN}请输入允许访问的IP地址：${NC}"
    read ip
    echo -e "${GREEN}请输入允许访问的端口：${NC}"
    read port
    echo -e "${GREEN}允许IP：$ip 访问端口：$port${NC}"
    # 这里可以添加允许IP和端口访问的实际命令（如防火墙规则）
    pause
}

# 阻止IP+端口访问
block_ip_port_access() {
    echo -e "${GREEN}请输入阻止访问的IP地址：${NC}"
    read ip
    echo -e "${GREEN}请输入阻止访问的端口：${NC}"
    read port
    echo -e "${GREEN}阻止IP：$ip 访问端口：$port${NC}"
    # 这里可以添加阻止IP和端口访问的实际命令（如防火墙规则）
    pause
}

# 脚本功能菜单
show_menu() {
    echo -e "${GREEN}Alist 管理菜单${NC}"
    echo "1. 安装"
    echo "2. 更新"
    echo "3. 卸载"
    echo "4. 添加域名访问"
    echo "5. 删除域名访问"
    echo "6. 允许IP+端口访问"
    echo "7. 阻止IP+端口访问"
    echo "0. 退出"
    read -p "请输入选项编号: " choice
    case $choice in
        1)
            install_alist
            ;;
        2)
            update_alist
            ;;
        3)
            uninstall_alist
            ;;
        4)
            add_domain_access
            ;;
        5)
            delete_domain_access
            ;;
        6)
            allow_ip_port_access
            ;;
        7)
            block_ip_port_access
            ;;
        0)
            echo "感谢使用 Alist 管理工具！"
            exit 0
            ;;
        *)
            echo "无效输入，请重试。"
            ;;
    esac
}

# 欢迎信息
show_intro

# 主程序入口
while true; do
    show_menu  # 显示菜单
done

