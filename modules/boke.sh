#!/bin/bash

# 设置绿色文本的颜色
GREEN='\033[0;32m'
NC='\033[0m' # 默认颜色

# 设置目录路径
HALO_DIR="/opt/halo"
WORDPRESS_DIR="/opt/wordpress"

# 检查 Docker 和 Docker Compose 是否安装
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "Docker 未安装，请先安装 Docker。"
        exit 1
    fi
    if ! command -v docker-compose &>/dev/null; then
        echo "Docker Compose 未安装，请先安装 Docker Compose。"
        exit 1
    fi
}

# 创建 Dockerfile 用于 Halo
create_halo_dockerfile() {
    echo "正在创建 Halo Dockerfile..."

    cat <<EOF > "$HALO_DIR/Dockerfile"
# 使用 OpenJDK 作为基础镜像
FROM openjdk:11-jre-slim

# 设置工作目录
WORKDIR /app

# 克隆 Halo 源代码
RUN apt-get update && apt-get install -y git && \
    git clone https://github.com/halo-dev/halo.git && \
    cd halo && \
    ./mvnw clean install -DskipTests

# 暴露 Halo 的端口
EXPOSE 8080

# 设置启动命令
CMD ["java", "-jar", "halo/target/halo.jar"]
EOF
    echo "Halo Dockerfile 创建完成."
}

# 创建 Docker Compose 配置文件
create_docker_compose() {
    echo "正在创建 Docker Compose 配置文件..."

    cat <<EOF > "docker-compose.yml"
version: '3.7'

services:
  halo:
    build: $HALO_DIR
    container_name: halo
    ports:
      - "8080:8080"
    restart: always
    environment:
      JAVA_OPTS: "-Xms256m -Xmx1024m"

  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - "8081:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: example
    volumes:
      - wordpress_data:/var/www/html

  db:
    image: mysql:5.7
    container_name: db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: wordpress
    volumes:
      - db_data:/var/lib/mysql

volumes:
  wordpress_data:
  db_data:
EOF
    echo "Docker Compose 配置文件创建完成."
}

# 启动 Docker Compose 服务
start_docker_services() {
    echo "正在启动 Docker 服务..."

    docker-compose up -d
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}服务启动成功! Halo: http://localhost:8080, WordPress: http://localhost:8081${NC}"
    else
        echo "服务启动失败，请查看日志."
        exit 1
    fi
}

# 查看 Docker 容器状态
check_docker_status() {
    echo "正在查看 Docker 容器状态..."
    docker ps
}

# 停止并清除容器
stop_and_cleanup() {
    echo "停止并清理容器..."
    docker-compose down -v
    echo "容器已停止并清除所有数据卷."
}

# 主菜单
main_menu() {
    clear
    echo -e "${GREEN}========================================${NC}"
    echo "大黄鹰-Linux服务器运维工具箱菜单-Docker版"
    echo "欢迎使用本脚本，请根据菜单选择操作："
    echo -e "${GREEN}========================================${NC}"

    echo "1. 部署 Halo 和 WordPress"
    echo "2. 查看 Docker 容器状态"
    echo "3. 停止并清理 Docker 容器"
    echo "0. 退出"
    echo -e "${GREEN}========================================${NC}"

    read -p "请选择操作: " choice

    case $choice in
        1) check_docker; create_halo_dockerfile; create_docker_compose; start_docker_services ;;
        2) check_docker_status ;;
        3) stop_and_cleanup ;;
        0) exit 0 ;;
        *) echo "无效选项，请重新选择." ; main_menu ;;
    esac
}

# 调用主菜单
main_menu







