#!/bin/bash
myip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | head -n1`;
myint=`ifconfig | grep -B1 "inet addr:$myip" | head -n1 | awk '{print $1}'`;

flag=0

source="https://raw.githubusercontent.com/trigetmore/selalu_cinta"

#iplist="ip.txt"

wget --quiet -O iplist.txt $source/debian7/ip.txt

#if [ -f iplist ]
#then

iplist="iplist.txt"

lines=`cat $iplist`
#echo $lines

for line in $lines; do
#        echo "$line"
        if [ "$line" = "$myip" ]
        then
                flag=1
        fi

done


if [ $flag -eq 0 ]
then
   echo  "Your Server IP is not registered. Please contact admin"
   rm /root/debian32.sh
   exit 1
fi
# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install wget and curl
apt-get update
apt-get -y install wget curl

# Change to Time GMT+8
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# remove unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

# update
apt-get update 
apt-get -y upgrade

# install webserver
apt-get -y install nginx php5-fpm php5-cli

# install essential package
apt-get -y install nmap nano iptables sysv-rc-conf openvpn vnstat apt-file
apt-get -y install libexpat1-dev libxml-parser-perl
apt-get -y install build-essential

# disable exim
service exim4 stop
sysv-rc-conf exim4 off

# update apt-file
apt-file update

# Setting Vnstat
vnstat -u -i eth0
chown -R vnstat:vnstat /var/lib/vnstat
service vnstat restart

# install screenfetch
cd
wget $source/debian7/screenfetch-dev
mv screenfetch-dev /usr/bin/screenfetch
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile

# Install Web Server
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf $source/debian7/nginx.conf
mkdir -p /home/vps/public_html
echo "<pre>Setup by big bos</pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
wget -O /etc/nginx/conf.d/vps.conf $source/debian7/vps.conf
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
service php5-fpm restart
service nginx restart

# install openvpn
wget -O /etc/openvpn/openvpn.tar $source/debian7/openvpn.tar
cd /etc/openvpn/
tar xf openvpn.tar
wget -O /etc/openvpn/1194.conf $source/debian7/1194-debian.conf
service openvpn restart
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
wget -O /etc/iptables.up.rules $source/debian7/iptables.up.rules
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | grep -v '192.168'`;
MYIP2="s/xxxxxxxxx/$MYIP/g";
sed -i 's/port 1194/port 6500/g' /etc/openvpn/1194.conf
sed -i $MYIP2 /etc/iptables.up.rules;
iptables-restore < /etc/iptables.up.rules
service openvpn restart

# configure openvpn client config
cd /etc/openvpn/
wget -O /etc/openvpn/1194-client.ovpn $source/debian7/1194-client.conf
sed -i $MYIP2 /etc/openvpn/1194-client.ovpn;
sed -i 's/1194/6500/g' /etc/openvpn/1194-client.ovpn
NAME=`uname -n`.`awk '/^domain/ {print $2}' /etc/resolv.conf`;
mv /etc/openvpn/1194-client.ovpn /etc/openvpn/$NAME.ovpn
useradd -M -s /bin/false deenie11
echo "deenie11:deenie" | chpasswd
tar cf client.tar $NAME.ovpn
cp client.tar /home/vps/public_html/
cd

# setting port ssh
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i 's/Port 22/Port  22/g' /etc/ssh/sshd_config
service ssh restart

# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 443 -p 109 -p 80 -p 110"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
service ssh restart
service dropbear restart

# install vnstat gui
cd /home/vps/public_html/
wget $source/debian7/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
sed -i "s/\$locale = 'en_US.UTF-8';/\$locale = 'en_US.UTF+8';/g" config.php
cd

# install fail2ban
apt-get -y install fail2ban;
service fail2ban restart

# install squid3
apt-get -y install squid3
wget -O /etc/squid3/squid.conf $source/debian7/squid.conf
sed -i $MYIP2 /etc/squid3/squid.conf;
service squid3 restart

# install webmin
cd
wget "http://prdownloads.sourceforge.net/webadmin/webmin_1.820_all.deb"
dpkg --install webmin_1.820_all.deb;
apt-get -y -f install;
rm /root/webmin_1.820_all.deb
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart
service vnstat restart

