#!/bin/sh

# Welcome message

# Select network interface
read -p "请选择和PS4连接的网口（0-9）： " interface_num
if ! echo "$interface_num" | grep -qE '^[0-9]$'; then
    echo "输入错误，请输入0到9之间的数字。"
    exit 1
fi
interface="eth$interface_num"

# Select PS4 firmware version
echo "请选择PS4的固件版本：1为9.00, 2为10.00, 3为10.01, 4为11.00, 5为9.60"
read -p "请输入版本号（1、2、3或4、5）： " fw_version
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
    5)
        fw_code="960"
        stage1_file="stage1_9.60.bin"
        stage2_file="stage2_9.60.bin"
        ;;
    *)
        echo "输入错误，请输入1、2、3或4。、5"
        exit 1
        ;;
esac

# Determine platform architecture
arch=$(uname -m)
case $arch in
    x86_64)
        pppwn_executable="/etc/pppwn/pppwn_x86_64"
        ;;
    aarch64)
        pppwn_executable="/etc/pppwn/pppwn_aarch64"
        ;;
    mipsel)
        pppwn_executable="/etc/pppwn/pppwn_mipsel"
        ;;
    *)
        echo "PS4越狱工具不支持当前平台，请更换路由器或等待新版越狱工具。"
        exit 1
        ;;
esac

# Run the jailbreak tool
echo "正在运行PS4越狱工具..."
$pppwn_executable -i $interface --fw $fw_code --stage1 "/etc/pppwn/$stage1_file" --stage2 "/etc/pppwn/$stage2_file" -a
if [ $? -eq 0 ]; then
    echo "PS4越狱工具运行成功。"

    # Ask if user wants to add to startup
    read -p "是否添加自动运行？(y/n): " add_autorun
    if [ "$add_autorun" = "y" ] || [ "$add_autorun" = "Y" ]; then
        echo "#!/bin/sh" > /etc/pppwn/myps4.sh
        echo "$pppwn_executable -i $interface --fw $fw_code --stage1 \"/etc/pppwn/$stage1_file\" --stage2 \"/etc/pppwn/$stage2_file\" -a" >> /etc/pppwn/myps4.sh
        echo "sleep 5" >> /etc/pppwn/myps4.sh
        echo "for pid in \$(pgrep pppwn); do" >> /etc/pppwn/myps4.sh
        echo "    kill \$pid" >> /etc/pppwn/myps4.sh
        echo "done" >> /etc/pppwn/myps4.sh

        chmod +x /etc/pppwn/myps4.sh

        # Create init script for OpenWRT
        cat << 'EOF' > /etc/init.d/myps4
#!/bin/sh /etc/rc.common
# Copyright (C) 2007 OpenWrt.org

START=99
STOP=10

start() {
    echo "Starting PS4 jailbreak tool..."
    /etc/pppwn/myps4.sh &
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
    cat << 'EOF' > /etc/pppwn/monitor_ps4.sh
#!/bin/sh
while true; do
    if ! pgrep -f pppwn > /dev/null; then
        echo "PS4越狱工具未运行，正在重启..."
        /etc/pppwn/myps4.sh &
    fi
    sleep 60
done
EOF

    chmod +x /etc/pppwn/monitor_ps4.sh

    # Add monitor script to startup
    cat << 'EOF' > /etc/init.d/monitor_ps4
#!/bin/sh /etc/rc.common
# Copyright (C) 2007 OpenWrt.org

START=100
STOP=15

start() {
    echo "Starting PS4 jailbreak monitor..."
    /etc/pppwn/monitor_ps4.sh &
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
