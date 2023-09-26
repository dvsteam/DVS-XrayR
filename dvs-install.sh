#!/bin/bash

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
echo "Vui lòng chạy dưới dạng root -->Gõ: sudo -i <-- Để truy cập root"
exit
fi

if [ -f "./dvsteam" ]; then

chmod +x ./dvsteam
  ./dvsteam 

else
sudo apt update
sudo apt install wget unzip

  wget https://github.com/dvsteam/DVSTEAM-XrayR/releases/download/dvsteam-build/dvsteam.zip
  unzip -d ./ dvsteam.zip && rm dvsteam.zip

  chmod +x ./dvsteam
  ./dvsteam

fi
