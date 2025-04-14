#!/bin/bash

# 设置颜色
GREEN='\033[0;32m'
NC='\033[0m' # 无色

# 显示主菜单
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
             bash <(curl -fsSL https://github.com/dahuangying/dahuangying-toolbox/blob/main/modules/system.sh)
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

# 循环显示菜单
while true; do
    show_menu
done
