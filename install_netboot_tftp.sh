#!/bin/bash
# Netboot.xyz TFTP一键部署脚本 修复版
NAME="tftpd"
LOCAL_TFTP_DIR="/opt/netboot-tftp"
IMG_NAME="langren1353/netboot-shell-tftp"
TFTP_SERVER_IP=$(hostname -I | awk '{print $1}')

# 1. 清理同名旧容器
if docker ps -a | grep -q "$NAME";then
    echo "【清理】发现同名容器，强制删除..."
    docker rm -f $NAME
fi

# 2. 创建目录并全开权限
mkdir -p $LOCAL_TFTP_DIR
chmod 777 $LOCAL_TFTP_DIR
chown nobody:nogroup $LOCAL_TFTP_DIR

# 3. 放行UDP69端口
if command -v ufw &> /dev/null;then
    ufw allow 69/udp
    ufw reload
elif command -v firewall-cmd &> /dev/null;then
    firewall-cmd --add-port=69/udp --permanent
    firewall-cmd --reload
fi

# 4. 启动容器 挂载目录+适配tftp运行用户
docker run -itd \
--name $NAME \
-p 69:69/udp \
-v $LOCAL_TFTP_DIR:/data \
--user root \
--restart unless-stopped \
$IMG_NAME

# 5. 下载引导文件并修正权限
cd $LOCAL_TFTP_DIR
echo "【下载】获取netboot引导文件..."
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz.efi
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz-arm64.efi
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz.kpxe

# 全局可读可访问
chmod 644 ./*
chown nobody:nogroup ./*

echo -e "\n======================================"
echo "✅ Netboot TFTP 部署完成"
echo "🌐 服务器IP：$TFTP_SERVER_IP"
echo "📁 本地文件目录：$LOCAL_TFTP_DIR"
echo "📄 已就绪文件："
ls $LOCAL_TFTP_DIR
echo "======================================"
echo "交换机Shell下载命令："
echo "tftp $TFTP_SERVER_IP netboot.xyz.efi"
echo "tftp $TFTP_SERVER_IP netboot.xyz-arm64.efi"
echo "======================================"
echo "⚠️ 云服务器务必在后台安全组放行：UDP 69端口"
