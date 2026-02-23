#!/bin/bash
set -euo pipefail

# ========== 远程执行优化：超时+完整性+清理陷阱 ==========
cleanup() {
    echo -e "\n${YELLOW}脚本执行结束，清理临时文件...${NC}"
    docker rm -f $(docker ps -a --filter "name=_tmp_" -q) 2>/dev/null || true
}
trap cleanup EXIT

# 颜色变量
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
NC="\033[0m"

# 全局确认函数（移到最上方，避免子菜单调用失败）
confirm_action() {
    local prompt="$1"
    read -p "$(echo -e "${YELLOW}${prompt} (y/N): ${NC}")" choice
    [[ "$choice" =~ ^[Yy]$ ]] && return 0 || return 1
}

# 权限检查（优化提示，适配远程执行）
check_docker_permission() {
    if ! docker info &>/dev/null; then
        echo -e "${RED}错误：当前用户无 Docker 操作权限${NC}"
        echo -e "${YELLOW}远程执行解决方案：${NC}"
        echo "1. 重新运行：sudo bash <(curl -fsSL https://raw.githubusercontent.com/dahuangying/dahuangying-toolbox/main/main.sh)"
        echo "2. 配置权限：sudo usermod -aG docker $USER && newgrp docker"
        echo "3. 重新登录后再次执行脚本"
        exit 1
    fi
}

# Docker 版本检查（兼容远程执行的环境）
check_docker_version() {
    local min_version="20.10.0"
    local current_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "")
    if [ -n "$current_version" ]; then
        local min_arr=(${min_version//./ })
        local curr_arr=(${current_version//./ })
        for i in 0 1 2; do
            if [[ ${curr_arr[$i]:-0} -lt ${min_arr[$i]:-0} ]]; then
                echo -e "${YELLOW}警告：Docker 版本 $current_version 过低，建议升级后再使用${NC}"
                break
            elif [[ ${curr_arr[$i]:-0} -gt ${min_arr[$i]:-0} ]]; then
                break
            fi
        done
    fi
}

# 暂停函数（兼容远程终端）
pause() {
    echo -e "\n${GREEN}操作完成，按 Enter 键继续...${NC}"
    read -r || true  # 远程执行时防止 read 失败
}

# ========== 主菜单（优化显示+空值安全） ==========
show_menu() {
    clear
    # 检查 Docker 安装状态
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}╔════════════════════════════════╗${NC}"
        echo -e "${RED}║       Docker 未安装           ║${NC}"
        echo -e "${RED}╚════════════════════════════════╝${NC}"
        local containers=0
        local images=0
        local networks=0
        local volumes=0
    else
        # 空值安全获取资源数量（适配远程执行）
        local containers=$(docker ps -a -q 2>/dev/null | wc -l | awk '{print $1}')
        local images=$(docker images -q 2>/dev/null | wc -l | awk '{print $1}')
        local networks=$(docker network ls -q 2>/dev/null | wc -l | awk '{print $1}')
        local volumes=$(docker volume ls -q 2>/dev/null | wc -l | awk '{print $1}')
        echo -e "${GREEN}Docker 已安装${NC}"
        check_docker_version
    fi

    # 显示环境状态
    echo -e "${GREEN}环境状态： 容器: $containers  镜像: $images  网络: $networks  卷: $volumes ${NC}"
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}大黄鹰-Linux服务器运维工具箱菜单-Docker 管理脚本${NC}"
    echo -e "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}====================================================${NC}"
    echo "1. 查看 Docker 容器、镜像、卷和网络状态"
    echo "2. 安装/更新 Docker 环境"
    echo "3. 更新 Docker 容器"
    echo "4. 清理 Docker 容器"
    echo "5. Docker 容器管理"
    echo "6. Docker 镜像管理"
    echo "7. Docker 网络管理"
    echo "8. Docker 卷管理"
    echo "9. 卸载 Docker 环境"
    echo "0. 退出"
    read -p "请输入选项: " option
    case $option in
        1) show_docker_status ;;
        2) install_update_docker ;;
        3) update_menu ;;
        4) docker_cleanup ;;
        5) docker_container_management ;;
        6) docker_image_management ;;
        7) docker_network_management ;;
        8) docker_volume_management ;;
        9) uninstall_docker_environment ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效的选项，请重新选择！${NC}" && sleep 2 && show_menu ;;
    esac
}

