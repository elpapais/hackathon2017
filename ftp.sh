#!/bin/bash

export TERM=xterm-color

NC='\033[0m' # No Color
RED='\033[0;31m'
LIGHTGREEN='\033[1;32m'
CYAN='\033[0;36m'
LIGHTYELLOW='\033[1;33m'
bold=$(tput bold)
normal=$(tput sgr0)

username=$(whoami)
ftpusername=`gpw 1 10`
ftppasswd=`pwgen 20 1`

echo '----------------------------------------'
echo -e ${CYAN}${bold}'INSTALLING PREREQUISITES.....'${normal}${LIGHTYELLOW}
echo '----------------------------------------'

sudo apt-get --assume-yes update
sudo apt-get --assume-yes install vsftpd

echo ''
echo ''
echo '----------------------------------------'${normal}${NC}
echo ''
echo ''
echo ''
echo ''


echo '----------------------------------------'
echo -e ${CYAN}${bold}'CONFIGURING FTP.....'${normal}${LIGHTYELLOW}
echo '----------------------------------------'

sudo useradd -d /var/www/html $ftpusername
echo $ftpusername":"$ftppasswd | sudo chpasswd
sudo sed -ie 's/.*anonymous_enable=.*/anonymous_enable=NO/g' /etc/vsftpd.conf
sudo sed -ie 's/.*local_enable=.*/local_enable=YES/g' /etc/vsftpd.conf
sudo sed -ie 's/.*write_enable=.*/write_enable=YES/g' /etc/vsftpd.conf
sudo sed -ie 's/.*chroot_local_user=.*/chroot_local_user=YES/g' /etc/vsftpd.conf
sudo sed -ie 's/.*chroot_list_enable=.*/chroot_list_enable=YES/g' /etc/vsftpd.conf
sudo sed -ie 's/.*chroot_list_file=.*/chroot_list_file=\/etc\/vsftpd.chroot_list/g' /etc/vsftpd.conf
sudo bash -c 'echo '$ftpusername' > /etc/vsftpd.chroot_list'
sudo chown $ftpusername: /var/www/html
sudo chmod u+w /var/www/html

echo ''
echo ''
echo '----------------------------------------'${normal}${NC}
echo ''
echo ''
echo ''
echo ''

echo -e ${LIGHTGREEN}${bold}'----------------------------------------'
echo -e 'SECURE FTP SUCCESSFULLY SET UP!'
echo -e '----------------------------------------'${normal}${NC}
echo ''
echo ''

echo -e ${normal}${CYAN}'User Name - '${bold}${LIGHTYELLOW}$ftpusername
echo -e ${normal}${CYAN}'Password - '${bold}${LIGHTYELLOW}$ftppasswd
echo -e ${normal}${NC}