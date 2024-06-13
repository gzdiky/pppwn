#!/bin/sh

# Welcome message
echo "本脚用来运行OpenWRT的软路由闲置资源自动破解PS4，漏洞来自PPPwn，payload是GoldHEN 2.4b173，当前支持PS4固件9.00; 9.60和11.00的越狱。by ntbowen"
echo "在开始前请准备U盘 并放入GLODHEN 首次破解需插入PS4："
echo "连接路由器和PS4线路"
echo "PS4的网络设置为有线连接、定制、pppoe（账户密码随意）、DNS自动、MTU自动、不使用Proxy服务器"
echo "路由器开启程序并准备运行中后，，，PS4操作 测试连接网络激活程序运行"

# Remove startup entry and stop any running PPPwn processes
echo "正在删除系统启动项并停止PPPwn相关进程..."
/etc/init.d/myps4 disable
/etc/init.d/myps4 stop

# Kill any running PPPwn processes
for pid in $(pgrep pppwn); do
    kill $pid
done

# Check if required packages and files are already installed
check_installation() {
    if opkg list-installed | grep -q 'unzip' && opkg list-installed | grep -q 'libpcap' &&
       [ -f /etc/pppwn/pppwn_aarch64 ] && [ -f /etc/pppwn/pppwn_x86_64 ] && [ -f /etc/pppwn/pppwn_mipsel ] &&
       [ -f /etc/pppwn/stage1_9.00.bin ] && [ -f /etc/pppwn/stage1_9.60.bin ] && [ -f /etc/pppwn/stage1_10.00.bin ] && [ -f /etc/pppwn/stage1_10.01.bin ] && [ -f /etc/pppwn/stage1_11.00.bin ] &&
       [ -f /etc/pppwn/stage2_9.00.bin ] && [ -f /etc/pppwn/stage2_9.60.bin ] && [ -f /etc/pppwn/stage2_10.00.bin ] && [ -f /etc/pppwn/stage2_10.01.bin ] && [ -f /etc/pppwn/stage2_11.00.bin ]; then
        return 0
    else
        return 1
    fi
}

# Function to install required packages
install_packages() {
    echo "正在下载安装必要插件..."
    opkg update

    # Check and install unzip if not installed
    if ! opkg list-installed | grep -q 'unzip'; then
        opkg install unzip
        if [ $? -ne 0 ]; then
            echo "unzip 安装失败。请检查软件源是否提供所需软件或者安装符合要求的OpenWRT。"
            read -p "是否重试？(y/n): " retry
            if [ "$retry" = "y" ] || [ "$retry" = "Y" ]; then
                install_packages
            else
                exit 1
            fi
        fi
    fi

    # Check and install libpcap if not installed
    if ! opkg list-installed | grep -q 'libpcap'; then
        opkg install libpcap
        if [ $? -ne 0 ]; then
            echo "libpcap 安装失败。请检查软件源是否提供所需软件或者安装符合要求的OpenWRT。"
            read -p "是否重试？(y/n): " retry
            if [ "$retry" = "y" ] || [ "$retry" = "Y" ]; then
                install_packages
            else
                exit 1
            fi
        fi
    fi
}

# Function to download and install PS4 jailbreak tools
install_jailbreak_tools() {
    echo "正在下载安装PS4越狱工具..."
    wget https://github.com/gzdiky/pppwn/archive/refs/heads/main.zip -O /tmp/main.zip && unzip -o -j /tmp/main.zip -d /etc/pppwn
    if [ $? -ne 0 ]; then
        echo "下载或解压失败。"
        read -p "是否重试？(y/n): " retry
        if [ "$retry" = "y" ] || [ "$retry" = "Y" ]; then
            install_jailbreak_tools
        else
            exit 1
        fi
    fi
}

# Check if already installed
if check_installation; then
    echo "你似乎安装过PS4越狱工具。"
    read -p "是否升级或重新安装PS4越狱工具？(y/n): " reinstall
    if [ "$reinstall" != "y" ] && [ "$reinstall" != "Y" ]; then
        read -p "是否直接开始PS4越狱？(y/n): " start_jailbreak
        if [ "$start_jailbreak" != "y" ] && [ "$start_jailbreak" != "Y" ]; then
            echo "退出脚本。"
            exit 0
        fi
    else
        install_packages
        install_jailbreak_tools
    fi
else
    read -p "是否安装PS4越狱工具？(y/n): " install
    if [ "$install" != "y" ] && [ "$install" != "Y" ]; then
        echo "退出脚本。"
        exit 0
    else
        install_packages
        install_jailbreak_tools
    fi
fi

# Select network interface
read -p "请选择和PS4连接的网口（0-9）： " interface_num
if ! echo "$interface_num" | grep -qE '^[0-9]$'; then
    echo "输入错误，请输入0到9之间的数字。"
    exit 1
