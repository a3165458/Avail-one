#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi


# 检查并安装 Node.js 和 npm
function install_nodejs_and_npm() {
    if ! command -v node > /dev/null 2>&1; then
        echo "Node.js 未安装，正在安装..."
        curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
        sudo apt-get install -y nodejs
        echo "Node.js 安装完成。"
    else
        echo "Node.js 已安装。"
    fi

    if ! command -v npm > /dev/null 2>&1; then
        echo "npm 未安装，正在安装..."
        sudo apt-get install -y npm
        echo "npm 安装完成。"
    else
        echo "npm 已安装。"
    fi
}

# 检查并安装 PM2
function install_pm2() {
    if ! command -v pm2 > /dev/null 2>&1; then
        echo "PM2 未安装，正在安装..."
        npm install pm2@latest -g
        echo "PM2 安装完成。"
    else
        echo "PM2 已安装。"
    fi
}


# 脚本保存路径
SCRIPT_PATH="$HOME/Avail-one.sh"

# 自动设置快捷键的功能
function check_and_set_alias() {
    local alias_name="availf"
    local shell_rc="$HOME/.bashrc"

    # 对于Zsh用户，使用.zshrc
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    # 检查快捷键是否已经设置
    if ! grep -q "$alias_name" "$shell_rc"; then
        echo "设置快捷键 '$alias_name' 到 $shell_rc"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        # 添加提醒用户激活快捷键的信息
        echo "快捷键 '$alias_name' 已设置。请运行 'source $shell_rc' 来激活快捷键，或重新打开终端。"
    else
        # 如果快捷键已经设置，提供一个提示信息
        echo "快捷键 '$alias_name' 已经设置在 $shell_rc。"
        echo "如果快捷键不起作用，请尝试运行 'source $shell_rc' 或重新打开终端。"
    fi
}

# 节点安装功能
function install_node() {

install_nodejs_and_npm
install_pm2


# 函数：检查命令是否存在
exists() {
  command -v "$1" >/dev/null 2>&1
}

# 函数：检查依赖项是否存在
exists() {
  command -v "$1" >/dev/null 2>&1
}

# 函数：安装依赖项（如果不存在）
install_dependencies() {
  local update_needed=0
  local to_install=()

  for dep in "$@"; do
    if ! exists "$dep"; then
      to_install+=("$dep")
      update_needed=1
    fi
  done

  if [ "$update_needed" -eq 1 ]; then
    echo "更新软件包索引..."
    sudo apt update -y
    echo "安装依赖项：${to_install[*]}"
    sudo apt install -y "${to_install[@]}"
  else
    echo "所有依赖项已安装。"
  fi
}

# 安装必要的依赖项
dependencies=(curl make clang pkg-config libssl-dev build-essential)
install_dependencies "${dependencies[@]}"


# 设置安装目录和发布 URL
INSTALL_DIR="${HOME}/avail-light"
RELEASE_URL="https://github.com/availproject/avail-light/releases/download/v1.8.0-rc1/avail-light-linux-amd64.tar.gz"

# 创建安装目录并进入
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit

# 下载并解压发布包
wget "$RELEASE_URL"
tar -xvzf avail-light-linux-amd64.tar.gz
cp avail-light-linux-amd64 avail-light

# 创建identity.toml文件
read -p "请输入您的12位钱包助记词：" SECRET_SEED_PHRASE
cat > identity.toml <<EOF
avail_secret_seed_phrase = "$SECRET_SEED_PHRASE"
EOF

pm2 start ./avail-light --name availd -- --network goldberg --identity ./identity.toml 

# 完成安装提示
echo ====================================== 安装完成 =========================================

}



# 查看Avail服务状态
function check_service_status() {
    pm2 list
}

# Avail 节点日志查询
function view_logs() {
    pm2 logs availd
}

# 查询节点匹配的钱包地址（建议安装好后，就查询钱包地址，如果日志过长，该功能可能会失效）
function check_wallet() {
    pm2 logs availd | grep address
}

function uninstall_node() {
    echo "你确定要卸载Avail-light 节点程序吗？这将会删除所有相关的数据。[Y/N]"
    read -r -p "请确认: " response

    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "开始卸载节点程序..."
            pm2 stop availd && pm2 delete availd
            rm -rf $HOME/.avail-light $HOME/artela $(which avail-light)
            echo "节点程序卸载完成。"
            ;;
        *)
            echo "取消卸载操作。"
            ;;
    esac
}


# 主菜单
function main_menu() {
    while true; do
        clear
        echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
        echo "================================================================"
        echo "节点社区 Telegram 群组:https://t.me/niuwuriji"
        echo "节点社区 Telegram 频道:https://t.me/niuwuriji"
        echo "退出脚本，请按键盘ctrl c退出即可"
        echo "请选择要执行的操作:"
        echo "1. 安装节点"
        echo "2. 查看Avail服务状态"
        echo "3. 节点日志查询"
        echo "4. 查询节点匹配的钱包地址"
        echo "5. 设置快捷键的功能"
        echo "6. 卸载节点"
        read -p "请输入选项（1-6）: " OPTION

        case $OPTION in
        1) install_node ;;
        2) check_service_status ;;
        3) view_logs ;;
        4) check_wallet ;;
        5) check_and_set_alias ;;
        6) uninstall_node ;;
        *) echo "无效选项，请重新输入。" ;;
        esac
        read -p "按任意键返回菜单..." 
    done
}

# 显示主菜单
main_menu
