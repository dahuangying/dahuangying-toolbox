#!/bin/bash

# =======================================
# 1Panel 新一代管理面板 安装脚本
# =======================================

# 设置一些变量
PANEL_VERSION="v1.10.29-lts-linux-amd64"
INSTALL_DIR="/opt/1panel"
INSTALL_TAR="/root/1panel-${PANEL_VERSION}.tar.gz"
INSTALL_URL="https://github.com/kejilion/sh/releases/download/${PANEL_VERSION}/1panel-${PANEL_VERSION}.tar.gz"

# 更新系统
echo "更新系统..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 安装必要的依赖
echo "安装依赖..."
sudo apt-get install -y curl wget tar unzip systemd

# 下载 1Panel 安装包
echo "下载 1Panel 安装包..."
wget -q ${INSTALL_URL} -O ${INSTALL_TAR}

# 解压安装包
echo "解压安装包..."
sudo mkdir -p ${INSTALL_DIR}
sudo tar -zxvf ${INSTALL_TAR} -C ${INSTALL_DIR}

# 删除安装包
rm -f ${INSTALL_TAR}

# 创建系统服务文件
echo "创建 1Panel 服务文件..."
SERVICE_FILE="/etc/systemd/system/1panel.service"
sudo tee ${SERVICE_FILE} > /dev/null <<EOF
[Unit]
Description=1Panel Service
After=network.target

[Service]
Type=simple
ExecStart=${INSTALL_DIR}/1panel
WorkingDirectory=${INSTALL_DIR}
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# 重载 systemd 配置并启动服务
echo "重载 systemd 并启动服务..."
sudo systemctl daemon-reload
sudo systemctl enable 1panel
sudo systemctl start 1panel

# 安装完成提示
echo "1Panel 安装完成！"
echo "------------------------------------------------"
echo "1Panel 服务已启动，访问地址：http://<你的服务器IP>:8888"
echo "默认用户名：admin"
echo "默认密码：123456"
echo "------------------------------------------------"
echo "安装日志可以查看: ${INSTALL_DIR}/install.log"








