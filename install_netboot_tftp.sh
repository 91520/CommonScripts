#!/bin/bash
# Netboot.xyz TFTP 终极修复脚本
NAME="tftpd"
LOCAL_TFTP_DIR="/opt/netboot-tftp"
IMG_NAME="langren1353/netboot-shell-tftp"
TFTP_SERVER_IP=$(hostname -I | awk '{print $1}')

# 清理旧容器
docker rm -f $NAME 2>/dev/null

# 创建目录+最高权限
mkdir -p $LOCAL_TFTP_DIR
chmod 777 $LOCAL_TFTP_DIR

# 放行防火墙
ufw allow 69/udp
ufw reload
firewall-cmd --add-port=69/udp --permanent 2>/dev/null
firewall-cmd --reload 2>/dev/null

# 启动容器 强制root运行 彻底放开限制
docker run -itd \
--name $NAME \
-p 69:69/udp \
-v $LOCAL_TFTP_DIR:/data \
--user root \
--restart unless-stopped \
$IMG_NAME

# 下载文件 并重命名【去掉多余点 规避tftp文件名拦截】
cd $LOCAL_TFTP_DIR
rm -f *.efi *.kpxe
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz.efi -O bootx64.efi
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz-arm64.efi -O bootarm64.efi
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz.kpxe -O boot.kpxe

# 全局权限全开
chmod 755 $LOCAL_TFTP_DIR
chmod 644 $LOCAL_TFTP_DIR/*

echo "======================================"
echo "✅ 部署完成 简化文件名规避报错"
echo "服务器IP: $TFTP_SERVER_IP"
echo "可用下载命令（直接用这个）"
echo "tftp $TFTP_SERVER_IP bootx64.efi"
echo "tftp $TFTP_SERVER_IP bootarm64.efi"
echo "======================================"