# ========== 1. 查看 Docker 状态（修复变量+Compose 检查） ==========
show_docker_status() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker 未安装，无法查看状态${NC}"
        pause
        show_menu
    fi

    # 重新定义变量（解决作用域问题）
    local containers=$(docker ps -a -q | wc -l | awk '{print $1}')
    local images=$(docker images -q | wc -l | awk '{print $1}')
    local networks=$(docker network ls -q | wc -l | awk '{print $1}')
    local volumes=$(docker volume ls -q | wc -l | awk '{print $1}')

    echo -e "${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker版本${NC}"
    docker --version || true
    
    # 检查 Compose 两种形式（适配新版 Docker）
    echo -e "\n${GREEN}Docker Compose版本${NC}"
    if command -v docker-compose &> /dev/null; then
        docker-compose --version || true
    elif docker compose version &> /dev/null; then
        docker compose version || true
    else
        echo -e "${YELLOW}Docker Compose 未安装${NC}"
    fi

    echo -e "\n${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker容器: $containers${NC}"
    docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}" || true

    echo -e "\n${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker镜像: $images${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}" || true

    echo -e "\n${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker网络: $networks${NC}"
    docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}" || true

    echo -e "\n${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker卷: $volumes${NC}"
    docker volume ls --format "table {{.Driver}}\t{{.Name}}" || true

    pause
    show_menu
}

# ========== 2. 安装/更新 Docker ==========
install_update_docker() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误：安装 Docker 需要 root 权限${NC}"
        echo -e "${YELLOW}请使用：sudo bash <(curl -fsSL https://raw.githubusercontent.com/dahuangying/dahuangying-toolbox/main/main.sh)${NC}"
        pause
        show_menu
    fi

    echo -e "${CYAN}正在安装/更新 Docker...${NC}"

    # 检测系统发行版
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo -e "${RED}无法检测系统发行版${NC}"
        pause
        show_menu
    fi

    # 更新系统
    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
        apt-get update -y
        apt-get install -y ca-certificates curl gnupg lsb-release
        mkdir -p /etc/apt/trusted.gpg.d
        curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/docker.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update -y
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    elif [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]]; then
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        echo -e "${RED}不支持的操作系统：$DISTRO${NC}"
        pause
        show_menu
    fi

    # 启动并启用 Docker
    systemctl enable --now docker
    usermod -aG docker $SUDO_USER || true

    echo -e "${GREEN}Docker 和 Docker Compose 安装/更新完成！${NC}"
    echo -e "${YELLOW}注意：需要重新登录才能生效 docker 组权限${NC}"
    pause
    show_menu
}

# ========== 3. 更新容器子菜单 ==========
update_menu() {
    while true; do
        clear
        echo -e "${GREEN}    Docker容器更新管理    ${NC}"
        echo -e "${GREEN}=========================${NC}"
        echo "1. 手动选择更新容器"
        echo "2. 自动更新所有容器"
        echo "3. 更新指定容器"
        echo "0. 返回主菜单"
        
        read -p "请输入选项: " choice
        case $choice in
            1)
                echo -e "${CYAN}正在运行的容器列表：${NC}"
                docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" || true
                read -p "输入要更新的容器名称（多个用空格分隔）: " -a containers
                for container in "${containers[@]}"; do
                    safe_update_container "$container" false
                done
                ;;
            2)
                echo -e "${CYAN}正在批量更新所有容器...${NC}"
                local containers=$(docker ps -q)
                for container in $containers; do
                    local container_name=$(docker inspect --format '{{.Name}}' "$container" | sed 's/^\///')
                    safe_update_container "$container_name" true
                done
                ;;
            3)
                read -p "输入要更新的容器名称: " target
                safe_update_container "$target" false
                ;;
            0)
               show_menu
                ;;
            *)
                echo -e "${RED}无效选项！${NC}"
                ;;
        esac
        pause
    done
}

