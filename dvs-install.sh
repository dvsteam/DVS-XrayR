#!/bin/bash

DVSxrayr="https://github.com/dvsteam/DVS-XrayR/releases/download/dvsteam/dvsteam.zip"
DVSfile="dvsteam.zip"

# Kiểm tra quyền root
[ "$(id -u)" -ne 0 ] && echo "DVSTEAM này cần quyền root để chạy. Vui lòng chạy dưới dạng root -->Gõ: sudo -i <-- Để truy cập root" && exit 1

for cmd in wget unzip; do
    command -v $cmd &> /dev/null || { echo "Cài đặt $cmd..."; sudo apt update; sudo apt install $cmd -y; }
done

if [ ! -f "./dvsteam" ]; then
    wget "$DVSxrayr" && unzip -d ./ "$DVSfile" && rm "$DVSfile"
fi

[ -f "./dvsteam" ] && { chmod +x ./dvsteam; ./dvsteam; } || echo "Lỗi khi chạy dvsteam"
