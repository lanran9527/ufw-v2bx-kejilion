#!/usr/bin/env bash

cert_path="/etc/3x-ui/cert"
acme="/root/.acme.sh/acme.sh"

menu() {
    echo "----- 3x-ui 一键证书管理 -----"
    echo "1. 申请(安装)证书"
    echo "2. 强制续签证书"
    echo "3. 删除证书"
    echo "0. 退出"
    echo "---------------------------"
    read -p "请选择功能: " choice
    case $choice in
        1)
            read -p "输入你的域名: " domain
            read -p "输入邮箱(可选，回车略过): " email
            systemctl stop nginx 2>/dev/null
            systemctl stop apache2 2>/dev/null
            if [ -n "$email" ]; then
                $acme --issue -d $domain --standalone -m $email
            else
                $acme --issue -d $domain --standalone
            fi
            mkdir -p $cert_path
            $acme --install-cert -d $domain \
                --key-file $cert_path/private.key \
                --fullchain-file $cert_path/cert.crt \
                --reloadcmd "systemctl reload nginx || systemctl reload xray || systemctl reload v2ray"
            echo "证书已安装到 $cert_path"
            ;;
        2)
            read -p "输入你的域名进行强制续签: " domain
            $acme --renew -d $domain --force
            $acme --install-cert -d $domain \
                --key-file $cert_path/private.key \
                --fullchain-file $cert_path/cert.crt \
                --reloadcmd "systemctl reload nginx || systemctl reload xray || systemctl reload v2ray"
            echo "续签完成（已重新安装证书）"
            ;;
        3)
            read -p "输入你的域名删除证书: " domain
            $acme --remove -d $domain
            rm -rf $cert_path
            echo "证书已删除"
            ;;
        0)
            exit 0
            ;;
        *)
            echo "无效选择"
            ;;
    esac
}

while true; do
    menu
done