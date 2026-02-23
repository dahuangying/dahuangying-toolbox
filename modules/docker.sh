#!/bin/bash

# 设置颜色变量（新增黄色、青色、红色）
GREEN="\033[0;32m"  # 绿色
YELLOW="\033[1;33m" # 黄色
CYAN="\033[0;36m"   # 青色
RED="\033[0;31m"    # 红色
NC="\033[0m"        # 重置颜色

# ========== 优化10：退出陷阱清理 ==========
cleanup() {
    echo -e "\n${YELLOW}脚本执行结束，清理临时文件...${NC}"
    # 清理临时容器（匹配 _tmp_ 后缀）
    docker rm -f $(docker ps -a --filter "name=_tmp_" -q) 2>/dev/null || true
}
trap cleanup EXIT

# ========== 优化2：confirm_action 移到前面（解决函数未定义问题） ==========
# 安全确认函数
confirm_action() {
    local prompt="$1"
    read -p "$(echo -e "${YELLOW}${prompt} (y/N): ${NC}")" choice
    [[ "$choice" =~ ^[Yy]$ ]] && return 0 || return 1
}

# ========== 优化3：Docker 权限检查 ==========
check_docker_permission() {
    if ! docker info &>/dev/null; then
        echo -e "${RED}错误：当前用户无 Docker 操作权限${NC}"
        echo -e "${YELLOW}尝试解决方案：${NC}"
        echo "1. 使用 sudo 运行脚本"
        echo "2. 将当前用户添加到 docker 组：sudo usermod -aG docker $USER"
        echo "3. 重新登录或执行 newgrp docker 使组权限生效"
        exit 1
    fi
}

