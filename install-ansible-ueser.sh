#!/bin/bash
# Copyright 2020 Mattia Moscheni

IPMASTER=`echo $SSH_CLIENT | cut -d ' ' -f 1`

IPMASTER="https://raw.githubusercontent.com/moscheIT/ansible-playbook/master/id_rsa"

if [ "$1" != "" ]; then
  IPMASTER=$1
fi

grep ansible /etc/passwd 1>/dev/null 2>/dev/null
if [ "$?" != "0" ]; then
  echo -n $"Create ansible user:"
  /usr/sbin/useradd -m ansible && echo "success" || echo "failure"
  echo
fi

if [ ! -d /home/ansible ]; then
  echo $"ERROR: no ansible home directory found!"
  exit 1
fi

echo -n $"Change password of ansible user:"
password=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13`
echo "ansible:$password" | chpasswd && echo "success" || echo "failure"
echo

echo -n $"Change password age of ansible user:"
chage -I -1 -m 0 -M 99999 -E -1 ansible && echo "success" || echo "failure"
echo

grep "ansible" /etc/sudoers 1>/dev/null 2>/dev/null
if [ "$?" != "0" ]; then
  echo -n $"Configure sudoers for ansible user:"
  echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible
  echo
fi

echo -n $"Disable default requiretty in sudoers:"
sed -i "s/Defaults requiretty/# Defaults requiretty/g" /etc/sudoers && echo "success" || echo "failure"
echo

if [ ! -d /home/ansible/.ssh ]; then
  echo -n $"Install rsa public key for ansible:"
  curl -s $IPMASTER -o /tmp/id_rsa.pub
  mkdir /home/ansible/.ssh
  chmod 700 /home/ansible/.ssh
  cp /tmp/id_rsa.pub /home/ansible/.ssh/authorized_keys
  chmod 600 /home/ansible/.ssh/authorized_keys
  chown -R ansible.ansible /home/ansible/.ssh
  rm -rf /tmp/id_rsa.pub
  echo "success"
  echo
fi
