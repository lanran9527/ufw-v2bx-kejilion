#!/bin/bash

# 配置
domain=""     # 你的域名，例：example.com
email=""      # 你的邮箱，用于 Let's Encrypt（可选）
acme_dir="/root/.acme.sh" # acme.sh 安装目录

# 检查/root/.acme.sh是否存在，若无则安装
if [ ! -d "$acme_dir" ]; then
  curl https://get.acme.sh | sh
  source ~/.bashrc
fi

# 添加acme.sh到路径
export PATH="$acme_dir":$PATH

# 检查输入
read -p "请输入你的域名: " domain
read -p "请输入你的邮箱（可选，直接回车跳过）: " email

# 检查80端口
if lsof -i:80 | grep -q LISTEN; then
  echo "检测到 80 端口被占用，尝试释放..."
  systemctl stop nginx || systemctl stop apache2 || echo "没有检测到常见的 Web 服务"
fi

# 申请证书
if [ -z "$email" ]; then
  $acme_dir/acme.sh --issue -d $domain --standalone
else
  $acme_dir/acme.sh --issue -d $domain --standalone -m $email
fi

# 安装证书到指定目录
mkdir -p /etc/ssl/$domain
$acme_dir/acme.sh --install-cert -d $domain \
  --key-file /etc/ssl/$domain/private.key \
  --fullchain-file /etc/ssl/$domain/fullchain.crt \
  --reloadcmd "systemctl reload nginx || systemctl reload xray || systemctl reload v2ray"

echo "证书已安装到 /etc/ssl/$domain/，如需修改reload命令请自行调整"
echo "证书申请完毕，如有防火墙请开放 80/443 端口"