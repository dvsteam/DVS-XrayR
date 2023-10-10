#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

version="v1.0.0"

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Lỗi: ${plain} Tập lệnh này phải được chạy bằng cách sử dụng người dùng root!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Phiên bản hệ thống không được phát hiện, vui lòng liên hệ với tác giả kịch bản!${plain}\n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Vui lòng sử dụng CentOS 7 trở lên hệ thống!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ thống Ubuntu 16 trở lên!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng Debian 8 trở lên!${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [mặc định $2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Có khởi động lại XrayR hay không" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Nhấn Enter trở lại để trở về menu chính: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -n -e "Nhập phiên bản được chỉ định (mặc định là phiên bản mới nhất): " && read version
    else
        version=$2
    fi
#    confirm "本功能会强制重装当前最新版，数据不会丢失，是否继续?" "n"
#    if [[ $? != 0 ]]; then
#        echo -e "${red}已取消${plain}"
#        if [[ $1 != 0 ]]; then
#            before_show_menu
#        fi
#        return 0
#    fi
    bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}Bản cập nhật hoàn tất và XrayR đã được tự động khởi động lại, sử dụng “XrayR log” để xem nhật ký chạy${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "XrayR tự động cố gắng khởi động lại sau khi sửa đổi cấu hình"
    vi /etc/XrayR/config.yml
    sleep 2
    check_status
    case $? in
        0)
            echo -e "Trạng thái XrayR: ${green} đã chạy ${plain}"
            ;;
        1)
            echo -e "Bạn có xem nhật ký khi phát hiện bạn không khởi động XrayR hoặc XrayR tự động khởi động lại không? [Y/n]" && echo
            read -e -p "(Mặc định là: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "Trạng thái XrayR: ${red} chưa cài đặt${plain}"
    esac
}

uninstall() {
    confirm "Bạn có chắc chắn muốn gỡ cài đặt XrayR không?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop XrayR
    systemctl disable XrayR
    rm /etc/systemd/system/XrayR.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/XrayR/ -rf
    rm /usr/local/XrayR/ -rf

    echo ""
    echo -e "Gỡ cài đặt thành công, nếu bạn muốn xóa tập lệnh này, sau khi thoát khỏi tập lệnh chạy ${green}rm /usr/bin/XrayR -f${plain} để xóa"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}XrayR đã được chạy, không cần khởi động nữa, nếu bạn cần khởi động lại, vui lòng chọn khởi động lại ${plain}"
    else
        systemctl start XrayR
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}XrayR khởi chạy thành công, vui lòng sử dụng ″XrayR log‶ để xem nhật ký chạy ${plain}"
        else
            echo -e "${red}XrayR khởi chạy thất bại, vui lòng sử dụng ‟XrayR log” để xem tiến trình ${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    systemctl stop XrayR
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}XrayR Dừng lại thành công${plain}"
    else
        echo -e "${red}XrayR dừng thất bại, vui lòng kiểm tra thông báo log ${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart XrayR
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}XrayR Khởi Động Thành Công${plain}"
        echo -e "${green}[XrayR đang chạy] để kiểm tra tiến trình gõ: ‟XrayR log” ${plain}"
    else
        echo -e "${red}Lỗi: XrayR khởi động thất bại, Gõ: ‟xrayr log” để xem tình trạng ${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status XrayR --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable XrayR
    if [[ $? == 0 ]]; then
        echo -e "${green}XrayR được đặt để khởi động tự động${plain}"
    else
        echo -e "${red}XrayR Cài đặt không tự động khởi động${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable XrayR
    if [[ $? == 0 ]]; then
        echo -e "${green}XrayR Hủy khởi động thành công${plain}"
    else
        echo -e "${red}XrayR Hủy bỏ lỗi khởi động máy tính${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u XrayR.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh)
    #if [[ $? == 0 ]]; then
    #    echo ""
    #    echo -e "${green}安装 bbr 成功，请重启服务器${plain}"
    #else
    #    echo ""
    #    echo -e "${red}下载 bbr 安装脚本失败，请检查本机能否连接 Github${plain}"
    #fi

    #before_show_menu
}

