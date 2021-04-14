#!/bin/bash

echo 192.168.100.60 otus-bkps >> /etc/hosts
mkdir /root/.ssh
cp /vagrant/ssh_key_c/id_rsa /root/.ssh 
cp /vagrant/ssh_key_c/id_rsa.pub /root/.ssh
touch /root/.ssh/authorized_keys
cat /vagrant/ssh_key_s/id_rsa.pub > /root/.ssh/authorized_keys
yum install -y borgbackup
#
#
scp -o StrictHostKeyChecking=no /vagrant/file otus-bkps: 
cp /vagrant/script-backup.sh /root

