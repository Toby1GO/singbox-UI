#!/bin/bash

# --- 配置区 ---
# 替换为你的 GitHub 实际信息
GITHUB_USER="Toby1GO"
REPO_NAME="singbox-ui"
# 自动获取最新版本号 (或者你可以写死，如 TAG="v1.0.0")
TAG="v1.0"

FILENAME="SingboxUI.tar.gz"
DOWNLOAD_URL="https://github.com/$GITHUB_USER/$REPO_NAME/releases/download/$TAG/$FILENAME"
INSTALL_DIR="/opt/singbox_ui"
SERVICE_NAME="singbox_ui"

echo ">>> 准备安装版本: $TAG"

# 1. 创建目录并下载
sudo mkdir -p $INSTALL_DIR
echo ">>> 正在从 Release 下载资源..."
sudo curl -L $DOWNLOAD_URL -o $INSTALL_DIR/$FILENAME

# 2. 解压并清理
echo ">>> 正在解压文件..."
sudo tar -xzf $INSTALL_DIR/$FILENAME -C $INSTALL_DIR
sudo rm $INSTALL_DIR/$FILENAME

# 3. 赋予执行权限
echo ">>> 设置程序权限..."
# 假设解压后文件名叫 box 和 sing-box
sudo chmod +x $INSTALL_DIR/box
sudo chmod +x $INSTALL_DIR/sing-box

# 4. 写入 Systemd 服务文件 (实现开机自启)
echo ">>> 正在配置开机自启动服务..."
cat <<EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=Singbox UI Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/box
Restart=on-failure
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 5. 启动服务
echo ">>> 正在加载并启动服务..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "-----------------------------------------------"
echo "安装成功！"
echo "服务状态: systemctl status $SERVICE_NAME"
echo "查看日志: journalctl -u $SERVICE_NAME -f"
echo "-----------------------------------------------"
