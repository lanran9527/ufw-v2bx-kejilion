#!/bin/bash

set -e

REPO="lanran9527/ufw-v2bx-kejilion"   # 换成你的用户名/仓库名
BRANCH="main"                   # 如果不是main分支改成你的分支
SCRIPT_NAME="cert-manage.sh"
INSTALL_DIR="/usr/local/bin"

echo "正在下载 $SCRIPT_NAME ..."

curl -fsSL "https://raw.githubusercontent.com/${REPO}/${BRANCH}/${SCRIPT_NAME}" -o "${INSTALL_DIR}/${SCRIPT_NAME}"

chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"

echo "安装完成!"
echo "你可以直接运行: sudo ${SCRIPT_NAME}"
echo "或直接输入: sudo cert-manage.sh"