# ========== 优化9：Docker 版本兼容性检查 ==========
check_docker_version() {
    local min_version="20.10.0"
    local current_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    if [ -n "$current_version" ]; then
        # 拆分版本号进行比较
        local min_arr=(${min_version//./ })
        local curr_arr=(${current_version//./ })
        for i in 0 1 2; do
            if [[ ${curr_arr[$i]:-0} -lt ${min_arr[$i]:-0} ]]; then
                echo -e "${YELLOW}警告：当前 Docker 版本 $current_version 可能过旧，建议升级到 $min_version 以上${NC}"
                break
            elif [[ ${curr_arr[$i]:-0} -gt ${min_arr[$i]:-0} ]]; then
                break
            fi
        done
    fi
}

# 显示主菜单
show_menu() {
    clear
    # ========== 优化10：null 安全的方式获取资源数量 ==========
    # 获取当前环境数据（增加错误重定向）
    if ! command -v docker &> /dev/null; then
        containers=0
        images=0
        networks=0
        volumes=0
    else
        containers=$(docker ps -a -q 2>/dev/null | wc -l | awk '{print $1}')
        images=$(docker images -q 2>/dev/null | wc -l | awk '{print $1}')
        networks=$(docker network ls -q 2>/dev/null | wc -l | awk '{print $1}')
        volumes=$(docker volume ls -q 2>/dev/null | wc -l | awk '{print $1}')
        # 检查 Docker 版本
        check_docker_version
    fi

    # 显示环境状态
    echo -e "${GREEN}环境状态： 容器: $containers  镜像: $images  网络: $networks  卷: $volumes ${NC}"
     # 显示 Docker 安装状态
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}Docker 已安装${NC}"
    else
        echo -e "${RED}Docker 未安装${NC}"
    fi
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
        *) echo "无效的选项，请重新选择！" && sleep 2 && show_menu ;;
    esac
}

# 1. 查看 Docker 容器、镜像、卷和网络状态
show_docker_status() {
    # ========== 优化1：重新定义变量（解决作用域问题） ==========
    # 在函数内重新获取数量
    local containers=$(docker ps -a -q 2>/dev/null | wc -l | awk '{print $1}')
    local images=$(docker images -q 2>/dev/null | wc -l | awk '{print $1}')
    local networks=$(docker network ls -q 2>/dev/null | wc -l | awk '{print $1}')
    local volumes=$(docker volume ls -q 2>/dev/null | wc -l | awk '{print $1}')

    echo -e "${GREEN}==============================${NC}"
    echo -e "${GREEN}Docker版本${NC}"
    docker --version || true
    # ========== 优化6：Docker Compose 插件检查 ==========
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

# 2. 安装或更新 Docker 环境
install_update_docker() {
    echo "正在安装或更新 Docker..."

    # 更新系统
    sudo apt-get update -y

    # 安装 Docker
    sudo apt-get install -y docker.io

    # 启动 Docker 服务
    sudo systemctl enable --now docker

    # 安装 Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/2.35.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    echo -e "${GREEN}Docker 和 Docker Compose 安装/更新完成！${NC}"
    pause
    show_menu
}

# 3.更新Docker容器管理
update_menu() {
    while true; do
        clear
        echo -e "${GREEN}    Docker容器更新管理    ${NC}"
	echo -e "${GREEN}=========================${NC}"
        echo "1. 手动选择更新容器"
        echo "2. 自动更新所有容器"
        echo "3. 更新指定容器"
        echo "0. 返回"
        
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
                # 兼容 Bash 3（替换 mapfile）
                local containers=$(docker ps -q)
                for container in $containers; do
                    safe_update_container "$(docker inspect --format '{{.Name}}' "$container" | sed 's/^\///')" true
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

# 安全更新容器函数
safe_update_container() {
    local container=$1
    local auto_mode=${2:-false}

    # 空容器名检查
    if [ -z "$container" ]; then
        echo -e "${RED}错误：未指定容器名称！${NC}"
        return 1
    fi

    # 容器存在性检查
    if ! docker inspect "$container" &>/dev/null; then
        echo -e "${RED}错误：容器 '$container' 不存在！${NC}"
        echo -e "${CYAN}可用容器列表：${NC}"
        docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}' | column -t || true
        echo -e "${NC}"
        return 1
    fi

    echo -e "\n${CYAN}=== 正在处理容器: $container ===${NC}"

    # 获取容器配置
    local image=$(docker inspect --format '{{.Config.Image}}' "$container" | cut -d'@' -f1)
    local volumes=$(docker inspect --format '{{ range .Mounts }}-v {{ .Source }}:{{ .Destination }} {{ end }}' "$container")
    # ========== 优化5：更可靠的端口解析 ==========
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

    # 检查镜像更新（增加超时）
    echo -e "${YELLOW}▶ 正在检查镜像更新...${NC}"
    if ! timeout 300 docker pull "$image" >/dev/null 2>&1; then
        echo -e "${RED}✖ 镜像拉取失败: $image${NC}"
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

    # 创建临时容器
    local new_name="${container}_tmp_$(date +%s)"
    echo -e "${CYAN}▶ 正在创建临时容器: $new_name${NC}"
    # ========== 优化8：更详细的错误信息 ==========
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

    # 替换旧容器（增加错误处理）
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

# 4. Docker智能清理（完整集成）
docker_cleanup() {
    # 环境检查
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}错误：未检测到Docker环境${NC}"
        pause
        show_menu
    fi

    # 清理子菜单
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

    # 显示磁盘使用
    show_disk_usage() {
        echo -e "\n${CYAN}=== 当前Docker磁盘使用 ===${NC}"
        docker system df --format '{
            "类型": "{{.Type}}",
            "总数": "{{.TotalCount}}",
            "活跃数": "{{.ActiveCount}}",
            "大小": "{{.Size}}",
            "可回收": "{{.Reclaimable}}"
        }' | awk -F'"' 'BEGIN {
            printf "%-10s %-8s %-8s %-12s %-12s\n","类型","总数","活跃","大小","可回收"
        }
        NR>1 {
            gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$4)
            gsub(/^ +| +$/,"",$6); gsub(/^ +| +$/,"",$8)
            gsub(/^ +| +$/,"",$10)
            printf "%-10s %-8s %-8s %-12s %-12s\n",$2,$4,$6,$8,$10
        }'
    }

    # 全面清理
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

    # 自定义清理
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

    # 清理构建缓存
    clean_build_cache() {
        echo -e "${GREEN}◆ 清理构建缓存...${NC}"
        docker builder prune -f
        echo -e "${GREEN}✓ 构建缓存已清理${NC}"
        pause
        custom_cleanup
    }

    # 清理停止的容器
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

    # 清理镜像
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

    # 清理网络
    clean_networks() {
        echo -e "${GREEN}◆ 清理孤立网络...${NC}"
        docker network prune -f
        pause
        custom_cleanup
    }

    # 清理卷
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

# 5. Docker 容器管理
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

# 启动容器
start_container() {
    read -p "请输入要启动的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_container_management
    fi
    docker start $container_id || echo -e "${RED}启动容器失败${NC}"
    echo -e "${GREEN}容器 $container_id 已启动！${NC}"
    pause
    docker_container_management
}

# 停止容器
stop_container() {
    read -p "请输入要停止的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_container_management
    fi
    docker stop $container_id || echo -e "${RED}停止容器失败${NC}"
    echo -e "${GREEN}容器 $container_id 已停止！${NC}"
    pause
    docker_container_management
}

# 启动所有容器（增加空值处理）
start_all_containers() {
    local container_ids=$(docker ps -a -q)
    if [ -z "$container_ids" ]; then
        echo -e "${YELLOW}没有可启动的容器${NC}"
    else
        docker start $container_ids || echo -e "${RED}部分容器启动失败${NC}"
        echo -e "${GREEN}所有容器已启动！${NC}"
    fi
    pause
    docker_container_management
}

# 停止所有容器（增加空值处理）
stop_all_containers() {
    local container_ids=$(docker ps -q)
    if [ -z "$container_ids" ]; then
        echo -e "${YELLOW}没有运行中的容器${NC}"
    else
        docker stop $container_ids || echo -e "${RED}部分容器停止失败${NC}"
        echo -e "${GREEN}所有容器已停止！${NC}"
    fi
    pause
    docker_container_management
}

# 创建指定容器
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
    # 检查容器名称是否已存在
    if docker inspect "$container_name" &>/dev/null; then
        echo -e "${RED}容器名称 $container_name 已存在${NC}"
        docker_container_management
    fi
    docker run -d --name $container_name $image_name || echo -e "${RED}创建容器失败${NC}"
    echo -e "${GREEN}新容器已创建！${NC}"
    pause
    docker_container_management
}

