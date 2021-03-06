#!/bin/bash
export TERM=xterm-color

NC='\033[0m' # No Color
RED='\033[0;31m'
LIGHTGREEN='\033[1;32m'
CYAN='\033[0;36m'
LIGHTYELLOW='\033[1;33m'
bold=$(tput bold)
normal=$(tput sgr0)

sudo apt-get -y install pwgen gpw

chainname='primechain-hackathon'
rpcuser=`gpw 1 10`
rpcpassword=`pwgen 40 1`
repodir=`pwd`
assetName='yobicoin'
protocol=10007
networkport=61172
rpcport=15590
explorerport=2750
adminNodeName=$chainname'_Admin'
explorerDisplayName=$chainname
phpinipath='/etc/php/7.0/apache2/php.ini'
username='yobiuser'

echo '----------------------------------------'
echo -e ${CYAN}${bold}'INSTALLING PREREQUISITES.....'${normal}${LIGHTYELLOW}
echo '----------------------------------------'

cd .. 

sudo apt-get --assume-yes update
sudo apt-get --assume-yes install jq git vsftpd aptitude apache2-utils php-curl sqlite3 libsqlite3-dev python-dev gcc python-pip
sudo pip install --upgrade pip

wget https://pypi.python.org/packages/60/db/645aa9af249f059cc3a368b118de33889219e0362141e75d4eaf6f80f163/pycrypto-2.6.1.tar.gz
tar -xvzf pycrypto-2.6.1.tar.gz
cd pycrypto*
sudo python setup.py install
cd ..

## Configuring PHP-Curl
sudo sed -ie 's/;extension=php_curl.dll/extension=php_curl.dll/g' $phpinipath

sudo service apache2 restart

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

sleep 3
echo '----------------------------------------'
echo -e ${CYAN}${bold}'CONFIGURING FIREWALL.....'${normal}${LIGHTYELLOW}
echo '----------------------------------------'

sudo ufw allow $networkport
sudo ufw allow $rpcport
sudo ufw allow $explorerport
sudo ufw allow 21

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

echo -e ${LIGHTGREEN}${bold}'----------------------------------------'
echo -e 'FIREWALL SUCCESSFULLY CONFIGURED!'
echo -e '----------------------------------------'${normal}${NC}

echo '----------------------------------------'
echo -e ${CYAN}${bold}'INSTALLING & CONFIGURING MULTICHAIN.....'${normal}${LIGHTYELLOW}
echo '----------------------------------------'

sudo bash -c 'chmod -R 777 /var/www/html'
wget --no-verbose http://www.multichain.com/download/multichain-latest.tar.gz
sudo bash -c 'tar xvf multichain-latest.tar.gz'
sudo bash -c 'cp multichain-1.0-*/multichain* /usr/local/bin/'

su -l $username -c  'multichain-util create '$chainname $protocol

su -l $username -c "sed -ie 's/.*root-stream-open =.*\#/root-stream-open = false     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*mining-requires-peers =.*\#/mining-requires-peers = true     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*initial-block-reward =.*\#/initial-block-reward = 0     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*first-block-reward =.*\#/first-block-reward = -1     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*target-adjust-freq =.*\#/target-adjust-freq = 172800     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*max-std-tx-size =.*\#/max-std-tx-size = 100000000     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*max-std-op-returns-count =.*\#/max-std-op-returns-count = 1024     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*max-std-op-return-size =.*\#/max-std-op-return-size = 8388608     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*max-std-op-drops-count =.*\#/max-std-op-drops-count = 100     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*max-std-element-size =.*\#/max-std-element-size = 32768     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*default-network-port =.*\#/default-network-port = '$networkport'     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*default-rpc-port =.*\#/default-rpc-port = '$rpcport'     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c "sed -ie 's/.*chain-name =.*\#/chain-name = '$chainname'     #/g' /home/"$username"/.multichain/$chainname/params.dat"
su -l $username -c " sed -ie 's/.*protocol-version =.*\#/protocol-version = '$protocol'     #/g' /home/"$username"/.multichain/$chainname/params.dat"

