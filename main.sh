#!/bin/bash

# 设置颜色
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

# 显示暂停，按任意键继续，字体设置为绿色
pause() {
    echo -e "${GREEN}操作完成，按任意键继续...${NC}"
    read -n 1 -s -r  # 等待用户按下任意键
    echo
}

# 欢迎信息
echo -e "${GREEN}"大黄鹰-Linux服务器运维工具箱，是一款部署在github上开源的脚本工具，旨在为你提供简便的运维解决方案。"${NC}"
echo -e "脚本链接： https://github.com/dahuangying/dahuangying-toolbox"

# 显示菜单
show_menu() {
    echo -e "${GREEN}==================================${NC}"
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
    
    # 获取主网络接口
    NET_IF=$(ip route | grep default | awk '{print $5}' | head -n1)
    [ -z "$NET_IF" ] && NET_IF="eth0"

    echo -e "\n${GREEN}============ 系统信息 ============${NC}"
    
    # 1. 基础信息
show_system_info() {
 
    # 获取主网络接口
    NET_IF=$(ip route | grep default | awk '{print $5}' | head -n1)
    [ -z "$NET_IF" ] && NET_IF="eth0"

    echo -e "\n${GREEN}============ 系统信息查询 ============${NC}"
    
    # 1. 基础信息
    echo -e "${YELLOW}◆ 基础信息${NC}"
    echo "主机名: $(hostname)"
    echo "系统版本: $(lsb_release -d | cut -f2- 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核版本: $(uname -r)"
    echo "系统时间: $(date +"%Y-%m-%d %T %Z")"
    echo "运行时长: $(uptime -p)"
    
    # 2. CPU信息
    echo -e "\n${YELLOW}◆ CPU信息${NC}"
    echo "架构: $(uname -m)"
    echo "型号: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "核心数: $(nproc)核"
    echo "平均频率: $(lscpu | grep 'CPU MHz' | cut -d: -f2 | xargs) MHz"
    echo "占用率: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
    echo "系统负载: $(uptime | awk -F'load average: ' '{print $2}')"
    
    # 3. 内存信息
    echo -e "\n${YELLOW}◆ 内存信息${NC}"
    free -h | awk '/Mem/{printf "物理内存: %s/%s (可用: %s)\n", $3, $2, $7}'
    free -h | awk '/Swap/{printf "交换分区: %s/%s\n", $3, $2}'
    
    # 4. 磁盘信息
    echo -e "\n${YELLOW}◆ 存储信息${NC}"
    echo "根分区使用率: $(df -h / | awk 'NR==2{print $5}')"
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v loop
    echo -e "\n挂载点使用情况:"
    df -hT | grep -v tmpfs | awk '{printf "%-20s %-10s %-10s %-10s\n", $7, $2, $6, $5}'
    
    # 5. 网络信息（重点增强部分）
    echo -e "\n${YELLOW}◆ 网络信息${NC}"
    echo "主接口: $NET_IF"
    echo "内网IP: $(hostname -I | awk '{print $1}')"
    echo "公网IP: $(curl -s ipinfo.io/ip)"
    echo "运营商: $(curl -s ipinfo.io/org)"
    echo "地理位置: $(curl -s ipinfo.io/city), $(curl -s ipinfo.io/country)"
    echo "DNS: $(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')"
    echo "流量统计:"
    echo "  接收: $(numfmt --to=iec $(cat /sys/class/net/$NET_IF/statistics/rx_bytes))"
    echo "  发送: $(numfmt --to=iec $(cat /sys/class/net/$NET_IF/statistics/tx_bytes))"
    
    # ▼▼▼ 增强的网络算法信息 ▼▼▼
    echo -e "\n${BLUE}网络算法配置:${NC}"
    echo "TCP拥塞控制: $(sysctl -n net.ipv4.tcp_congestion_control)"
    echo "当前队列算法: $(sysctl -n net.core.default_qdisc)"
    echo "可用拥塞算法: $(cat /proc/sys/net/ipv4/tcp_available_congestion_control)"
    echo "内存缓冲区:"
    echo "  TCP接收: $(sysctl -n net.ipv4.tcp_rmem | awk '{print $3/1024/1024"MB"}')"
    echo "  TCP发送: $(sysctl -n net.ipv4.tcp_wmem | awk '{print $3/1024/1024"MB"}')"
    # ▲▲▲ 新增内容结束 ▲▲▲
    
    # 6. 安全信息
    echo -e "\n${YELLOW}◆ 安全信息${NC}"
    echo "最后登录用户:"
    last -n 3 | head -n -2
    echo -e "\nSSH登录失败:"
    journalctl -u sshd | grep Failed | tail -n 3 2>/dev/null || echo "无记录"
    
    # 7. 硬件信息
    echo -e "\n${YELLOW}◆ 硬件信息${NC}"
    echo "主板型号: $(dmidecode -t baseboard | grep "Product Name" | cut -d: -f2 | xargs 2>/dev/null || echo "未知")"
    echo "BIOS版本: $(dmidecode -t bios | grep "Version" | cut -d: -f2 | xargs 2>/dev/null || echo "未知")"
    echo "GPU信息: $(lspci | grep -i vga | cut -d: -f3 | xargs 2>/dev/null || echo "未检测到独立显卡")"
    
    # 8. 容器/虚拟化
    echo -e "\n${YELLOW}◆ 运行环境${NC}"
    if [ -f /.dockerenv ]; then
        echo "Docker容器"
    elif systemd-detect-virt -q 2>/dev/null; then
        echo "虚拟化平台: $(systemd-detect-virt)"
    else
        echo "物理机"
    fi
    
    echo -e "${GREEN}================================${NC}"
    pause
}

# 系统更新
system_update() {

    echo -e "\n${GREEN}=== 系统更新开始 ===${NC}"

    # 系统检测
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            debian|ubuntu)
                echo -e "${BLUE}[Debian/Ubuntu] 更新中...${NC}"
                if ! sudo apt-get update; then
                    echo -e "${RED}更新软件源失败${NC}"
                    return 1
                fi
                sudo apt-get upgrade -y
                sudo apt-get --only-upgrade install security-updates -y
                
                # 内核检查
                if ls /boot/vmlinuz-* 2>/dev/null | grep -q vmlinuz; then
                    echo -e "${YELLOW}当前内核版本: $(uname -r)${NC}"
                    NEED_REBOOT=true
                fi
                ;;

            centos|rhel)
                echo -e "${BLUE}[RHEL/CentOS] 更新中...${NC}"
                sudo yum update --security -y
                NEED_REBOOT=true  # RHEL系更新通常需要重启
                ;;

            arch)
                echo -e "${BLUE}[Arch] 更新中...${NC}"
                sudo pacman -Syu --noconfirm
                ;;
        esac

        # 通用Flatpak/Snap更新
        command -v flatpak >/dev/null && flatpak update -y
        command -v snap >/dev/null && sudo snap refresh
    fi

    # 更新后处理
    echo -e "\n${GREEN}=== 更新完成 ===${NC}"
    if $NEED_REBOOT; then
        read -p $'\033[33m需重启应用更新，是否立即重启？(y/N): \033[0m' choice
        [[ "$choice" =~ ^[Yy]$ ]] && sudo reboot
    fi

    echo -e "${CYAN}建议检查：${NC}"
    echo "1. 待重启服务: sudo needrestart -b"
    echo "2. 安全补丁: sudo apt list --upgradable 2>/dev/null"
    pause
}

