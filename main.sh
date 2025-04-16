#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
NC='\033[0m' # 无色

# GitHub 用户名和仓库名（你可以修改为自己的）
GITHUB_USER="dahuangying"
REPO_NAME="dahuangying-toolbox"
BRANCH="main"

# 下载模块
download_module() {
    mkdir -p modules
    if [ ! -f modules/$1 ]; then
        echo -e "${GREEN}正在下载模块: $1${NC}"
        curl -fsSL https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${BRANCH}/modules/$1 -o modules/$1
        chmod +x modules/$1
    fi
}

# 下载所有模块
download_all_modules() {
    download_module system.sh
    download_module network.sh
    download_module docker.sh
    download_module web.sh
    download_module tools.sh
}

# 主菜单
show_menu() {
    echo -e "${GREEN}欢迎使用大黄鹰工具箱${NC}"
    echo "1. 系统管理"
    echo "2. 网络优化"
    echo "3. Docker 管理"
    echo "4. 建站工具"
    echo "5. 系统工具"
    echo "0. 退出"
    read -p "请输入选项编号: " choice
    case $choice in
        1)
            bash modules/system.sh
            ;;
        2)
            bash modules/network.sh
            ;;
        3)
            bash modules/docker.sh
            ;;
        4)
            bash modules/web.sh
            ;;
        5)
            bash modules/tools.sh
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
download_all_modules
while true; do
    show_menu
done