su -l $username -c "echo rpcuser='$rpcuser' > /home/$username/.multichain/$chainname/multichain.conf"
su -l $username -c "echo rpcpassword='$rpcpassword' >> /home/$username/.multichain/$chainname/multichain.conf"
su -l $username -c 'echo rpcport='$rpcport' >> /home/'$username'/.multichain/'$chainname'/multichain.conf'

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

echo '----------------------------------------'
echo -e ${CYAN}${bold}'RUNNING BLOCKCHAIN.....'${normal}${LIGHTYELLOW}
echo '----------------------------------------'

su -l $username -c 'multichaind '$chainname' -daemon'

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

echo '----------------------------------------'
echo -e ${CYAN}${bold}'LOADING CONFIGURATION.....'${normal}${LIGHTYELLOW}
echo '----------------------------------------'

sleep 6

addr=`curl --user $rpcuser:$rpcpassword --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getaddresses", "params": [] }' -H 'content-type: text/json;' http://127.0.0.1:$rpcport | jq -r '.result[0]'`

su -l $username -c  "multichain-cli "$chainname" issue "$addr" '{\"name\":\""$assetName"\", \"open\":true}' 1000000000000 0.01 0 '{\"description\":\"This is a smart asset for peer-to-peer transaction\"}'"


echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''


echo '----------------------------------------'
echo -e ${CYAN}${bold}'CREATING AND CONFIGURING STREAMS.....'${normal}${LIGHTYELLOW}
echo '----------------------------------------'


# CREATE STREAMS
# ------ -------
su -l $username -c "multichain-cli $chainname createrawsendfrom $addr '{}' '[{\"create\":\"stream\",\"name\":\"proof_of_existence\",\"open\":false,\"details\":{\"purpose\":\"Stores hashes of files\"}}]' send"

su -l $username -c  "multichain-cli "$chainname" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"users_credentials\",\"open\":false,\"details\":{\"purpose\":\"Stores Users Credentials\"}}]' send"
su -l $username -c  "multichain-cli "$chainname" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"users_details\",\"open\":false,\"details\":{\"purpose\":\"Stores Users Details\"}}]' send"
su -l $username -c  "multichain-cli "$chainname" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"users_addresses\",\"open\":false,\"details\":{\"purpose\":\"Stores addresses owned by users\"}}]' send"
su -l $username -c  "multichain-cli "$chainname" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"users_session\",\"open\":false,\"details\":{\"purpose\":\"Stores session history for users\"}}]' send"

su -l $username -c  "multichain-cli "$chainname" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"vault\",\"open\":false,\"details\":{\"purpose\":\"Stores documents uploaded by users\"}}]' send"

su -l $username -c  "multichain-cli "$chainname" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"contract_details\",\"open\":false,\"details\":{\"purpose\":\"Stores basic details of contracts\"}}]' send"
su -l $username -c  "multichain-cli "$chainname" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"contract_files\",\"open\":false,\"details\":{\"purpose\":\"Stores files related to contracts\"}}]' send"
su -l $username -c  "multichain-cli "$chainname" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"contract_signatures\",\"open\":false,\"details\":{\"purpose\":\"Stores signatures of contracts\"}}]' send"
su -l $username -c  "multichain-cli "$chainname" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"contracts_signed\",\"open\":false,\"details\":{\"purpose\":\"Stores the list of contracts signed by each user\"}}]' send"
su -l $username -c  "multichain-cli "$chainname" createrawsendfrom "$addr" '{}' '[{\"create\":\"stream\",\"name\":\"contract_invited_signees\",\"open\":false,\"details\":{\"purpose\":\"Stores the list of users invited to sign a contract\"}}]' send"


# SUBSCRIBE STREAMS
# --------- -------
su -l $username -c "multichain-cli "$chainname" subscribe proof_of_existence"

