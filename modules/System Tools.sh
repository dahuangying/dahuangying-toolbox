#!/bin/bash

# 欢迎信息
echo "=============================="
echo "欢迎使用一键运维脚本"
echo "=============================="
echo "请选择你要执行的操作："

# 菜单选项
echo "1. ROOT密码登录模式管理"
echo "2. 修改登录密码"
echo "3. 查看端口占用状态"
echo "4. 开放/关闭端口"
echo "5. 文件权限管理"
echo "0. 退出"
read -p "请输入选项 (0-5): " option

# ROOT密码登录模式管理
function root_password_login() {
    echo "1. 开启 ROOT 密码登录模式"
    echo "2. 关闭 ROOT 密码登录模式"
    read -p "请选择操作 (1-2): " choice

    if [ "$choice" -eq 1 ]; then
        echo "正在开启 ROOT 密码登录模式..."
        sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        systemctl restart sshd
        echo -e "\e[32m操作完成，按任意键继续...\e[0m"
        read -n 1 -s
    elif [ "$choice" -eq 2 ]; then
        echo "正在关闭 ROOT 密码登录模式..."
        sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        systemctl restart sshd
        echo -e "\e[32m操作完成，按任意键继续...\e[0m"
        read -n 1 -s
    else
        echo "无效选项！"
    fi
}

# 修改登录密码
function change_password() {
    read -p "请输入新密码: " new_password
    echo -e "$new_password\n$new_password" | passwd root
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
}

# 查看端口占用状态
function check_ports() {
    echo "正在查看端口占用状态..."
    netstat -tuln
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
}

# 开放所有端口
function open_all_ports() {
    echo "正在开放所有端口..."
    firewall-cmd --zone=public --add-port=0-65535/tcp --permanent
    firewall-cmd --reload
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
}

# 关闭所有端口
function close_all_ports() {
    echo "正在关闭所有端口..."
    firewall-cmd --zone=public --remove-port=0-65535/tcp --permanent
    firewall-cmd --reload
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
}

# 开放指定端口
function open_specific_port() {
    read -p "请输入要开放的端口号: " port
    echo "正在开放端口 $port ..."
    firewall-cmd --zone=public --add-port=$port/tcp --permanent
    firewall-cmd --reload
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
}

# 关闭指定端口
function close_specific_port() {
    read -p "请输入要关闭的端口号: " port
    echo "正在关闭端口 $port ..."
    firewall-cmd --zone=public --remove-port=$port/tcp --permanent
    firewall-cmd --reload
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
}

# 文件权限管理
function file_permissions() {
    echo "请选择文件权限设置："
    echo "1. rwxr-xr-x (755)"
    echo "2. rw-r--r-- (644)"
    echo "3. rwx------ (700)"
    echo "4. r-xr-xr-x (555)"
    echo "5. r-------- (400)"
    echo "6. 自定义权限"
    read -p "请输入选项 (1-6): " choice

    echo "请输入文件或目录的路径："
    read filepath

    if [ ! -e "$filepath" ]; then
        echo "错误：文件或目录不存在！"
        return
    fi

    case $choice in
        1)
            chmod 755 "$filepath"
            echo "权限已设置为 rwxr-xr-x (755)"
            ;;
        2)
            chmod 644 "$filepath"
            echo "权限已设置为 rw-r--r-- (644)"
            ;;
        3)
            chmod 700 "$filepath"
            echo "权限已设置为 rwx------ (700)"
            ;;
        4)
            chmod 555 "$filepath"
            echo "权限已设置为 r-xr-xr-x (555)"
            ;;
        5)
            chmod 400 "$filepath"
            echo "权限已设置为 r-------- (400)"
            ;;
        6)
            read -p "请输入自定义权限 (如：755, 644)： " custom_permission
            chmod "$custom_permission" "$filepath"
            echo "权限已设置为自定义权限 $custom_permission"
            ;;
        *)
            echo "无效选项！"
            ;;
    esac
    echo -e "\e[32m操作完成，按任意键继续...\e[0m"
    read -n 1 -s
}

# 根据用户输入执行操作
case $option in
    1)
        root_password_login
        ;;
    2)
        change_password
        ;;
    3)
        check_ports
        ;;
    4)
        echo "请选择端口操作："
        echo "1. 开放所有端口"
        echo "2. 关闭所有端口"
        echo "3. 开放指定端口"
        echo "4. 关闭指定端口"
        read -p "请输入选项 (1-4): " port_option

        case $port_option in
            1)
                open_all_ports
                ;;
            2)
                close_all_ports
                ;;
            3)
                open_specific_port
                ;;
            4)
                close_specific_port
                ;;
            *)
                echo "无效选项！"
                ;;
        esac
        ;;
    5)
        file_permissions
        ;;
    0)
        echo "退出脚本"
        exit 0
        ;;
    *)
        echo "无效选项！"
        ;;
esac



