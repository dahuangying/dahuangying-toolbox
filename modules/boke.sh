#!/bin/bash

# 设置绿色文本的颜色
GREEN='\033[0;32m'
NC='\033[0m' # 默认颜色

# 安装和配置 Halo 和 WordPress 的基本路径和变量
HALO_DIR="/opt/halo"
WORDPRESS_DIR="/opt/wordpress"
HALO_DB_NAME="halo_db"
WORDPRESS_DB_NAME="wordpress_db"
HALO_DB_USER="halo_user"
WORDPRESS_DB_USER="wordpress_user"

# 检查安装状态
check_status() {
    clear
    echo -e "${GREEN}========================================${NC}"
    if [ -d "$HALO_DIR" ]; then
        echo "Halo 安装状态: 已安装"
    else
        echo "Halo 安装状态: 未安装"
    fi

    if [ -d "$WORDPRESS_DIR" ]; then
        echo "WordPress 安装状态: 已安装"
    else
        echo "WordPress 安装状态: 未安装"
    fi
    echo -e "${GREEN}========================================${NC}"
    echo "大黄鹰-Linux服务器运维工具箱菜单-博客"
    echo "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}========================================${NC}"
}

# 安装依赖项（Java、MySQL）
install_dependencies() {
    echo "正在安装必要的依赖项..."
    sudo apt update

    # 安装 Java（如果没有安装）
    if ! java -version &>/dev/null; then
        echo "Java 未安装，正在安装 OpenJDK 11..."
        sudo apt install -y openjdk-11-jdk
    else
        echo "Java 已安装：$(java -version)"
    fi

    # 安装 MySQL（如果没有安装）
    if ! mysql --version &>/dev/null; then
        echo "MySQL 未安装，正在安装 MySQL..."
        sudo apt install -y mysql-server
        sudo systemctl start mysql
        sudo systemctl enable mysql
    else
        echo "MySQL 已安装：$(mysql --version)"
    fi
}

# 创建数据库和用户
create_database() {
    echo "创建数据库和用户之前，请提供以下信息："

    # 用户输入数据库名称和密码
    read -p "请输入 Halo 数据库名称（默认 halo_db）： " db_name
    db_name=${db_name:-halo_db}

    read -p "请输入 Halo 数据库用户名（默认 halo_user）： " db_user
    db_user=${db_user:-halo_user}

    read -sp "请输入 Halo 数据库密码（默认 password）： " db_password
    echo
    db_password=${db_password:-password}

    # 创建数据库和用户
    echo "正在创建数据库和用户..."
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS $db_name;"
    sudo mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_password';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"

    # 更新数据库信息
    HALO_DB_NAME=$db_name
    HALO_DB_USER=$db_user
    HALO_DB_PASS=$db_password
}

# 安装 Halo
install_halo() {
    echo "开始安装 Halo..."
    if [ -d "$HALO_DIR" ]; then
        echo "Halo 已经安装在 $HALO_DIR，跳过安装步骤."
    else
        echo "正在下载并安装 Halo..."
        git clone https://github.com/halo-dev/halo.git "$HALO_DIR"
        cd "$HALO_DIR"
        echo "正在构建 Halo 项目..."
        ./mvnw clean install -DskipTests
        echo "Halo 安装完成，配置服务..."
    fi
}

# 安装 WordPress
install_wordpress() {
    echo "开始安装 WordPress..."
    if [ -d "$WORDPRESS_DIR" ]; then
        echo "WordPress 已经安装在 $WORDPRESS_DIR，跳过安装步骤."
    else
        echo "正在下载并安装 WordPress..."
        git clone https://github.com/WordPress/WordPress.git "$WORDPRESS_DIR"
        cd "$WORDPRESS_DIR"
        sudo apt install -y php php-mysql
        sudo apt install -y apache2
        sudo systemctl enable apache2
        sudo systemctl start apache2
        cp wp-config-sample.php wp-config.php
        echo "WordPress 安装完成，配置数据库等."
    fi
}

# 更新 Halo
update_halo() {
    echo "正在更新 Halo..."
    cd "$HALO_DIR" || { echo "Halo 没有安装."; return; }
    git pull origin main
    echo "Halo 更新完成."
}

# 更新 WordPress
update_wordpress() {
    echo "正在更新 WordPress..."
    cd "$WORDPRESS_DIR" || { echo "WordPress 没有安装."; return; }
    git pull origin main
    echo "WordPress 更新完成."
}

# 卸载 Halo
uninstall_halo() {
    read -p "你确定要卸载 Halo 吗？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "正在卸载 Halo..."
        rm -rf "$HALO_DIR"
        echo "Halo 卸载完成，正在清理残余文件..."

        # 清理数据库
        read -p "你是否需要删除 Halo 的数据库？(y/n): " delete_db
        if [[ $delete_db == [yY] ]]; then
            sudo mysql -e "DROP DATABASE IF EXISTS $HALO_DB_NAME;"
            sudo mysql -e "DROP USER IF EXISTS '$HALO_DB_USER'@'localhost';"
            echo "Halo 数据库和用户已删除."
        fi

        echo "残余文件已彻底清除."
    else
        echo "取消卸载 Halo."
    fi
}

# 卸载 WordPress
uninstall_wordpress() {
    read -p "你确定要卸载 WordPress 吗？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "正在卸载 WordPress..."
        rm -rf "$WORDPRESS_DIR"
        echo "WordPress 卸载完成，正在清理残余文件..."

        # 清理数据库
        read -p "你是否需要删除 WordPress 的数据库？(y/n): " delete_db
        if [[ $delete_db == [yY] ]]; then
            sudo mysql -e "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME;"
            sudo mysql -e "DROP USER IF EXISTS '$WORDPRESS_DB_USER'@'localhost';"
            echo "WordPress 数据库和用户已删除."
        fi

        echo "残余文件已彻底清除."
    else
        echo "取消卸载 WordPress."
    fi
}

# 操作完成后按任意键继续
press_any_key_to_continue() {
    read -n 1 -s -r -p $'操作完成，按任意键继续...\n'
}

# 主菜单
main_menu() {
    check_status
    echo "1. 安装 Halo"
    echo "2. 更新 Halo"
    echo "3. 卸载 Halo"
    echo -e "${GREEN}==============${NC}"
    echo "4. 安装 WordPress"
    echo "5. 更新 WordPress"
    echo "6. 卸载 WordPress"
    echo "0. 退出"
    echo -e "${GREEN}==============${NC}"
    read -p "请选择操作: " choice

    case $choice in
        1) install_dependencies; create_database; install_halo; press_any_key_to_continue ;;
        2) update_halo; press_any_key_to_continue ;;
        3) uninstall_halo; press_any_key_to_continue ;;
        4) install_wordpress; press_any_key_to_continue ;;
        5) update_wordpress; press_any_key_to_continue ;;
        6) uninstall_wordpress; press_any_key_to_continue ;;
        0) exit 0 ;;
        *) echo "无效选项，请重新选择." ; press_any_key_to_continue ; main_menu ;;
    esac
}

# 调用主菜单
main_menu






