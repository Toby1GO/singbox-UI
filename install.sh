#!/bin/bash

# 遇到任何错误立即停止执行
set -e

# --- 配置区 ---
GITHUB_USER="Toby1GO"
REPO_NAME="singbox-UI"
INSTALL_DIR="/opt/singbox_ui"
SERVICE_NAME="singbox_ui"
FILENAME="SingboxUI.tar.gz"

# 1. 自动获取最新 Tag
echo ">>> 正在获取远程版本信息..."
TAG=$(curl -s "https://api.github.com/repos/$GITHUB_USER/$REPO_NAME/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$TAG" ]; then
    echo "❌ 错误：无法获取最新版本号，请检查仓库名和网络。"
    exit 1
fi

DOWNLOAD_URL="https://github.com/$GITHUB_USER/$REPO_NAME/releases/download/$TAG/$FILENAME"

# 2. 准备安装目录
echo ">>> 准备安装目录: $INSTALL_DIR"
sudo mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 3. 安全下载
echo ">>> 正在从 Release 下载: $FILENAME (版本: $TAG)"
# -L 跟随重定向, -f 如果 404 则返回错误码
if ! sudo curl -L -f "$DOWNLOAD_URL" -o "$FILENAME"; then
    echo "❌ 错误：文件下载失败！请检查 Release 中是否有 $FILENAME"
    exit 1
fi

# 4. 校验文件格式 (防止下载到 HTML 报错页面)
if ! file "$FILENAME" | grep -q "gzip compressed data"; then
    echo "❌ 错误：下载的文件损坏或格式不正确（非 gzip 压缩包）。"
    echo "可能是下载到了 GitHub 的报错页面，请检查下载链接。"
    sudo rm "$FILENAME"
    exit 1
fi

# 5. 解压
echo ">>> 正在解压..."
if ! sudo tar -xzf "$FILENAME" -C "$INSTALL_DIR"; then
    echo "❌ 错误：解压失败。"
    exit 1
fi
sudo rm "$FILENAME"

# 6. 核心文件存在性检查
echo ">>> 检查程序文件..."
if [ ! -f "$INSTALL_DIR/box" ]; then
    echo "❌ 错误：解压后的目录中未找到主程序 'box'"
    exit 1
fi

# 7. 授权
sudo chmod +x "$INSTALL_DIR/box"
[ -f "$INSTALL_DIR/sing-box" ] && sudo chmod +x "$INSTALL_DIR/sing-box"

# 8. 写入并配置 Systemd 服务
echo ">>> 配置系统服务..."
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

# 9. 最终启动
echo ">>> 启动服务并设置自启动..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

echo "✅ 安装成功！"
echo "使用 'systemctl status $SERVICE_NAME' 查看运行状态。"
