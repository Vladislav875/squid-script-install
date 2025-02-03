#!/bin/bash

set -e  # Прерывать выполнение при ошибке

# Установка Squid
echo "Обновление списка пакетов..."
sudo /usr/bin/apt update

echo "Установка apache2-utils и Squid..."
sudo /usr/bin/apt -y install apache2-utils squid

# Настройка Squid
echo "Настройка Squid..."
sudo touch /etc/squid/passwd
sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
sudo /usr/bin/touch /etc/squid/blacklist.acl
echo "Загрузка конфигурационного файла..."
sudo /usr/bin/wget --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/conf/ubuntu-2204.conf

# Разрешение трафика через iptables
echo "Настройка iptables..."
if [ -f /sbin/iptables ]; then
    sudo /sbin/iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
fi

# Создание пользователя с случайным именем и паролем
echo "Создание пользователя Squid..."
USERNAME="user_$(openssl rand -hex 4)"
PASSWORD=$(openssl rand -base64 12)
echo -n "$USERNAME:$PASSWORD" | sudo tee /etc/squid/passwd
sudo chown proxy:proxy /etc/squid/passwd
sudo chmod 600 /etc/squid/passwd
echo "Добавление пользователя в htpasswd..."
sudo htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD

# Перезапуск Squid
echo "Перезапуск Squid..."
sudo systemctl enable squid
echo "Запуск Squid..."
sudo service squid restart

# Получение IP-адреса
echo "Получение IP-адреса..."
IP=$(curl -s ifconfig.me)
PORT=3128

# Вывод строки подключения
echo "Прокси доступен по адресу: $IP:$PORT:$USERNAME:$PASSWORD"