# 删除指定容器
remove_specified_container() {
    read -p "请输入要删除的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_container_management
    fi
    docker rm -f $container_id || echo -e "${RED}删除容器失败${NC}"
    echo -e "${GREEN}容器 $container_id 已删除！${NC}"
    pause
    docker_container_management
}

# 删除所有容器（增加确认和空值处理）
remove_all_containers() {
    local container_count=$(docker ps -a -q | wc -l | awk '{print $1}')
    if [ "$container_count" -eq 0 ]; then
        echo -e "${YELLOW}没有可删除的容器${NC}"
        pause
        docker_container_management
        return
    fi
    read -p "您确定要删除所有 $container_count 个容器吗？[y/n]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker rm -f $(docker ps -a -q) || echo -e "${RED}部分容器删除失败${NC}"
        echo -e "${GREEN}所有容器已删除！${NC}"
    else
        echo -e "${YELLOW}已取消删除操作${NC}"
    fi
    pause
    docker_container_management
}

# 6. Docker 镜像管理
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

# 删除指定镜像
remove_specified_image() {
    read -p "请输入要删除的镜像 ID 或名称: " image_id
    if [ -z "$image_id" ]; then
        docker_image_management
    fi
    docker rmi -f $image_id || echo -e "${RED}删除镜像失败（可能被容器引用）${NC}"
    echo -e "${GREEN}镜像 $image_id 已删除！${NC}"
    pause
    docker_image_management
}

# 删除所有镜像（增加空值处理）
remove_all_images() {
    local image_count=$(docker images -q | wc -l | awk '{print $1}')
    if [ "$image_count" -eq 0 ]; then
        echo -e "${YELLOW}没有可删除的镜像${NC}"
        pause
        docker_image_management
        return
    fi
    docker rmi -f $(docker images -q) || echo -e "${RED}部分镜像删除失败（可能被容器引用）${NC}"
    echo -e "${GREEN}所有可删除的镜像已删除！${NC}"
    pause
    docker_image_management
}

# 7. Docker 网络管理
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

# 创建 Docker 网络（增加检查）
create_network() {
    read -p "请输入要创建的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    if docker inspect "$network_name" &>/dev/null; then
        echo -e "${RED}网络 $network_name 已存在${NC}"
        docker_network_management
    fi
    docker network create $network_name || echo -e "${RED}创建网络失败${NC}"
    echo -e "${GREEN}网络 $network_name 已创建！${NC}"
    pause
    docker_network_management
}