# 安全更新容器（优化端口解析+错误信息）
safe_update_container() {
    local container=$1
    local auto_mode=${2:-false}

    if [ -z "$container" ]; then
        echo -e "${RED}错误：未指定容器名称！${NC}"
        return 1
    fi

    if ! docker inspect "$container" &>/dev/null; then
        echo -e "${RED}错误：容器 '$container' 不存在！${NC}"
        echo -e "${CYAN}可用容器列表：${NC}"
        docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}' | column -t || true
        return 1
    fi

    echo -e "\n${CYAN}=== 正在处理容器: $container ===${NC}"

    # 获取容器配置（优化端口解析）
    local image=$(docker inspect --format '{{.Config.Image}}' "$container" | cut -d'@' -f1)
    local volumes=$(docker inspect --format '{{ range .Mounts }}-v {{ .Source }}:{{ .Destination }} {{ end }}' "$container")
    
    # 更可靠的端口解析
    local ports=""
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local port_map=$(echo "$line" | sed -e 's/=/:/' -e 's/\/tcp//' -e 's/\/udp//')
            ports="$ports -p $port_map"
        fi
    done < <(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{$p}}={{index $conf 0.HostPort}}{{end}} {{end}}' "$container" 2>/dev/null | tr ' ' '\n' | grep -v '^$')

    local envs=$(docker inspect --format '{{ range .Config.Env }}--env {{ . }} {{ end }}' "$container")
    local restart_policy=$(docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' "$container")
    local network=$(docker inspect --format '{{.HostConfig.NetworkMode}}' "$container")

    # 检查镜像更新（超时控制）
    echo -e "${YELLOW}▶ 正在检查镜像更新...${NC}"
    if ! timeout 300 docker pull "$image" >/dev/null 2>&1; then
        echo -e "${RED}✖ 镜像拉取失败或超时: $image${NC}"
        return 1
    fi

    # 判断是否需要更新
    local old_image_id=$(docker inspect --format '{{.Image}}' "$container")
    local new_image_id=$(docker inspect --format '{{.Id}}' "$image" 2>/dev/null || echo "")
    if [ "$old_image_id" == "$new_image_id" ] || [ -z "$new_image_id" ]; then
        echo -e "${YELLOW}✔ 当前已是最新版本${NC}"
        return 0
    fi

    # 手动模式确认
    if [ "$auto_mode" = "false" ] && ! confirm_action "确认更新容器 $container 吗？"; then
        return 0
    fi

    # 创建临时容器（详细错误信息）
    local new_name="${container}_tmp_$(date +%s)"
    echo -e "${CYAN}▶ 正在创建临时容器: $new_name${NC}"
    if ! docker run -d \
        --name "$new_name" \
        --restart "$restart_policy" \
        --network "$network" \
        $volumes \
        $ports \
        $envs \
        "$image" >/dev/null 2>&1; then
        local error_msg=$(docker logs "$new_name" 2>&1 | head -20)
        echo -e "${RED}✖ 临时容器创建失败！错误信息：${NC}"
        echo "$error_msg"
        docker rm -f "$new_name" 2>/dev/null || true
        return 1
    fi

    # 替换旧容器
    echo -e "${CYAN}▶ 正在替换旧容器...${NC}"
    if ! docker stop "$container" >/dev/null 2>&1; then
        echo -e "${RED}✖ 停止旧容器失败，回滚操作${NC}"
        docker rm -f "$new_name" 2>/dev/null || true
        return 1
    fi
    docker rm "$container" >/dev/null 2>&1 || true
    docker rename "$new_name" "$container" >/dev/null 2>&1 || true

    echo -e "${GREEN}✔ 容器 $container 更新成功！${NC}"
}

