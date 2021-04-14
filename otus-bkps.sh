#!/bin/bash

echo 192.168.100.61 otus-bkpc >> /etc/hosts
mkdir /root/.ssh
cp /vagrant/ssh_key_s/id_rsa /root/.ssh 
cp /vagrant/ssh_key_s/id_rsa.pub /root/.ssh 
touch /root/.ssh/authorized_keys
cat /vagrant/ssh_key_c/id_rsa.pub > /root/.ssh/authorized_keys
yum install -y borgbackup
mkdir /var/backup
