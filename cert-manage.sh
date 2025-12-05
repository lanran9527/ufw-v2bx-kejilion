#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

LOGI() { echo -e "${green}[INF] $* ${plain}"; }
LOGE() { echo -e "${red}[ERR] $* ${plain}"; }
LOGD() { echo -e "${yellow}[DEG] $* ${plain}"; }

acme_path=~/.acme.sh/acme.sh
cert_root=/root/cert

# 安装 acme.sh
install_acme() {
    if ! command -v $acme_path &>/dev/null; then
        LOGI "acme.sh未安装，正在安装..."
        curl https://get.acme.sh | sh
        source ~/.bashrc
    else
        LOGI "acme.sh已安装"
    fi
}

# 申请证书
apply_cert() {
    install_acme
    read -rp "请输入你的域名: " domain
    [ -z "$domain" ] && LOGE "域名不能为空" && exit 1

    cert_dir="$cert_root/$domain"
    rm -rf "$cert_dir" && mkdir -p "$cert_dir"

    read -rp "指定申请端口(默认80): " WebPort
    WebPort=${WebPort:-80}

    LOGI "开始为 $domain 申请SSL证书(端口$WebPort)..."
    $acme_path --set-default-ca --server letsencrypt
    $acme_path --issue -d "$domain" --listen-v6 --standalone --httpport "$WebPort" --force
    if [ $? -ne 0 ]; then
        LOGE "申请证书失败"
        exit 1
    fi

    $acme_path --installcert -d "$domain" \
        --key-file "$cert_dir/privkey.pem" \
        --fullchain-file "$cert_dir/fullchain.pem" \
        --reloadcmd "systemctl restart x-ui || x-ui restart"

    LOGI "证书安装成功: $cert_dir"
}

# 吊销证书
revoke_cert() {
    domains=$(find $cert_root/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    [ -z "$domains" ] && LOGE "无证书可吊销" && return
    echo "$domains"
    read -rp "输入要吊销的域名: " domain
    echo "$domains" | grep -qw "$domain" || { LOGE "域名不存在" && return; }
    $acme_path --revoke -d "$domain"
    rm -rf "$cert_root/$domain"
    LOGI "已吊销并清理: $domain"
}

# 强制续签
renew_cert() {
    domains=$(find $cert_root/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    [ -z "$domains" ] && LOGE "无证书可续签" && return
    echo "$domains"
    read -rp "输入强制续签的域名: " domain
    echo "$domains" | grep -qw "$domain" || { LOGE "域名不存在" && return; }
    $acme_path --renew -d "$domain" --force
    LOGI "已强制续签: $domain"
}

# 查看所有证书
list_cert() {
    domains=$(find $cert_root/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    [ -z "$domains" ] && LOGI "暂无任何证书" && return
    for domain in $domains; do
        echo -e "${green}域名：$domain${plain}"
        echo "证书: $cert_root/$domain/fullchain.pem"
        echo "密钥: $cert_root/$domain/privkey.pem"
    done
}

# 设置面板证书
set_panel_cert() {
    domains=$(find $cert_root/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    [ -z "$domains" ] && LOGE "无证书可用" && return
    echo "$domains"
    read -rp "请选择要用于面板的域名: " domain
    cert="$cert_root/$domain/fullchain.pem"
    key="$cert_root/$domain/privkey.pem"
    [[ -f "$cert" && -f "$key" ]] || { LOGE "证书或密钥文件不存在"; return; }
    /usr/local/x-ui/x-ui cert -webCert "$cert" -webCertKey "$key"
    LOGI "面板证书路径已设置!"
}

show_menu() {
    echo -e "
${green}========= 一键SSL证书管理 =========${plain}
  1. 申请证书
  2. 吊销(删除)证书
  3. 强制续签证书
  4. 显示已申请证书
  5. 设置证书为x-ui面板
  0. 退出
====================================
"
    read -rp "请选择操作: " num
    case $num in
        1) apply_cert ;;
        2) revoke_cert ;;
        3) renew_cert ;;
        4) list_cert ;;
        5) set_panel_cert ;;
        0) exit ;;
        *) echo "输入有误" ;;
    esac
}

while true; do
    show_menu
done