# ========== 4. Docker 清理子菜单 ==========
docker_cleanup() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}错误：未检测到Docker环境${NC}"
        pause
        show_menu
    fi

    show_cleanup_menu() {
        clear
        echo -e "${CYAN}=== Docker智能清理 ===${NC}"
        echo "1. 显示磁盘使用情况"
        echo "2. 执行全面清理"
        echo "3. 自定义清理项目"
        echo "0. 返回主菜单"
        read -p "请输入选项: " sub_option
        case $sub_option in
            1) show_disk_usage ; pause ; show_cleanup_menu ;;
            2) full_cleanup ;;
            3) custom_cleanup ;;
            0) show_menu ;;
            *) echo -e "${RED}无效选项！${NC}" ; pause ; show_cleanup_menu ;;
        esac
    }

    show_disk_usage() {
        echo -e "\n${CYAN}=== 当前Docker磁盘使用 ===${NC}"
        docker system df --format '类型\t总数\t活跃数\t大小\t可回收'
        docker system df --format '{{.Type}}\t{{.TotalCount}}\t{{.ActiveCount}}\t{{.Size}}\t{{.Reclaimable}}'
    }

    full_cleanup() {
        if ! confirm_action "确认要进行全面清理吗？(包括容器/镜像/网络/卷)"; then
            echo -e "${YELLOW}已取消全面清理${NC}"
            pause
            show_cleanup_menu
            return
        fi
        
        echo -e "${GREEN}◆ 开始全面清理...${NC}"
        docker system prune -a --volumes -f
        echo -e "${GREEN}✓ 全面清理完成！${NC}"
        show_disk_usage
        pause
        show_cleanup_menu
    }

    custom_cleanup() {
        clear
        echo -e "${CYAN}=== 自定义清理选项 ===${NC}"
        echo "1. 清理构建缓存"
        echo "2. 清理停止的容器"
        echo "3. 清理未使用镜像"
        echo "4. 清理孤立网络"
        echo "5. 清理未使用卷"
        echo "0. 返回上级"
        read -p "请选择要清理的项目: " custom_option
        case $custom_option in
            1) clean_build_cache ;;
            2) clean_containers ;;
            3) clean_images ;;
            4) clean_networks ;;
            5) clean_volumes ;;
            0) show_cleanup_menu ;;
            *) echo -e "${RED}无效选项！${NC}" ; pause ; custom_cleanup ;;
        esac
    }

    clean_build_cache() {
        echo -e "${GREEN}◆ 清理构建缓存...${NC}"
        docker builder prune -f
        echo -e "${GREEN}✓ 构建缓存已清理${NC}"
        pause
        custom_cleanup
    }

    clean_containers() {
        if confirm_action "确定要清理所有停止的容器吗？"; then
            echo -e "${GREEN}◆ 清理停止的容器...${NC}"
            docker container prune -f
        else
            echo -e "${YELLOW}已取消容器清理${NC}"
        fi
        pause
        custom_cleanup
    }

    clean_images() {
        clear
        echo -e "${CYAN}=== 镜像清理选项 ===${NC}"
        echo "1. 仅清理悬空镜像"
        echo "2. 清理所有未使用镜像"
        echo "0. 返回上级"
        read -p "请选择清理方式: " img_choice
        case $img_choice in
            1) docker image prune -f ; echo -e "${GREEN}✓ 悬空镜像已清理${NC}" ;;
            2) docker image prune -a -f ; echo -e "${GREEN}✓ 未使用镜像已清理${NC}" ;;
            0) custom_cleanup ; return ;;
            *) echo -e "${RED}无效选择！${NC}" ;;
        esac
        pause
        custom_cleanup
    }

    clean_networks() {
        echo -e "${GREEN}◆ 清理孤立网络...${NC}"
        docker network prune -f
        pause
        custom_cleanup
    }

    clean_volumes() {
        if confirm_action "确定要清理未使用的卷吗？"; then
            echo -e "${GREEN}◆ 清理未使用卷...${NC}"
            docker volume prune -f
        else
            echo -e "${YELLOW}已取消卷清理${NC}"
        fi
        pause
        custom_cleanup
    }

    show_cleanup_menu
}

