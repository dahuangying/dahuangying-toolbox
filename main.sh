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
echo -e "${GREEN}  "大黄鹰-Linux服务器运维工具箱，是一款部署在github上开源的脚本工具，旨在为你提供简便的运维解决方案。"${NC}"
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
    echo -e "\nSSH失败记录:"
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

# 系统清理函数
system_cleanup() {
    # 颜色定义
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color

    # 暂停函数
    pause() {
        read -p "$(echo -e "${YELLOW}按回车键继续...${NC}")" dummy
    }

    NEED_REBOOT=false
    REBOOT_MARKER="/var/run/reboot-required"
    LOG_FILE="/var/log/dahuang_clean.log"

    # 安全验证函数
    safe_clean() {
        local path="$1"
        [[ "$path" == "/" ]] && { echo -e "${RED}危险路径禁止操作${NC}"; return 1; }
        [ -e "$path" ] || { echo -e "${YELLOW}路径不存在: $path${NC}"; return 1; }
        return 0
    }

    # 内核检测函数
    check_kernel() {
        CURRENT_KERNEL=$(uname -r)
        NEWEST_KERNEL=$(ls -t /boot/vmlinuz-* 2>/dev/null | head -n1 | sed 's/.*vmlinuz-//')
        
        if [ -n "$NEWEST_KERNEL" ] && [ "$CURRENT_KERNEL" != "$NEWEST_KERNEL" ]; then
            echo -e "${YELLOW}⚠️ 内核待更新: ${CURRENT_KERNEL} → ${NEWEST_KERNEL}${NC}"
            return 0
        fi
        return 1
    }

# 系统清理
system_cleanup() {
    echo -e "\n${GREEN}=== 系统清理 ===${NC}"
    
    # 检测系统类型
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            debian|ubuntu|raspbian)
                echo -e "${BLUE}[Debian/Ubuntu] 正在清理...${NC}"
                sudo apt-get autoremove -y
                sudo apt-get autoclean -y
                sudo apt-get clean -y
                sudo rm -rf /var/cache/apt/archives/*
                sudo journalctl --vacuum-time=7d  # 清理7天前的日志
                ;;
            centos|rhel|fedora|rocky|almalinux)
                echo -e "${BLUE}[RHEL/CentOS] 正在清理...${NC}"
                if command -v dnf >/dev/null; then
                    sudo dnf autoremove -y
                    sudo dnf clean all
                else
                    sudo yum autoremove -y
                    sudo yum clean all
                fi
                sudo rm -rf /var/cache/yum/*
                sudo journalctl --vacuum-time=7d
                ;;
            arch|manjaro)
                echo -e "${BLUE}[Arch/Manjaro] 正在清理...${NC}"
                sudo pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null  # 清理孤儿包
                sudo pacman -Sc --noconfirm  # 清理缓存
                sudo rm -rf /var/cache/pacman/pkg/*
                sudo journalctl --vacuum-time=7d
                ;;
            alpine)
                echo -e "${BLUE}[Alpine] 正在清理...${NC}"
                sudo apk cache clean
                sudo rm -rf /var/cache/apk/*
                ;;
            *)
                echo -e "${RED}不支持的Linux发行版: $ID${NC}"
                return 1
                ;;
        esac
    elif [ "$(uname)" == "Darwin" ]; then
        echo -e "${BLUE}[macOS] 正在清理...${NC}"
        brew cleanup
        brew autoremove
        rm -rf ~/Library/Caches/*
        sudo rm -rf /System/Library/Caches/*
    else
        echo -e "${RED}无法识别的操作系统${NC}"
        return 1
    fi

    # 通用清理（所有系统）
    echo -e "${YELLOW}执行通用清理...${NC}"
    sudo rm -rf /tmp/*
    sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
    sudo find /var/tmp -type f -atime +7 -delete

    echo -e "\n${GREEN}清理完成！${NC}"
    echo -e "释放空间：$(df -h / | awk 'NR==2{print $4}') 可用"
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
done  # 这里需要加上 done 来结束 while 循环