# 系统清理
system_cleanup() {
    # 颜色定义
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
    
    # 新增重启判断变量
    need_reboot=false

    # 安全检查函数
    check_safe_path() {
        [[ "$1" == "/" || ! -d "$1" ]] && { echo -e "${RED}危险路径: $1${NC}"; return 1; }
        return 0
    }

    # 显示空间使用
    show_space_usage() {
        echo -e "\n${CYAN}磁盘使用情况:${NC}"
        df -h / | awk 'NR==2{printf "%-10s %s\n%-10s %s\n%-10s %s\n", "总空间:", $2, "已用:", $3, "可用:", $4}'
    }

    # 开始清理
    echo -e "\n${GREEN}=== 系统清理开始 ===${NC}"
    show_space_usage

    # 发行版特定清理
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            debian|ubuntu)
                echo -e "${BLUE}[Debian/Ubuntu] 清理中...${NC}"
                sudo apt-get -qq autoremove --purge -y
                # 内核检查
                if sudo apt list --installed | grep -q 'linux-image-[0-9]'; then
                    echo -e "${YELLOW}检测到内核变更，建议重启${NC}"
                    need_reboot=true
                fi
                check_safe_path "/var/cache/apt/archives" && sudo rm -rf /var/cache/apt/archives/*
                ;;
            centos|rhel)
                echo -e "${BLUE}[RHEL/CentOS] 清理中...${NC}"
                sudo package-cleanup --oldkernels --count=1 -y
                # 内核检查
                if [ $(sudo rpm -qa | grep -c '^kernel-') -gt 1 ]; then
                    echo -e "${YELLOW}检测到多内核存在，建议重启${NC}"
                    need_reboot=true
                fi
                check_safe_path "/var/cache/yum" && sudo rm -rf /var/cache/yum/*
                ;;
            *)
                echo -e "${YELLOW}未知发行版，执行通用清理${NC}"
                ;;
        esac
    fi

    # 通用清理
    echo -e "${YELLOW}执行跨平台清理...${NC}"
    check_safe_path "/tmp" && sudo find /tmp -type f -atime +7 -delete
    sudo journalctl --vacuum-time=1d --vacuum-size=100M

    # 最终重启提示（带确认）
    if $need_reboot; then
        echo -e "\n${RED}重要：以下操作需要重启生效${NC}"
        echo -e "1. 已执行内核更新或删除"
        
        read -p $'\033[33m是否立即重启系统？(y/N): \033[0m' reboot_choice
        if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}即将重启系统...${NC}"
            sleep 3  # 给用户3秒中断机会
            sudo reboot
        else
            echo -e "${YELLOW}您选择了不重启，请稍后手动执行 sudo reboot${NC}"
        fi
    else
        echo -e "\n${GREEN}所有清理已完成，无需重启${NC}"
    fi

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

# 模块静默拉取下载
MODULES_DIR="./modules"

download_module() {
    MODULE_NAME=$1
    MODULE_URL=$2

    # 如果模块已存在且大小>0，跳过下载
    if [ -s "$MODULES_DIR/$MODULE_NAME" ]; then
        return 0
    fi

    # 静默下载（不显示进度，仅错误输出）
    if ! curl -fsSL "$MODULE_URL" -o "$MODULES_DIR/$MODULE_NAME" 2>/dev/null; then
        echo -e "${RED}错误: 模块 $MODULE_NAME 下载失败${NC}" >&2
        return 1
    fi

    # 验证下载完整性（至少非空文件）
    if [ ! -s "$MODULES_DIR/$MODULE_NAME" ]; then
        echo -e "${RED}错误: 下载的模块 $MODULE_NAME 为空${NC}" >&2
        rm -f "$MODULES_DIR/$MODULE_NAME"
        return 1
    fi
}

# 初始化模块目录
mkdir -p "$MODULES_DIR"

# 静默下载所有模块（无输出提示）
download_module "system.sh" "https://raw.githubusercontent.com/dahuangying/dahuangying-toolbox/main/modules/system.sh"
download_module "docker.sh" "https://raw.githubusercontent.com/dahuangying/dahuangying-toolbox/main/modules/docker.sh"
download_module "network.sh" "https://raw.githubusercontent.com/dahuangying/dahuangying-toolbox/main/modules/network.sh"
download_module "nginx-proxy-manager.sh" "https://raw.githubusercontent.com/dahuangying/dahuangying-toolbox/main/modules/nginx-proxy-manager.sh"
download_module "1Panel.sh" "https://raw.githubusercontent.com/dahuangying/dahuangying-toolbox/main/modules/1Panel.sh"

# 为下载的模块赋予执行权限
chmod +x "$MODULES_DIR"/*

# 显示暂停，按任意键继续，字体设置为绿色
pause() {
    echo -e "${GREEN}操作完成，按任意键继续...${NC}"
    read -n 1 -s -r  # 等待用户按下任意键
    echo
}

# 主程序入口
while true; do
    show_menu
done






