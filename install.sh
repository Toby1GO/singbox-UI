#!/bin/bash

# 只要任何一行命令出错，立即终止脚本
set -e

# --- 配置区 ---
GITHUB_USER="Toby1G0"
REPO_NAME="singbox-UI"
# 你的 Release Tag 是 V1.0 (注意大小写要一致)
TAG="V1.0"
FILENAME="SingboxUI.tar.gz"
DOWNLOAD_URL="https://github.com/$GITHUB_USER/$REPO_NAME/releases/download/$TAG/$FILENAME"

INSTALL_DIR="/opt/singbox_ui"
SERVICE_NAME="singbox_ui"

echo ">>> [1/6] 准备安装目录: $INSTALL_DIR"
sudo mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 2. 增强型下载
echo ">>> [2/6] 正在下载资源: $FILENAME..."
# -L 跟随重定向, -f 遇到404报错, -sS 静默但显示错误
if ! sudo curl -L -f -sS "$DOWNLOAD_URL" -o "$FILENAME"; then
    echo "❌ 错误：下载失败！请确认 Release 中是否存在 $FILENAME"
    exit 1
fi

# 3. 校验文件格式 (核心检测)
if ! file "$FILENAME" | grep -q "gzip compressed data"; then
    echo "❌ 错误：下载的文件不是有效的压缩包。"
    echo "这通常是因为链接被拦截或重定向失败，请检查网络。"
    sudo rm "$FILENAME"
    exit 1
fi

# 4. 解压并检查内容
echo ">>> [3/6] 正在解压并清理..."
sudo tar -xzf "$FILENAME" -C "$INSTALL_DIR"
sudo rm "$FILENAME"

# 检查解压后主程序是否存在
if [ ! -f "$INSTALL_DIR/box" ]; then
    echo "❌ 错误：解压成功但未在 $INSTALL_DIR 中找到 'box' 文件。"
    exit 1
fi

# 5. 权限设置
echo ">>> [4/6] 设置执行权限..."
sudo chmod +x "$INSTALL_DIR/box"
# 尝试给已解压出的 sing-box 授权（如果存在）
if [ -f "$INSTALL_DIR/sing-box" ]; then
    sudo chmod +x "$INSTALL_DIR/sing-box"
fi

# 6. 配置 Systemd 开机自启
echo ">>> [5/6] 写入系统服务配置..."
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

# 7. 启动并运行
echo ">>> [6/6] 启动服务并设置自启动..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

echo "-----------------------------------------------"
echo "✅ 安装成功并已挂在后台运行！"
echo "查看运行状态: systemctl status $SERVICE_NAME"
echo "查看程序日志: journalctl -u $SERVICE_NAME -f"
echo "-----------------------------------------------"
