#!/bin/bash

# 1Panel 安装管理脚本

# 配置项
PANEL_INSTALL_DIR="/opt/1panel"  # 1Panel 安装目录
PANEL_SERVICE_FILE="/etc/systemd/system/1panel.service"  # 1Panel 服务文件路径

# 颜色配置
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 函数：显示菜单
show_menu() {
    clear
    
    # 检查是否已安装 1Panel
    if [ -d "$PANEL_INSTALL_DIR" ] || [ -f "$PANEL_SERVICE_FILE" ]; then
        INSTALL_STATUS="已安装"
    else
        INSTALL_STATUS="未安装"
    fi

 # 显示安装状态和安装目录（绿色）
    echo -e "${GREEN}1Panel 安装状态: $INSTALL_STATUS${NC}"
    echo -e "${GREEN}安装目录: $PANEL_INSTALL_DIR${NC}"
    echo -e "${GREEN}========================================${NC}"
    # 显示菜单头部
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱菜单-1Panel${NC}"
    echo -e "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}========================================${NC}"
    # 主菜单选项
    echo "1. 安装 1Panel"
    echo "2. 查看面板信息"
    echo "3. 修改密码"
    echo "4. 卸载 1Panel"
    echo "0. 退出"
    read -p "请输入选项: " option
    case $option in
        1) install_panel ;;
        2) view_panel_info ;;
        3) update_password ;;
        4) uninstall_panel ;;
        0) exit 0 ;;  # 退出选项
        *) echo "无效的选项，请重新选择！" && sleep 2 && show_menu ;;
    esac
}

# 函数：安装 1Panel
install_panel() {
    echo "开始安装 1Panel..."

    # 执行官方安装脚本
    curl -sSL https://resource.1panel.pro/quick_start.sh -o quick_start.sh && bash quick_start.sh

    echo "1Panel 安装完成！"
    echo "请使用以下命令查看面板地址："
    echo "您可以通过 1pctl user-info 查看面板信息"
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
    show_menu
}

# 函数：查看面板信息
view_panel_info() {
    echo "正在获取面板信息..."
    1pctl user-info
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
    show_menu
}

# 函数：修改密码
update_password() {
    echo "正在修改密码..."
    # 通过官方命令修改密码
    1pctl update password
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
    show_menu
}

# 函数：卸载 1Panel
uninstall_panel() {
    read -p "您确定要卸载 1Panel 并删除所有相关文件吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "正在卸载 1Panel..."

        # 查找并删除 1Panel 相关文件
        echo "查找并删除 1Panel 相关文件..."
        sudo find / -name "1panel*" -exec sudo rm -f {} \;

        # 删除服务文件
        echo "检查并删除服务文件..."
        sudo rm -f /root/1panel-v1.10.29-lts-linux-amd64/1panel.service

        # 检查并禁用服务
        echo "检查并禁用服务..."
        sudo systemctl list-units --type=service | grep 1panel
        sudo systemctl stop 1panel
        sudo systemctl disable 1panel
        sudo rm -f /etc/systemd/system/1panel.service

        # 确认删除所有文件
        echo "确认所有相关文件已删除..."
        sudo find / -name "1panel*"

        # 清理日志文件
        echo "清理日志文件..."
        sudo rm -f /var/log/1panel.log

        echo "1Panel 卸载完成！"
    else
        echo "取消卸载。"
    fi
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
    show_menu
}

# 启动脚本
show_menu
