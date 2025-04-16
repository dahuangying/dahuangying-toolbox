#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
NC='\033[0m' # 无色

# 显示暂停，按任意键继续，字体设置为绿色
pause() {
    echo -e "${GREEN}操作完成，按任意键继续...${NC}"
    read -n 1 -s -r  # 等待用户按下任意键
    echo
}

# 欢迎信息
echo -e "${GREEN}  "大黄鹰-Linux服务器运维工具箱，是一款部署在github上开源的脚本工具，旨在为你提供简便的运维解决方案。"${NC}"
echo -e "脚本链接： https://github.com/dahuangying/dahuangying-toolbox"

# 显示菜单
show_menu() {
    echo -e "${GREEN}  大黄鹰-Linux服务器运维工具箱${NC}"
    echo -e "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}==================================${NC}"
    echo "1. 系统信息查询"
    echo "2. 系统更新"
    echo "3. 系统清理"
    echo "4. 系统工具"
    echo "5. 应用脚本"
    echo "6. Docker 管理"
    echo "7. 卸载模块"
    echo "8. 删除工具箱及卸载所有模块"
    echo "0. 退出"
    read -p "请输入选项编号: " choice
    case $choice in
        1)
            show_system_info
            ;;
        2)
            system_update
            ;;
        3)
            system_cleanup
            ;;
        4)
            bash modules/system.sh
            ;;
        5)
            bash modules/network.sh
            ;;
        6)
            bash modules/docker.sh
            ;;
        7)
            echo "请输入模块名删除（例如：system.sh）："
            read module_name
            delete_module $module_name
            ;;
        8)
            echo "确定要删除所有模块和主程序吗？（y/n）"
            read confirmation
            if [[ $confirmation == "y" || $confirmation == "Y" ]]; then
                delete_all_modules
                delete_main_script
                exit 0
            else
                echo "取消删除操作。"
            fi
            ;;
        0)
            echo "感谢使用大黄鹰-Linux服务器运维工具箱！"
            exit 0
            ;;
        *)
            echo "无效输入，请重试。"
            ;;
    esac
}

# 显示系统信息
show_system_info() {
    echo -e "${GREEN}系统信息查询${NC}"
    echo "---------------------------"
    echo "主机名: $(hostname)"
    echo "系统版本: $(lsb_release -d | cut -f2- -d:)"
    echo "Linux版本: $(uname -r)"
    echo "---------------------------"
    echo "CPU架构: $(uname -m)"
    echo "CPU型号: $(lscpu | grep 'Model name' | cut -d: -f2)"
    echo "CPU核心数: $(nproc)"
    echo "CPU频率: $(lscpu | grep 'CPU MHz' | cut -d: -f2)"
    echo "---------------------------"
    echo "CPU占用: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
    echo "系统负载: $(uptime | cut -d' ' -f12)"
    echo "物理内存: $(free -h | grep Mem | awk '{print $2}')"
    echo "虚拟内存: $(free -h | grep Swap | awk '{print $2}')"
    echo "硬盘占用: $(df -h | grep '/dev/root' | awk '{print $5}')"
    echo "---------------------------"
    echo "总接收: $(cat /sys/class/net/eth0/statistics/rx_bytes)"
    echo "总发送: $(cat /sys/class/net/eth0/statistics/tx_bytes)"
    echo "---------------------------"
    echo "网络算法: $(sysctl -n net.ipv4.tcp_congestion_control)"
    echo "---------------------------"
    echo "运营商: $(curl -s ipinfo.io/org)"
    echo "IPv4地址: $(curl -s ipinfo.io/ip)"
    echo "DNS地址: $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')"
    echo "地理位置: $(curl -s ipinfo.io/loc)"
    echo "系统时间: $(date)"
    echo "---------------------------"
    echo "运行时长: $(uptime -p)"
    echo -e "${GREEN}---------------------------${NC}"
    pause
}

# 系统更新
system_update() {
    echo -e "${GREEN}正在进行系统更新...${NC}"
    sudo apt-get update && sudo apt-get upgrade -y
    echo -e "${GREEN}系统更新完成。${NC}"
    pause
}

# 系统清理
system_cleanup() {
    echo -e "${GREEN}正在清理系统...${NC}"
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
    echo -e "${GREEN}系统清理完成。${NC}"
    pause
}

# 删除模块
delete_module() {
    echo -e "${GREEN}正在删除模块：$1${NC}"
    if [ -f "modules/$1" ]; then
        rm -f "modules/$1"
        echo -e "${GREEN}模块 $1 已删除。${NC}"
    else
        echo -e "${GREEN}模块 $1 不存在。${NC}"
    fi
}

# 删除所有模块
delete_all_modules() {
    echo -e "${GREEN}正在删除所有模块...${NC}"
    rm -rf modules/*
    echo -e "${GREEN}所有模块已删除。${NC}"
}

# 删除主程序
delete_main_script() {
    echo -e "${GREEN}正在删除主程序 main.sh...${NC}"
    rm -f main.sh
    echo -e "${GREEN}主程序已删除！${NC}"
    echo -e "${GREEN}请手动删除此工具箱文件夹。${NC}"
}

# 删除工具箱目录
delete_toolbox() {
    echo -e "${GREEN}正在删除整个工具箱目录...${NC}"
    rm -rf /path/to/dahuangying-toolbox  # 替换为你工具箱的实际路径
    echo -e "${GREEN}工具箱已删除。${NC}"
}

# 删除所有内容
full_uninstall() {
    echo -e "${GREEN}确定要删除所有模块和主程序吗？（y/n）${NC}"
    read confirmation
    if [[ $confirmation == "y" || $confirmation == "Y" ]]; then
        delete_all_modules
        delete_main_script
        delete_toolbox
        echo -e "${GREEN}所有内容已删除。${NC}"
        exit 0
    else
        echo -e "${GREEN}取消删除操作。${NC}"
    fi
}

# 主程序入口
while true; do
    show_menu
done






