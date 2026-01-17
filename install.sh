#!/bin/bash

# 开启严格模式：任何命令失败即刻退出
set -e

# --- 核心配置 (已根据你的截图校对) ---
GITHUB_USER="Toby1G0"
REPO_NAME="singbox-UI"
# 如果你的 Tag 确实是大写 V，这里必须是大写
TAG="V1.0" 
FILENAME="SingboxUI.tar.gz"
INSTALL_DIR="/opt/singbox_ui"
SERVICE_NAME="singbox_ui"

# 下载地址
DOWNLOAD_URL="https://github.com/$GITHUB_USER/$REPO_NAME/releases/download/$TAG/$FILENAME"

echo ">>> [1/5] 清理并准备安装目录..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo ">>> [2/5] 正在下载资源 (版本: $TAG)..."
# -L 跟随重定向, -f 遇到404直接报错退出
if ! sudo curl -L -f -sS "$DOWNLOAD_URL" -o "$FILENAME"; then
    echo "❌ 错误：下载失败！请检查以下两点："
    echo "1. Release 中的文件名是否精确为 $FILENAME"
    echo "2. 版本号是否精确为 $TAG (注意大写 V)"
    exit 1
fi

# 检查文件是否为有效的压缩包
if ! file "$FILENAME" | grep -q "gzip compressed data"; then
    echo "❌ 错误：下载的文件损坏，不是有效的 gzip 格式。"
    sudo rm "$FILENAME"
    exit 1
fi

echo ">>> [3/5] 正在解压并授权..."
sudo tar -xzf "$FILENAME" -C "$INSTALL_DIR"
sudo rm "$FILENAME"

# 检查主程序是否存在
if [ ! -f "$INSTALL_DIR/box" ]; then
    echo "❌ 错误：在解压目录中未找到主程序 'box'"
    exit 1
fi

sudo chmod +x "$INSTALL_DIR/box"
# 额外尝试给 sing-box 授权（如果存在）
[ -f "$INSTALL_DIR/sing-box" ] && sudo chmod +x "$INSTALL_DIR/sing-box"

echo ">>> [4/5] 配置 systemd 开机自启..."
cat <<EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=Singbox UI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/box
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo ">>> [5/5] 启动服务..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

echo "✅ 安装成功！"
echo "服务状态：systemctl status $SERVICE_NAME"