su -l $username -c  "multichain-cli "$chainname" subscribe users_credentials"
su -l $username -c  "multichain-cli "$chainname" subscribe users_details"
su -l $username -c  "multichain-cli "$chainname" subscribe users_addresses"
su -l $username -c  "multichain-cli "$chainname" subscribe users_session"

su -l $username -c  "multichain-cli "$chainname" subscribe vault"

su -l $username -c  "multichain-cli "$chainname" subscribe contract_details"
su -l $username -c  "multichain-cli "$chainname" subscribe contract_files"
su -l $username -c  "multichain-cli "$chainname" subscribe contract_signatures"
su -l $username -c  "multichain-cli "$chainname" subscribe contracts_signed"
su -l $username -c  "multichain-cli "$chainname" subscribe contract_invited_signees"



echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

echo -e ${LIGHTGREEN}${bold}'----------------------------------------'
echo -e 'BLOCKCHAIN SUCCESSFULLY SET UP!'
echo -e '----------------------------------------'${normal}${LIGHTYELLOW}


echo '----------------------------------------'
echo -e ${CYAN}${bold}'SETTING UP APPLICATIONS.....'${normal}${LIGHTYELLOW}
echo '----------------------------------------'

cp -rf $repodir/cli /var/www/html
cd /var/www/html	# Changing current directory to web server's root directory

###
## INSTALLING & CONFIGURING APPLICATIONS
###

# Configuring cli
sudo sed -ie 's/RPC_USER =.*;/RPC_USER = "'$rpcuser'";/g' /var/www/html/cli/config.php
sudo sed -ie 's/RPC_PASSWORD =.*;/RPC_PASSWORD = "'$rpcpassword'";/g' /var/www/html/cli/config.php
sudo sed -ie 's/RPC_PORT =.*;/RPC_PORT = "'$rpcport'";/g' /var/www/html/cli/config.php


###
## INSTALLING & CONFIGURING MULTICHAIN EXPLORER
###

cd /home/$username
git clone https://github.com/MultiChain/multichain-explorer.git
cd multichain-explorer
sudo python setup.py install

sudo bash -c 'cp /home/'$username'/multichain-explorer/chain1.example.conf /home/'$username'/multichain-explorer/'$chainname'.conf'

sudo sed -ie 's/MultiChain chain1/'$explorerDisplayName'/g' /home/$username/multichain-explorer/$chainname.conf
sudo sed -ie 's/2750/'$explorerport'/g' /home/$username/multichain-explorer/$chainname.conf
sudo sed -ie 's/chain1/'$chainname'/g' /home/$username/multichain-explorer/$chainname.conf
sudo sed -ie 's/host localhost.*\#/host  localhost 	#/g' /home/$username/multichain-explorer/$chainname.conf
sudo sed -ie 's/host localhost/host 0.0.0.0/g' /home/$username/multichain-explorer/$chainname.conf
sudo sed -ie 's/chain1.explorer.sqlite/'$chainname'.explorer.sqlite/g' /home/$username/multichain-explorer/$chainname.conf

su -l $username -c "python -m Mce.abe --config /home/"$username"/multichain-explorer/"$chainname".conf --commit-bytes 100000 --no-serve"
sleep 5
su -l $username -c "echo -ne '\n' | nohup python -m Mce.abe --config /home/"$username"/multichain-explorer/"$chainname".conf > /dev/null 2>/dev/null &"

# Restarting Apache to load the changes
sudo service apache2 restart

echo ''
echo ''
echo '----------------------------------------'
echo ''
echo ''
echo ''
echo ''

echo -e ${LIGHTGREEN}${bold}'----------------------------------------'
echo -e 'APPLICATIONS SUCCESSFULLY SET UP!'
echo -e '----------------------------------------'${normal}${NC}
echo ''
echo ''
echo ''
echo ''

echo -e ${normal}${CYAN}'RPC User Name - '${bold}${LIGHTYELLOW}$rpcuser
echo -e ${normal}${CYAN}'RPC Password - '${bold}${LIGHTYELLOW}$rpcpassword
echo -e ${normal}${NC}