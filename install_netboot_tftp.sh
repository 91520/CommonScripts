#!/bin/bash
# Netboot.xyz TFTP一键部署脚本 最终稳定版
NAME="tftpd"
LOCAL_TFTP_DIR="/opt/netboot-tftp"
IMG_NAME="langren1353/netboot-shell-tftp"
TFTP_SERVER_IP=$(hostname -I | awk '{print $1}')

# 清理同名旧容器
docker rm -f $NAME 2>/dev/null
echo "【清理】旧容器已移除"

# 创建目录并赋予最高权限
mkdir -p $LOCAL_TFTP_DIR
chmod 777 $LOCAL_TFTP_DIR

# 清理历史冗余文件
rm -rf $LOCAL_TFTP_DIR/*.1 $LOCAL_TFTP_DIR/*.2

# 放行防火墙UDP69
if command -v ufw &> /dev/null;then
    ufw allow 69/udp
    ufw reload
fi
if command -v firewall-cmd &> /dev/null;then
    firewall-cmd --add-port=69/udp --permanent 2>/dev/null
    firewall-cmd --reload 2>/dev/null
fi

# 启动TFTP容器 root权限运行
docker run -itd \
--name $NAME \
-p 69:69/udp \
-v $LOCAL_TFTP_DIR:/data \
--user root \
--restart unless-stopped \
$IMG_NAME

# 下载纯净引导文件
cd $LOCAL_TFTP_DIR
echo "【下载】引导文件中..."
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz.efi
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz-arm64.efi
wget -q https://boot.netboot.xyz/ipxe/netboot.xyz.kpxe

# 统一权限
chmod 644 $LOCAL_TFTP_DIR/*

echo -e "\n======================================"
echo "✅ Netboot TFTP 部署完成"
echo "🌐 内网IP：$TFTP_SERVER_IP"
echo "🌐 公网IP：129.146.28.242"
echo "📁 文件目录：$LOCAL_TFTP_DIR"
echo "📄 已就绪文件："
ls $LOCAL_TFTP_DIR
echo "======================================"
echo "交换机正确下载命令（无get）："
echo "tftp 129.146.28.242 netboot.xyz.efi"
echo "tftp 129.146.28.242 netboot.xyz-arm64.efi"
echo "======================================"
echo "⚠️ 务必云平台安全组放行 UDP 69 端口"