# 加入 Docker 网络
join_network() {
    read -p "请输入要加入的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_network_management
    fi
    read -p "请输入要加入的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    docker network connect $network_name $container_id || echo -e "${RED}加入网络失败${NC}"
    echo -e "${GREEN}容器 $container_id 已加入网络 $network_name！${NC}"
    pause
    docker_network_management
}

# 退出 Docker 网络
leave_network() {
    read -p "请输入要退出的容器 ID 或名称: " container_id
    if [ -z "$container_id" ]; then
        docker_network_management
    fi
    read -p "请输入要退出的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    docker network disconnect $network_name $container_id || echo -e "${RED}退出网络失败${NC}"
    echo -e "${GREEN}容器 $container_id 已退出网络 $network_name！${NC}"
    pause
    docker_network_management
}

# 删除 Docker 网络
delete_network() {
    read -p "请输入要删除的网络名称: " network_name
    if [ -z "$network_name" ]; then
        docker_network_management
    fi
    docker network rm $network_name || echo -e "${RED}删除网络失败（可能被容器使用）${NC}"
    echo -e "${GREEN}网络 $network_name 已删除！${NC}"
    pause
    docker_network_management
}

# 8. Docker 卷管理
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

# 创建新卷（增加检查）
create_volume() {
    read -p "请输入要创建的新卷名称: " volume_name
    if [ -z "$volume_name" ]; then
        docker_volume_management
    fi
    if docker inspect "$volume_name" &>/dev/null; then
        echo -e "${RED}卷 $volume_name 已存在${NC}"
        docker_volume_management
    fi
    docker volume create $volume_name || echo -e "${RED}创建卷失败${NC}"
    echo -e "${GREEN}新卷 $volume_name 已创建！${NC}"
    pause
    docker_volume_management
}

# 删除指定卷
delete_specified_volume() {
    read -p "请输入要删除的卷名称: " volume_name
    if [ -z "$volume_name" ]; then
        docker_volume_management
    fi
    docker volume rm $volume_name || echo -e "${RED}删除卷失败（可能被容器使用）${NC}"
    echo -e "${GREEN}卷 $volume_name 已删除！${NC}"
    pause
    docker_volume_management
}

# ========== 优化4：卷删除空值处理 ==========
# 删除所有卷
delete_all_volumes() {
    local volumes=$(docker volume ls -q)
    local volume_count=$(echo "$volumes" | wc -l | awk '{print $1}')
    if [ "$volume_count" -eq 0 ]; then
        echo -e "${YELLOW}没有可删除的卷${NC}"
        pause
        docker_volume_management
        return
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

# 9. 卸载 Docker 环境的函数
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

# 停止并删除 Docker 容器和镜像（增加错误重定向）
function clean_docker_containers_images {
    echo "停止并删除所有容器和镜像..."
    sudo docker stop $(sudo docker ps -a -q) 2>/dev/null || true
    sudo docker rm $(sudo docker ps -a -q) 2>/dev/null || true
    sudo docker rmi $(sudo docker images -q) 2>/dev/null || true
}

# 卸载 Docker 对应的包（增加错误处理）
function uninstall_docker {
    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
        echo "卸载 Docker（适用于 Ubuntu/Debian）..."
        sudo apt-get purge -y docker-ce docker-ce-cli containerd.io 2>/dev/null || true
        sudo apt-get purge -y docker.io 2>/dev/null || true
    elif [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]]; then
        echo "卸载 Docker（适用于 CentOS/RHEL）..."
        sudo yum remove -y docker-ce docker-ce-cli containerd.io 2>/dev/null || true
    else
        echo "不支持的操作系统。"
        exit 1
    fi
}

# 删除 Docker 相关文件和目录（增加错误重定向）
function delete_docker_files {
    echo "删除 Docker 配置和数据文件..."
    sudo rm -rf /var/lib/docker 2>/dev/null || true
    sudo rm -rf /var/lib/containerd 2>/dev/null || true
    sudo rm -rf /etc/docker 2>/dev/null || true
    sudo rm -rf /var/run/docker 2>/dev/null || true
}

# 删除 Docker 用户和组（可选，增加错误重定向）
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

# 暂停，按任意键继续
pause() {
    # 设置绿色文本颜色
    echo -e "\033[0;32m操作完成，按任意键继续...\033[0m"
    read -n 1 -s -r
}

# 启动脚本（增加权限检查）
check_docker_permission
show_menu
