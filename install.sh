#!/bin/bash

# 遇到任何错误立即停止，防止误操作
set -e

# --- 确定后的配置 ---
DOWNLOAD_URL="https://github.com/Toby1GO/singbox-UI/releases/download/V1.0/SingboxUI.tar.gz"
INSTALL_DIR="/opt/singbox_ui"
SERVICE_NAME="singbox_ui"
FILENAME="SingboxUI.tar.gz"

echo ">>> [1/4] 清理并准备安装目录: $INSTALL_DIR"
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo ">>> [2/4] 正在下载资源 (使用确认链接)..."
# -L 跟随重定向, -f 遇到404报错
if ! sudo curl -L -f -sS "$DOWNLOAD_URL" -o "$FILENAME"; then
    echo "❌ 错误：下载失败！请检查 GitHub Release 是否公开，以及 V1.0 和 SingboxUI.tar.gz 是否准确。"
    exit 1
fi

# 检查文件是否为有效的压缩包
if ! file "$FILENAME" | grep -q "gzip compressed data"; then
    echo "❌ 错误：下载的文件不是有效的 gzip 格式。可能下载到了错误页面。"
    sudo rm "$FILENAME"
    exit 1
fi

echo ">>> [3/4] 正在解压并授权..."
sudo tar -xzf "$FILENAME" -C "$INSTALL_DIR"
sudo rm "$FILENAME"

# 检查主程序 box 是否存在
if [ ! -f "$INSTALL_DIR/box" ]; then
    echo "❌ 错误：未在解压后的目录中找到主程序 'box'"
    exit 1
fi

sudo chmod +x "$INSTALL_DIR/box"
# 给 sing-box 授权（如果存在）
[ -f "$INSTALL_DIR/sing-box" ] && sudo chmod +x "$INSTALL_DIR/sing-box"

echo ">>> [4/4] 配置 systemd 开机自启..."
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

echo ">>> 正在启动服务..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

echo "-----------------------------------------------"
echo "✅ 安装成功并已后台运行！"
echo "使用 'systemctl status $SERVICE_NAME' 查看状态。"
echo "-----------------------------------------------"