update_shell() {
    wget -O /usr/bin/XrayR -N --no-check-certificate https://raw.githubusercontent.com/dvsteam/DVS-XrayR/main/XrayR.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Tải xuống tập lệnh không thành công, vui lòng kiểm tra xem thiết bị có thể kết nối với Github không${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/XrayR
        echo -e "${green}Tập lệnh nâng cấp thành công, vui lòng chạy lại tập lệnh${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/XrayR.service ]]; then
        return 2
    fi
    temp=$(systemctl status XrayR | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled XrayR)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}XrayR đã được cài đặt, vui lòng không cài đặt lại nhiều lần${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Vui lòng cài đặt XrayR trước${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Trạng thái XrayR: ${green} Đang chạy ${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Trạng thái XrayR: ${yellow} Không chạy ${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Trạng thái XrayR: ${red} Chưa cài đặt ${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Có khởi động lại tự động, sau khi bật nguồn hay không: ${green}CÓ${plain}"
    else
        echo -e "Có khởi động lại tự động, sau khi bật nguồn hay không: ${red}KHÔNG${plain}"
    fi
}

show_XrayR_version() {
    echo -n "Phiên bản XrayR:"
    /usr/local/XrayR/XrayR -version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_usage() {
    echo "XrayR Cách sử dụng tập lệnh quản lý: "
    echo "------------------------------------------"
    echo "XrayR              - Hiển thị menu quản lý (nhiều chức năng hơn)"
    echo "XrayR start        - Bắt đầu XrayR"
    echo "XrayR stop         - Dừng XrayR"
    echo "XrayR restart      - Khởi động lại XrayR"
    echo "XrayR status       - Xem trạng thái XrayR"
    echo "XrayR enable       - Đặt XrayR tự động khởi động khi khởi động"
    echo "XrayR disable      - Hủy tự động khởi động XrayR khi khởi động"
    echo "XrayR log          - Xem nhật ký XrayR"
    echo "XrayR update       - Cập nhật XrayR"
    echo "XrayR update x.x.x - Cập nhật phiên bản cụ thể của XrayR"
    echo "XrayR install      - Cài đặt XrayR"
    echo "XrayR uninstall    - Gỡ cài đặt XrayR"
    echo "XrayR version      - Xem phiên bản XrayR"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}XrayR Menu tiện ích${plain}
  ${red}---> Địa chỉ dự án DVSTEAM https://github.com/dvsteam/DVS-XrayR <---${plain}
  ${green}0.${plain} Thay đổi cài đặt
————————————————
  ${green}1.${plain} Cài đặt XrayR
  ${green}2.${plain} Cập nhật XrayR
  ${green}3.${plain} Gỡ cài đặt XrayR
————————————————
  ${green}4.${plain} Bắt đầu XrayR
  ${green}5.${plain} Dừng XrayR
  ${green}6.${plain} Khởi động lại XrayR
  ${green}7.${plain} Xem trạng thái XrayR
  ${green}8.${plain} Xem nhật ký log XrayR
————————————————
  ${green}9.${plain} Đặt XrayR tự động khởi động khi khởi động
 ${green}10.${plain} Hủy tự động khởi động XrayR khi khởi động
————————————————
 ${green}11.${plain} Cài đặt bbr (kernel mới nhất) chỉ bằng một cú nhấp chuột
 ${green}12.${plain} Xem phiên bản XrayR
 ${green}13.${plain} Kịch bản bảo trì nâng cấp
 "
#Các bản cập nhật tiếp theo có thể được thêm vào chuỗi ở trên
    show_status
    echo && read -p "Vui lòng nhập lựa chọn của bạn [0-13]: " num

    case "${num}" in
        0) config
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && start
        ;;
        5) check_install && stop
        ;;
        6) check_install && restart
        ;;
        7) check_install && status
        ;;
        8) check_install && show_log
        ;;
        9) check_install && enable
        ;;
        10) check_install && disable
        ;;
        11) install_bbr
        ;;
        12) check_install && show_XrayR_version
        ;;
        13) update_shell
        ;;
        *) echo -e "${red}Vui lòng nhập đúng số [0-12]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0 $2
        ;;
        "config") config $*
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_XrayR_version 0
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    show_menu
fi