fi
interface="eth$interface_num"

# Select PS4 firmware version
echo "请选择PS4的固件版本：1为9.00, 2为10.00, 3为10.01, 4为11.00"
read -p "请输入版本号（1、2、3或4）： " fw_version
case $fw_version in
    1)
        fw_code="900"
        stage1_file="stage1_9.00.bin"
        stage2_file="stage2_9.00.bin"
        ;;
    2)
        fw_code="1000"
        stage1_file="stage1_10.00.bin"
        stage2_file="stage2_10.00.bin"
        ;;
    3)
        fw_code="1001"
        stage1_file="stage1_10.01.bin"
        stage2_file="stage2_10.01.bin"
        ;;
    4)
        fw_code="1100"
        stage1_file="stage1_11.00.bin"
        stage2_file="stage2_11.00.bin"
        ;;
    *)
        echo "输入错误，请输入1、2、3或4。"
        exit 1
        ;;
esac

# Determine platform architecture
arch=$(uname -m)
case $arch in
    x86_64)
        pppwn_executable="/etc/PPPwn/pppwn_x86_64"
        ;;
    aarch64)
        pppwn_executable="/etc/PPPwn/pppwn_aarch64"
        ;;
    mipsel)
        pppwn_executable="/etc/PPPwn/pppwn_mipsel"
        ;;
    *)
        echo "PS4越狱工具不支持当前平台，请更换路由器或等待新版越狱工具。"
        exit 1
        ;;
esac

# Run the jailbreak tool
echo "正在运行PS4越狱工具..."
$pppwn_executable -i $interface --fw $fw_code --stage1 "/etc/PPPwn/$stage1_file" --stage2 "/etc/PPPwn/$stage2_file" -a
if [ $? -eq 0 ]; then
    echo "PS4越狱工具运行成功。"

    # Ask if user wants to add to startup
    read -p "是否添加自动运行？(y/n): " add_autorun
    if [ "$add_autorun" = "y" ] || [ "$add_autorun" = "Y" ]; then
        echo "#!/bin/sh" > /etc/PPPwn/myps4.sh
        echo "$pppwn_executable -i $interface --fw $fw_code --stage1 \"/etc/PPPwn/$stage1_file\" --stage2 \"/etc/PPPwn/$stage2_file\" -a" >> /etc/PPPwn/myps4.sh
        echo "sleep 5" >> /etc/PPPwn/myps4.sh
        echo "for pid in \$(pgrep pppwn); do" >> /etc/PPPwn/myps4.sh
        echo "    kill \$pid" >> /etc/PPPwn/myps4.sh
        echo "done" >> /etc/PPPwn/myps4.sh

        chmod +x /etc/PPPwn/myps4.sh

        # Create init script for OpenWRT
        cat << 'EOF' > /etc/init.d/myps4
#!/bin/sh /etc/rc.common
# Copyright (C) 2007 OpenWrt.org

START=99
STOP=10

start() {
    echo "Starting PS4 jailbreak tool..."
    /etc/PPPwn/myps4.sh &
}

stop() {
    echo "Stopping PS4 jailbreak tool..."
    for pid in $(pgrep pppwn); do
        kill $pid
    done
}

EOF

        # Make the init script executable and enable it
        chmod +x /etc/init.d/myps4
        /etc/init.d/myps4 enable

        echo "PS4越狱工具已添加到系统启动项。"

    fi

    # Setup process monitoring
    echo "正在设置进程守护..."
    cat << 'EOF' > /etc/PPPwn/monitor_ps4.sh
#!/bin/sh
while true; do
    if ! pgrep -f pppwn > /dev/null; then
        echo "PS4越狱工具未运行，正在重启..."
        /etc/PPPwn/myps4.sh &
    fi
    sleep 60
done
EOF

    chmod +x /etc/PPPwn/monitor_ps4.sh

    # Add monitor script to startup
    cat << 'EOF' > /etc/init.d/monitor_ps4
#!/bin/sh /etc/rc.common
# Copyright (C) 2007 OpenWrt.org

START=100
STOP=15

start() {
    echo "Starting PS4 jailbreak monitor..."
    /etc/PPPwn/monitor_ps4.sh &
}

stop() {
    echo "Stopping PS4 jailbreak monitor..."
    for pid in $(pgrep -f monitor_ps4.sh); do
        kill $pid
    done
}

EOF

    chmod +x /etc/init.d/monitor_ps4
    /etc/init.d/monitor_ps4 enable

    echo "进程守护已设置完成。"

    # 立即启动 myps4 和 monitor_ps4
    /etc/init.d/myps4 start
    /etc/init.d/monitor_ps4 start

else
    echo "PS4越狱工具运行失败，请检查配置。"
    exit 1
fi

echo "脚本执行完毕。"