# ========== 5. 容器管理子菜单 ==========
docker_container_management() {
    echo -e "${GREEN}Docker容器管理${NC}"
    echo -e "${GREEN}==============================${NC}"
    echo "1. 启动容器"
    echo "2. 停止容器"
    echo "3. 启动所有容器"
    echo "4. 停止所有容器"
    echo "5. 创建指定容器"
    echo "6. 删除指定容器"
    echo "7. 删除所有容器"
    echo "0. 返回"
    read -p "请输入选项: " container_option
    case $container_option in
        1) start_container ;;
        2) stop_container ;;
        3) start_all_containers ;;
        4) stop_all_containers ;;
        5) create_new_container ;;
        6) remove_specified_container ;;
        7) remove_all_containers ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && docker_container_management ;;
    esac
}

start_container() {
    read -p "请输入要启动的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_container_management
    fi
    docker start $container_id
    echo -e "${GREEN}容器 $container_id 已启动！${NC}"
    pause
    docker_container_management
}

stop_container() {
    read -p "请输入要停止的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_container_management
    fi
    docker stop $container_id
    echo -e "${GREEN}容器 $container_id 已停止！${NC}"
    pause
    docker_container_management
}

start_all_containers() {
    local container_ids=$(docker ps -a -q)
    if [ -z "$container_ids" ]; then
        echo -e "${YELLOW}没有可启动的容器${NC}"
    else
        docker start $container_ids
        echo -e "${GREEN}所有容器已启动！${NC}"
    fi
    pause
    docker_container_management
}

stop_all_containers() {
    local container_ids=$(docker ps -q)
    if [ -z "$container_ids" ]; then
        echo -e "${YELLOW}没有运行中的容器${NC}"
    else
        docker stop $container_ids
        echo -e "${GREEN}所有容器已停止！${NC}"
    fi
    pause
    docker_container_management
}

create_new_container() {
    read -p "请输入新容器的镜像名称: " image_name
    if [ -z "$image_name" ]; then
        docker_container_management
    fi
    read -p "请输入新容器的名称（可选）: " container_name
    if [ -z "$container_name" ]; then
        container_name="auto_$(date +%s)"
        echo -e "${YELLOW}未输入容器名称，自动生成：$container_name${NC}"
    fi
    if docker inspect "$container_name" &>/dev/null; then
        echo -e "${RED}容器名称 $container_name 已存在${NC}"
        docker_container_management
    fi
    docker run -d --name $container_name $image_name
    echo -e "${GREEN}新容器已创建！${NC}"
    pause
    docker_container_management
}

remove_specified_container() {
    read -p "请输入要删除的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_container_management
    fi
    docker rm -f $container_id
    echo -e "${GREEN}容器 $container_id 已删除！${NC}"
    pause
    docker_container_management
}

remove_all_containers() {
    local container_count=$(docker ps -a -q | wc -l | awk '{print $1}')
    if [ "$container_count" -eq 0 ]; then
        echo -e "${YELLOW}没有可删除的容器${NC}"
        pause
        docker_container_management
    fi
    read -p "您确定要删除所有 $container_count 个容器吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker rm -f $(docker ps -a -q)
        echo -e "${GREEN}所有容器已删除！${NC}"
    else
        echo -e "${YELLOW}已取消删除操作${NC}"
    fi
    pause
    docker_container_management
}

