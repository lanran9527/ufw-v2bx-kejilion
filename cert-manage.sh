#!/bin/bash

acme_dir="/root/.acme.sh"
cert_base_dir="/etc/ssl"
reload_cmd="systemctl reload nginx || systemctl reload xray || systemctl reload v2ray"

# 安装 acme.sh
install_acme() {
  if [ ! -d "$acme_dir" ]; then
    echo "acme.sh 未安装，正在安装..."
    curl https://get.acme.sh | sh
  fi
  source ~/.bashrc
  export PATH="$acme_dir":$PATH
}

request_cert() {
  read -p "请输入要申请证书的域名: " domain
  read -p "请输入邮箱(可选，直接回车跳过): " email

  # 尝试关闭 80 端口
  echo "尝试关闭 80 端口可能占用进程..."
  systemctl stop nginx 2>/dev/null
  systemctl stop apache2 2>/dev/null

  # 申请证书
  if [ -z "$email" ]; then
    $acme_dir/acme.sh --issue -d $domain --standalone
  else
    $acme_dir/acme.sh --issue -d $domain --standalone -m $email
  fi

  mkdir -p $cert_base_dir/$domain
  $acme_dir/acme.sh --install-cert -d $domain \
    --key-file $cert_base_dir/$domain/private.key \
    --fullchain-file $cert_base_dir/$domain/fullchain.crt \
    --reloadcmd "$reload_cmd"

  echo "证书已安装到 $cert_base_dir/$domain/"
}

delete_cert() {
  read -p "请输入要删除证书的域名: " domain
  $acme_dir/acme.sh --remove -d $domain
  rm -rf $cert_base_dir/$domain
  echo "已删除 $domain 的证书及安装文件夹。"
}

renew_cert() {
  read -p "请输入要强制续签证书的域名: " domain
  $acme_dir/acme.sh --renew -d $domain --force
  echo "已尝试为 $domain 强制续签证书。"
}

menu() {
  echo "========= 3x-ui 证书管理（Shell版） ========="
  echo "1. 申请证书"
  echo "2. 删除证书"
  echo "3. 强制续签证书"
  echo "0. 退出"
  echo "==========================================="
  read -p "请选择操作: " choice
  case $choice in
    1)
      install_acme
      request_cert
      ;;
    2)
      install_acme
      delete_cert
      ;;
    3)
      install_acme
      renew_cert
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效操作"
      ;;
  esac
}

while true
do
  menu
done