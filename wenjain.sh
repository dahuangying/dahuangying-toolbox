#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 安全确认函数
confirm_action() {
    local action=$1
    local target=$2
    echo -e "${RED}警告：即将执行 ${action} 操作目标：${YELLOW}${target}${NC}"
    read -p "确认执行？(y/n): " choice
    [[ "$choice" =~ ^[Yy]$ ]] && return 0 || return 1
}

# 1. 创建目录
create_directory() {
    read -p "输入要创建的目录路径: " dirpath
    if [ -z "$dirpath" ]; then
        echo -e "${RED}路径不能为空！${NC}"
        return
    fi
    
    if confirm_action "创建目录" "$dirpath"; then
        if mkdir -p "$dirpath"; then
            echo -e "${GREEN}目录创建成功！${NC}"
            recommend_permissions "$dirpath" "directory"
        else
            echo -e "${RED}创建失败，请检查权限！${NC}"
        fi
    else
        echo -e "${YELLOW}已取消操作${NC}"
    fi
    wait_key
}

# 2. 创建文件
create_file() {
    read -p "输入要创建的文件路径: " filepath
    if [ -z "$filepath" ]; then
        echo -e "${RED}路径不能为空！${NC}"
        return
    fi
    
    if confirm_action "创建文件" "$filepath"; then
        if touch "$filepath"; then
            echo -e "${GREEN}文件创建成功！${NC}"
            recommend_permissions "$filepath" "file"
        else
            echo -e "${RED}创建失败，请检查权限！${NC}"
        fi
    else
        echo -e "${YELLOW}已取消操作${NC}"
    fi
    wait_key
}

# 3. 删除目录/文件
delete_target() {
    read -p "输入要删除的路径: " target
    if [ -z "$target" ]; then
        echo -e "${RED}路径不能为空！${NC}"
        return
    fi
    
    if [ ! -e "$target" ]; then
        echo -e "${RED}目标不存在！${NC}"
        return
    fi
    
    if confirm_action "删除" "$target"; then
        if [ -d "$target" ]; then
            rm -r "$target" && echo -e "${GREEN}目录删除成功！${NC}" || echo -e "${RED}删除失败！${NC}"
        else
            rm "$target" && echo -e "${GREEN}文件删除成功！${NC}" || echo -e "${RED}删除失败！${NC}"
        fi
    else
        echo -e "${YELLOW}已取消操作${NC}"
    fi
    wait_key
}

# 4. 编辑文件
edit_file() {
    read -p "输入要编辑的文件路径: " filepath
    if [ -z "$filepath" ]; then
        echo -e "${RED}路径不能为空！${NC}"
        return
    fi
    
    if [ ! -f "$filepath" ]; then
        echo -e "${RED}文件不存在或不是普通文件！${NC}"
        return
    fi
    
    if [ ! -w "$filepath" ]; then
        echo -e "${RED}无写权限，尝试获取权限...${NC}"
        if ! sudo chmod u+w "$filepath"; then
            echo -e "${RED}无法获取写权限！${NC}"
            return
        fi
    fi
    
    # 检测可用编辑器
    editor=${EDITOR:-nano}
    command -v $editor >/dev/null || editor="vi"
    
    $editor "$filepath"
    echo -e "${GREEN}编辑完成！${NC}"
    wait_key
}

# 5. 查找文件/目录
search_files() {
    read -p "输入查找路径（默认当前目录）: " searchpath
    read -p "输入查找名称（支持通配符）: " pattern
    
    searchpath=${searchpath:-.}
    
    if [ -z "$pattern" ]; then
        echo -e "${RED}搜索模式不能为空！${NC}"
        return
    fi
    
    echo -e "${BLUE}搜索结果：${NC}"
    find "$searchpath" -name "$pattern" -print | while read result; do
        if [ -d "$result" ]; then
            echo -e "${GREEN}[目录] ${result}${NC}"
        else
            echo -e "${YELLOW}[文件] ${result}${NC}"
        fi
    done
    
    wait_key
}

# 权限建议函数
recommend_permissions() {
    local target=$1
    local type=$2
    
    echo -e "\n${BLUE}权限建议：${NC}"
    case $type in
        "directory")
            echo -e "• 普通目录： ${GREEN}755 (drwxr-xr-x)${NC}"
            echo -e "• 敏感目录： ${GREEN}700 (drwx------)${NC}"
            echo -e "当前权限： $(stat -c "%a %A" "$target")"
            ;;
        "file")
            echo -e "• 配置文件： ${GREEN}644 (-rw-r--r--)${NC}"
            echo -e "• 可执行文件： ${GREEN}755 (-rwxr-xr-x)${NC}"
            echo -e "• 敏感文件： ${GREEN}600 (-rw-------)${NC}"
            echo -e "当前权限： $(stat -c "%a %A" "$target")"
            ;;
    esac
}

# 等待按键
wait_key() {
    echo -e "\n${GREEN}按任意键继续...${NC}"
    read -n 1 -s -r
}

# 主菜单
show_menu() {
    clear
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}     文件/目录管理工具箱       ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo -e "1. 创建目录"
    echo -e "2. 创建文件"
    echo -e "3. 删除目录/文件"
    echo -e "4. 编辑文件"
    echo -e "5. 查找文件/目录"
    echo -e "${GREEN}--------------------------------${NC}"
    echo -e "0. 退出"
    echo -e "${GREEN}================================${NC}"
    echo -n "请输入选项: "
}

# 主循环
while true; do
    show_menu
    read choice
    case $choice in
        1) create_directory ;;
        2) create_file ;;
        3) delete_target ;;
        4) edit_file ;;
        5) search_files ;;
        0) echo -e "${GREEN}已退出脚本${NC}"; exit 0 ;;
        *) echo -e "${RED}无效选项！${NC}"; sleep 1 ;;
    esac
done
