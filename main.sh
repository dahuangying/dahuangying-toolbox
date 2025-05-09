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
    echo "8. 卸载大黄鹰脚本"
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

# 1. 显示系统信息
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

# 2. 系统更新
system_update() {
    local NEED_REBOOT=false
    local KERNEL_REBOOT_FILE="/var/run/reboot-required.pkgs"
    local REBOOT_REQUIRED_FILE="/var/run/reboot-required"

    echo -e "\n${GREEN}=== 系统更新开始 ===${NC}"

    # 系统检测
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            debian|ubuntu)
                echo -e "${BLUE}[Debian/Ubuntu] 更新中...${NC}"
                
                # 记录当前内核版本
                CURRENT_KERNEL=$(uname -r)
                
                # 执行更新
                if ! sudo apt-get update; then
                    echo -e "${RED}更新软件源失败${NC}"
                    return 1
                fi
                
                # 获取可用的安全更新
                SECURITY_UPDATES=$(sudo apt-get upgrade --dry-run | grep -i security | wc -l)
                
                # 执行更新
                sudo apt-get upgrade -y
                [ $SECURITY_UPDATES -gt 0 ] && sudo apt-get --only-upgrade install security-updates -y
                
                # 检查是否需要重启（更精确的判断）
                if [ -f "$REBOOT_REQUIRED_FILE" ] || \
                   [ -f "$KERNEL_REBOOT_FILE" ] || \
                   [ "$(sudo needrestart -b 2>/dev/null | grep -c 'NEEDRESTART-KERNEL')" -gt 0 ]; then
                    NEED_REBOOT=true
                fi
                
                # 检查内核是否更新
                NEW_KERNEL=$(ls -t /boot/vmlinuz-* | head -n1 | sed 's/.*vmlinuz-//')
                if [ "$NEW_KERNEL" != "$CURRENT_KERNEL" ]; then
                    echo -e "${YELLOW}内核已更新: ${CURRENT_KERNEL} → ${NEW_KERNEL}${NC}"
                    NEED_REBOOT=true
                fi
                ;;

            centos|rhel)
                echo -e "${BLUE}[RHEL/CentOS] 更新中...${NC}"
                # 记录当前内核
                CURRENT_KERNEL=$(uname -r)
                
                # 执行更新
                sudo yum update --security -y
                
                # 检查内核是否更新
                NEW_KERNEL=$(rpm -q kernel | tail -n1 | sed 's/kernel-//')
                if [ "$NEW_KERNEL" != "$CURRENT_KERNEL" ]; then
                    echo -e "${YELLOW}内核已更新: ${CURRENT_KERNEL} → ${NEW_KERNEL}${NC}"
                    NEED_REBOOT=true
                fi
                
                # 检查其他需要重启的更新
                if sudo needs-restarting -r >/dev/null 2>&1; then
                    NEED_REBOOT=true
                fi
                ;;

            arch)
                echo -e "${BLUE}[Arch] 更新中...${NC}"
                # Arch通常不需要专门重启
                sudo pacman -Syu --noconfirm
                ;;
        esac

        # 通用Flatpak/Snap更新
        command -v flatpak >/dev/null && flatpak update -y
        command -v snap >/dev/null && sudo snap refresh
    fi

    # 更新后处理
    echo -e "\n${GREEN}=== 更新完成 ===${NC}"
    
    # 更精确的重启判断
    if $NEED_REBOOT; then
        echo -e "${YELLOW}系统需要重启以完成更新${NC}"
        echo -e "以下更新需要重启:"
        [ -f "$KERNEL_REBOOT_FILE" ] && cat "$KERNEL_REBOOT_FILE" | sed 's/^/• /'
        [ -f "$REBOOT_REQUIRED_FILE" ] && cat "$REBOOT_REQUIRED_FILE" | sed 's/^/• /'
        
        read -p $'\033[33m是否立即重启？(y/N): \033[0m' choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}系统将在5秒后重启...${NC}"
            # 清除重启标记
            sudo rm -f "$REBOOT_REQUIRED_FILE" "$KERNEL_REBOOT_FILE" 2>/dev/null
            sleep 5
            sudo reboot
        else
            echo -e "${YELLOW}请稍后手动执行 reboot 命令${NC}"
        fi
    else
        echo -e "${CYAN}无需重启，所有更新已实时生效${NC}"
    fi

# 在更新完成后的建议检查部分替换为：

echo -e "\n${CYAN}=== 更新后健康检查 ===${NC}"