# User Status
cd
wget $source/debian7/user-list
mv ./user-list /usr/local/bin/user-list
chmod +x /usr/local/bin/user-list

# Install Ddos Deflate
apt-get -y install dnsutils dsniff
wget $source/debian7/ddos-deflate-master.zip
unzip master.zip
cd ddos-deflate-master
./install.sh
cd

# Install SSH autokick
cd
wget $source/debian7/Autokick-debian.sh
bash Autokick-debian.sh

# Install Monitor
cd
wget $source/debian7/monssh; mv monssh /usr/local/bin/; chmod +x /usr/local/bin/monssh

# Install Menu
cd
wget $source/debian7/menu
mv ./menu /usr/local/bin/menu
chmod +x /usr/local/bin/menu

# moth
cd
wget $source/debian7/motd
mv ./motd /etc/motd

# Restart Service
chown -R www-data:www-data /home/vps/public_html
service nginx start
service php-fpm start
service vnstat restart
service openvpn restart
service ssh restart
service dropbear restart
service fail2ban restart
service squid3 restart
service webmin restart

#rip
cd
rm debian32.sh
rm menu.sh

# info

clear

echo "Setup by Anonymous/debian-7-bit-64"
echo ""
echo "layanan yang di aktifkan"
echo ""
echo "silahkan login melalui putty/juicessh"
echo "ip host  :$MYIP"
echo "user     :root"
echo "password :PASS VPS ANDA"
echo ""
echo "OpenVPN  : TCP 1194 (client config : http://$MYIP:81/client.tar)"
echo "OpenSSH  : 22, 143"
echo "Dropbear : 109, 110, 443, 80"
echo "Squid3   : 8080, 3128, 80 (limit to IP SSH)"
echo ""
echo "----------------------------------------------------"
echo "Webmin   : http://$MYIP:10000/"
echo "vnstat   : http://$MYIP:81/vnstat/"
echo "Timezone : Asia/Jakarta"
echo "Fail2Ban : [on]"
echo "IPv6     : [off]"
echo "Status   : please type ./status to check user status"
echo ""
echo "=============================================================================="
echo ""
echo "layanan menggunakan menu jika ingin membuat user ssh dll"
echo "silahkan jalankan perintah dengan ketik (menu)"
echo "Maka akan muncul layanan di bawah ini dan jika ingin membuat"
echo "perintah buat user dll silahkan tekan no yang ingin di jalankan dibawah :"
echo ""
echo "=============================================================================="
echo "1. Buat user"
echo "(membuat user ssh/vpn)"
echo "2. Perpanjang user"
echo "(perpanjangan masa aktif user ssh/vpn)"
echo "3. Hapus user"
echo "(hapus akun user ssh/vpn selamanya)"
echo "4. Daftar user"
echo "(list daftar user ssh/vpn)"
echo "5. User belum expired" 
echo "(user yang belum habis masa aktifnya)"
echo "6. User expired"
echo "(user yang sudah habis masa aktifnya)"
echo "7. Restart VPS"
echo "(refresh server minimal 2 kali dalam sehari pada jam 12.00 & 21.00)"
echo "8. Ganti pass VPS"
echo "(mengganti password VPS server anda)"
echo "9. Pengunaan data user"
echo "(melihat trafic keluar masuk data yang di terima dan keluar)"
echo "10. Status spek VPS"
echo "(melihat status memory spek cpu server & ram)"
echo "11. Monitor login & multi"
echo "(lihat user OL & user multi,jika user login lebih dari 3 maka multi login)"
echo "12. Restart port openvpn"
echo "(refresh port openvpn agar tetap stabil)"
echo "13. Restart port dropbear"
echo "(refresh port dropbear agar tetap stabil)"
echo "14. Restart port squid"
echo "(refresh port squid agar tetap stabil)"
echo "15. Restart cron service"
echo "(refresh cron agar tetap stabil)"
echo "16. Restart openssh service"
echo "(refresh port openssh agar tetap stabil)"
echo "17. Keluar VPS"
echo "(logout VPS server)"
rm ./debian32.sh
