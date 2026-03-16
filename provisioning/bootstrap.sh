#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

apt install -y -qq systemd-timesyncd
systemctl unmask systemd-timesyncd
systemctl enable systemd-timesyncd.service
timedatectl set-ntp true
systemctl restart systemd-timesyncd.service

#Fix SSHD
if ! grep -q "^Subsystem sftp internal-sftp" /etc/ssh/sshd_config; then
    echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config
    systemctl restart sshd
fi

SSH_PUBLIC_KEY=/vagrant/provisioning/id_rsa.pub
USER_DIR=/home/vagrant/.ssh
mkdir -p $USER_DIR
chmod 700 $USER_DIR

if [[ "$HOSTNAME" == *"-master" ]]; then
	mkdir -p /etc/ansible
	cp /vagrant/ansible.inventory /etc/ansible/hosts
	cp /vagrant/ansible.cfg /etc/ansible
	chmod 0644 /etc/ansible/hosts
	chmod 0644 /etc/ansible/ansible.cfg

	if [ ! -f $USER_DIR/id_rsa.pub ]; then
		# Create ssh keys
		echo -e 'y\n' | sudo -u vagrant ssh-keygen -t rsa -f $USER_DIR/id_rsa -q -N ''
	fi

	if [ ! -f $USER_DIR/id_rsa.pub ]; then
		echo "SSH public key could not be created"
		exit -1
	fi

	chown vagrant:vagrant $USER_DIR/id_rsa*
	cp $USER_DIR/id_rsa.pub $SSH_PUBLIC_KEY
fi

if [ ! -f $SSH_PUBLIC_KEY ]; then
	echo "SSH public key does not exist"
	exit -1
fi

touch $USER_DIR/authorized_keys 2>/dev/null
sed -i '/127.0.1.1.*packer-/d' /etc/hosts 2>/dev/null
sed -i '/127.0.2.1/d' /etc/hosts 2>/dev/null
grep -q -f $SSH_PUBLIC_KEY $USER_DIR/authorized_keys || cat $SSH_PUBLIC_KEY >> $USER_DIR/authorized_keys
chown vagrant:vagrant $USER_DIR/authorized_keys
chmod 0600 $USER_DIR/authorized_keys