# ========== 6. 镜像管理子菜单 ==========
docker_image_management() {
    echo -e "${GREEN}Docker镜像管理${NC}"
    echo -e "${GREEN}==============================${NC}"
    echo "1. 删除指定镜像"
    echo "2. 创建指定容器"
    echo "3. 删除所有镜像"
    echo "0. 返回"
    read -p "请输入选项: " image_option
    case $image_option in
        1) remove_specified_image ;;
        2) create_new_container ;;
        3) remove_all_images ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && docker_image_management ;;
    esac
}

remove_specified_image() {
    read -p "请输入要删除的镜像 ID 或名称: " image_id
    if [ -z "$image_id" ]; then
        docker_image_management
    fi
    docker rmi -f $image_id
    echo -e "${GREEN}镜像 $image_id 已删除！${NC}"
    pause
    docker_image_management
}

remove_all_images() {
    local image_count=$(docker images -q | wc -l | awk '{print $1}')
    if [ "$image_count" -eq 0 ]; then
        echo -e "${YELLOW}没有可删除的镜像${NC}"
        pause
        docker_image_management
    fi
    read -p "您确定要删除所有 $image_count 个镜像吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker rmi -f $(docker images -q) || echo -e "${RED}部分镜像删除失败（可能被容器引用）${NC}"
        echo -e "${GREEN}所有可删除的镜像已删除！${NC}"
    else
        echo -e "${YELLOW}已取消删除操作${NC}"
    fi
    pause
    docker_image_management
}

# ========== 7. 网络管理子菜单 ==========
docker_network_management() {
    echo -e "${GREEN}Docker网络管理${NC}"
    echo -e "${GREEN}==============================${NC}"
    echo "1. 创建网络"
    echo "2. 加入网络"
    echo "3. 退出网络"
    echo "4. 删除网络"
    echo "0. 返回"
    read -p "请输入选项: " network_option
    case $network_option in
        1) create_network ;;
        2) join_network ;;
        3) leave_network ;;
        4) delete_network ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && docker_network_management ;;
    esac
}

create_network() {
    read -p "请输入要创建的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    if docker inspect "$network_name" &>/dev/null; then
        echo -e "${RED}网络 $network_name 已存在${NC}"
        docker_network_management
    fi
    docker network create $network_name
    echo -e "${GREEN}网络 $network_name 已创建！${NC}"
    pause
    docker_network_management
}

join_network() {
    read -p "请输入要加入的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_network_management
    fi
    read -p "请输入要加入的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    docker network connect $network_name $container_id
    echo -e "${GREEN}容器 $container_id 已加入网络 $network_name！${NC}"
    pause
    docker_network_management
}

leave_network() {
    read -p "请输入要退出的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_network_management
    fi
    read -p "请输入要退出的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    docker network disconnect $network_name $container_id
    echo -e "${GREEN}容器 $container_id 已退出网络 $network_name！${NC}"
    pause
    docker_network_management
}

delete_network() {
    read -p "请输入要删除的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    docker network rm $network_name
    echo -e "${GREEN}网络 $network_name 已删除！${NC}"
    pause
    docker_network_management
}

# ========== 8. 卷管理子菜单（空值处理） ==========
docker_volume_management() {
    echo -e "${GREEN}Docker卷管理${NC}"
    echo -e "${GREEN}==============================${NC}"
    echo "1. 创建新卷"
    echo "2. 删除指定卷"
    echo "3. 删除所有卷"
    echo "0. 返回"
    read -p "请输入选项: " volume_option
    case $volume_option in
        1) create_volume ;;
        2) delete_specified_volume ;;
        3) delete_all_volumes ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && docker_volume_management ;;
    esac
}