case $ID in
    debian|ubuntu)
        # 1. 检查待重启服务（直接显示结果）
        echo -e "${YELLOW}【待重启服务检测】${NC}"
        if command -v needrestart >/dev/null; then
            RESTART_NEEDED=$(sudo needrestart -b 2>/dev/null)
            if [[ $RESTART_NEEDED == *"NEEDRESTART-KERNEL"* ]]; then
                echo -e "${RED}→ 需要重启: 内核已更新${NC}"
            elif [[ $RESTART_NEEDED == *"NEEDRESTART-SVC"* ]]; then
                echo -e "${YELLOW}→ 需要重启服务:${NC}"
                echo "$RESTART_NEEDED" | grep "NEEDRESTART-SVC" | cut -d: -f2
            else
                echo -e "${GREEN}→ 没有需要重启的服务${NC}"
            fi
        else
            echo "安装needrestart工具获取更精确信息: sudo apt install needrestart"
        fi

        # 2. 检查残留安全更新（更精确的命令）
        echo -e "\n${YELLOW}【安全更新检查】${NC}"
        SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
        if [ $SECURITY_UPDATES -gt 0 ]; then
            echo -e "${RED}→ 发现未完成的安全更新:${NC}"
            apt list --upgradable 2>/dev/null | grep -i security
        else
            echo -e "${GREEN}→ 没有未完成的安全更新${NC}"
        fi

        # 3. 新增检查（推荐）
        echo -e "\n${YELLOW}【建议操作】${NC}"
        if [ -f "/var/run/reboot-required" ]; then
            echo -e "${RED}→ 系统要求重启以完成更新${NC}"
            cat /var/run/reboot-required | sed 's/^/  /'
        fi
        ;;
        
    centos|rhel)
        # RHEL系专用检查
        echo -e "${YELLOW}【待重启服务检测】${NC}"
        if command -v needs-restarting >/dev/null; then
            sudo needs-restarting -r 2>/dev/null || echo -e "${RED}→ 系统需要重启${NC}"
            echo -e "\n${YELLOW}【需要重启的服务】${NC}"
            sudo needs-restarting -s
        fi
        
        echo -e "\n${YELLOW}【安全更新检查】${NC}"
        sudo yum updateinfo list sec 2>/dev/null || echo "无未完成的安全更新"
        ;;
esac
    pause
}

# 3. 系统清理
system_cleanup() {

    # 安全清理函数
    safe_clean() {
        local path="$1"
        [[ "$path" == "/" ]] && { echo -e "${RED}错误：禁止操作根目录${NC}"; return 1; }
        [ -e "$path" ] || { echo -e "${YELLOW}警告：路径不存在 [$path]${NC}"; return 1; }
        return 0
    }

    # 智能重启检测
    check_reboot() {
        local reboot_marker="/var/run/reboot-required"
        local kernel_changed=$( [ "$(uname -r)" != "$(ls -t /boot/vmlinuz-* 2>/dev/null | head -n1 | sed 's/.*vmlinuz-//')" ] && echo 1 )
        
        if [ -f "$reboot_marker" ] || [ -n "$kernel_changed" ]; then
            echo -e "\n${RED}⚠️ 需要重启以完成以下更新：${NC}"
            [ -f "$reboot_marker" ] && cat "$reboot_marker" | sed 's/^/  /'
            [ -n "$kernel_changed" ] && echo -e "  ${YELLOW}内核已更新${NC}"
            return 0
        fi
        return 1
    }

    # 主清理流程
    echo -e "\n${GREEN}=== 系统清理开始 ===${NC}"
    local start_time=$(date +%s)
    local disk_before=$(df -h / | awk 'NR==2{print $4}')

    # 按发行版清理
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            debian|ubuntu)
                echo -e "${CYAN}◆ Debian系清理${NC}"
                sudo apt-get autoremove --purge -y
                sudo apt-get clean
                safe_clean "/var/lib/apt/lists/" && sudo rm -rf /var/lib/apt/lists/*
                ;;
            centos|rhel)
                echo -e "${CYAN}◆ RHEL系清理${NC}"
                if command -v dnf >/dev/null; then
                    sudo dnf autoremove -y
                    sudo dnf clean all
                else
                    sudo yum autoremove -y
                    sudo yum clean all
                fi
                safe_clean "/var/cache/yum" && sudo rm -rf /var/cache/yum/*
                ;;
        esac
    fi

    # 通用清理
    echo -e "\n${CYAN}◆ 临时文件清理${NC}"
    safe_clean "/tmp" && sudo find /tmp -type f -atime +1 -delete
    safe_clean "/var/tmp" && sudo find /var/tmp -type f -atime +7 -delete

    echo -e "\n${CYAN}◆ 日志清理${NC}"
    sudo journalctl --vacuum-time=3d 2>/dev/null
    safe_clean "/var/log" && sudo find /var/log -type f \( -name "*.gz" -o -name "*.old" \) -mtime +7 -delete

    # 结果统计
    local disk_after=$(df -h / | awk 'NR==2{print $4}')
    echo -e "\n${GREEN}✓ 清理完成 [耗时: $(( $(date +%s) - start_time ))秒]${NC}"
    echo -e "空间变化: ${disk_before} → ${disk_after}"

    # 重启建议
    if check_reboot; then
        read -p "$(echo -e "${YELLOW}是否立即重启？(y/N): ${NC}")" choice
        if [[ "$choice" =~ ^[Yy] ]]; then
            echo -e "${GREEN}系统将在5秒后重启...${NC}"
            sleep 5
            sudo reboot
        fi
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
