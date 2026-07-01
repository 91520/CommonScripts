#!/bin/bash
# Netboot.xyz TFTP一键部署脚本
NAME="tftpd"
LOCAL_TFTP_DIR="/opt/netboot-tftp"
IMG_NAME="langren1353/netboot-shell-tftp"
TFTP_SERVER_IP=$(hostname -I | awk '{print $1}')

# 1. 停止删除已存在同名容器
if docker ps -a | grep -q "$NAME";then
    echo "发现已存在$NAME容器，正在清理..."
    docker rm -f $NAME
fi

# 2. 创建本地存放目录
mkdir -p $LOCAL_TFTP_DIR

# 3. 放行UDP69防火墙端口
if command -v ufw &> /dev/null;then
    ufw allow 69/udp
    ufw reload
elif command -v firewall-cmd &> /dev/null;then
    firewall-cmd --add-port=69/udp --permanent
    firewall-cmd --reload
fi

# 4. 启动TFTP容器 挂载本地目录到容器/data
docker run -itd \
--name $NAME \
-p 69:69/udp \
-v $LOCAL_TFTP_DIR:/data \
--restart unless-stopped \
$IMG_NAME

# 5. 自动下载主流netboot引导文件到TFTP目录
cd $LOCAL_TFTP_DIR
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz.efi
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz-arm64.efi
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz.kpxe

# 6. 授权权限避免读取失败
chmod 755 *

echo "======================================"
echo "✅ Netboot TFTP服务搭建完成"
echo "📌 服务IP: $TFTP_SERVER_IP"
echo "📂 本地文件目录: $LOCAL_TFTP_DIR"
echo "🔹 可用引导文件:"
ls $LOCAL_TFTP_DIR
echo "======================================"
echo "设备启动调用命令示例:"
echo "tftp $TFTP_SERVER_IP get netboot.xyz.efi"
echo "tftp $TFTP_SERVER_IP get netboot.xyz-arm64.efi"
