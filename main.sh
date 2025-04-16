#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
NC='\033[0m' # 无色

# 欢迎信息（不修改）
echo -e "${GREEN}🦅 大黄鹰-Linux服务器运维工具箱${NC}"
echo -e "欢迎使用大黄鹰-Linux服务器运维工具箱。请根据菜单选择操作。"
echo -e "脚本链接： https://github.com/dahuangying/dahuangying-toolbox"

# 快速启动显示 dhy 字母标识
quick_start() {
    echo -e "${GREEN}dhy 字母标识：${NC}"
    echo -e "${GREEN}dhy${NC}"
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱 快速启动！${NC}"
    echo -e "正在执行快速启动脚本..."
    # 在这里你可以添加快速启动的功能脚本内容
    echo -e "快速启动完成！"
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
}

# 系统更新
system_update() {
    echo -e "${GREEN}正在进行系统更新...${NC}"
    sudo apt-get update && sudo apt-get upgrade -y
    echo -e "${GREEN}系统更新完成。${NC}"
}

# 系统清理
system_cleanup() {
    echo -e "${GREEN}正在清理系统...${NC}"
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
    echo -e "${GREEN}系统清理完成。${NC}"
}

# 显示菜单
show_menu() {
    echo -e "${GREEN}欢迎使用大黄鹰工具箱${NC}"
    echo "1. 系统信息查询"
    echo "2. 系统更新"
    echo "3. 系统清理"
    echo "4. 系统工具"
    echo "5. 应用脚本"
    echo "6. Docker 管理"
    echo "7. 卸载模块"
    echo "8. 删除工具箱及卸载所有模块"
    echo "9. 快速启动脚本"
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
            bash modules/system.sh  # 确保有对应模块文件
            ;;
        5)
            echo "应用脚本功能（示例）"
            ;;
        6)
            bash modules/docker.sh  # 确保有 Docker 管理模块
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
        9)
            quick_start  # 调用快速启动脚本
            ;;
        0)
            echo "感谢使用大黄鹰工具箱！"
            exit 0
            ;;
        *)
            echo "无效输入，请重试。"
            ;;
    esac
}

# 主程序入口
while true; do
    show_menu
done