create_volume() {
    read -p "请输入要创建的新卷名称: " volume_name
    if [ -z "$volume_name" ]; then
        docker_volume_management
    fi
    if docker inspect "$volume_name" &>/dev/null; then
        echo -e "${RED}卷 $volume_name 已存在${NC}"
        docker_volume_management
    fi
    docker volume create $volume_name
    echo -e "${GREEN}新卷 $volume_name 已创建！${NC}"
    pause
    docker_volume_management
}

delete_specified_volume() {
    read -p "请输入要删除的卷名称: " volume_name
    if [ -z "$volume_name" ]; then
        docker_volume_management
    fi
    docker volume rm $volume_name
    echo -e "${GREEN}卷 $volume_name 已删除！${NC}"
    pause
    docker_volume_management
}

delete_all_volumes() {
    local volumes=$(docker volume ls -q)
    local volume_count=$(echo "$volumes" | wc -l | awk '{print $1}')
    if [ "$volume_count" -eq 0 ]; then
        echo -e "${YELLOW}没有可删除的卷${NC}"
        pause
        docker_volume_management
    fi
    read -p "您确定要删除所有 $volume_count 个卷吗？(数据将永久删除)[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        if [ -n "$volumes" ]; then
            docker volume rm $volumes || echo -e "${RED}部分卷删除失败（可能被容器使用）${NC}"
        fi
        echo -e "${GREEN}所有可删除的卷已删除！${NC}"
    else
        echo -e "${YELLOW}已取消删除操作${NC}"
    fi
    pause
    docker_volume_management
}

# ========== 9. 卸载 Docker ==========
uninstall_docker_environment() {
    read -p "您确定要卸载 Docker 吗？此操作将删除所有 Docker 容器、镜像及数据。请输入 y 确认：" confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        # 执行 Docker 卸载操作
        clean_docker_containers_images
        uninstall_docker
        delete_docker_files
        delete_docker_user_group
        delete_docker_install_script
        echo -e "${GREEN}Docker 环境已卸载并清理完成！${NC}"
        pause
        show_menu
    else
        echo "取消卸载操作。"
        pause
        show_menu
    fi
}

# 检测系统类型
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO=$ID
fi

# 停止并删除 Docker 容器和镜像
function clean_docker_containers_images {
    echo "停止并删除所有容器和镜像..."
    sudo docker stop $(sudo docker ps -a -q) 2>/dev/null || true
    sudo docker rm $(sudo docker ps -a -q) 2>/dev/null || true
    sudo docker rmi $(sudo docker images -q) 2>/dev/null || true
}

# 卸载 Docker 对应的包
function uninstall_docker {
    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
        echo "卸载 Docker（适用于 Ubuntu/Debian）..."
        sudo apt-get purge -y docker-ce docker-ce-cli containerd.io 2>/dev/null || true
    elif [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]]; then
        echo "卸载 Docker（适用于 CentOS/RHEL）..."
        sudo yum remove -y docker-ce docker-ce-cli containerd.io 2>/dev/null || true
    else
        echo "不支持的操作系统。"
        exit 1
    fi
}

# 删除 Docker 相关文件和目录
function delete_docker_files {
    echo "删除 Docker 配置和数据文件..."
    sudo rm -rf /var/lib/docker 2>/dev/null || true
    sudo rm -rf /var/lib/containerd 2>/dev/null || true
    sudo rm -rf /etc/docker 2>/dev/null || true
    sudo rm -rf /var/run/docker 2>/dev/null || true
}

# 删除 Docker 用户和组（可选）
function delete_docker_user_group {
    echo "删除 Docker 用户和组..."
    sudo deluser docker 2>/dev/null || true
    sudo delgroup docker 2>/dev/null || true
}

# 删除 Docker 安装脚本文件（如果存在）
function delete_docker_install_script {
    if [[ -f /get-docker.sh ]]; then
        echo "删除 Docker 安装脚本文件..."
        sudo rm -f /get-docker.sh 2>/dev/null || true
    fi
}

# ========== 启动脚本 ==========
check_docker_permission
show_menu
