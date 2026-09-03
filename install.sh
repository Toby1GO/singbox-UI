#!/bin/bash
set -e

DOWNLOAD_URL="https://github.com/Toby1GO/singbox-UI/releases/download/V1.0/singbox"
INSTALL_DIR="/opt/singbox_ui"
SERVICE_NAME="singbox_ui"
BIN_NAME="box"

echo ">>> 准备目录"
sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo ">>> 下载二进制程序"
sudo curl -L -f -sS "$DOWNLOAD_URL" -o "$BIN_NAME"
sudo chmod +x "$INSTALL_DIR/$BIN_NAME"

echo ">>> 写入systemd"
cat <<EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=Singbox UI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$BIN_NAME
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

sleep 2
if [[ $(systemctl is-active "$SERVICE_NAME") == "active" ]];then
echo "✅ 部署完成！"
echo "状态：systemctl status $SERVICE_NAME"
else
echo "⚠️ 程序启动失败，请检查"
fi
