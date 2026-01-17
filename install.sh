#!/bin/bash

# 定义安装路径
INSTALL_DIR="/opt/singbox"
SERVICE_NAME="singbox"

echo "开始安装..."

# 1. 创建目标目录并拷贝文件
sudo mkdir -p $INSTALL_DIR
sudo cp -r ./* $INSTALL_DIR/

# 2. 给程序赋予执行权限
sudo chmod +x $INSTALL_DIR/sing-box
sudo chmod +x $INSTALL_DIR/box

# 3. 创建 systemd 服务文件，实现开机自启
# 这里假设你想运行 program1，如果是运行多个，可以在脚本里写个启动脚本
cat <<EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=My Linux Project Service
After=network.target

[Service]
ExecStart=$INSTALL_DIR/program1
WorkingDirectory=$INSTALL_DIR
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

# 4. 重新加载配置并启动服务
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "安装完成！服务已启动并设置为开机自启。"
