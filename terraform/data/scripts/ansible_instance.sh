#!/bin/bash
set -e
exec > /var/log/ansible-setup.log 2>&1

echo "=== Starting user_data at $(date) ==="
sleep 10

echo "=== Installing Ansible ==="
sudo yum update -y
sudo yum install -y python3 python3-pip git
sudo pip3 install ansible boto3 botocore

# Install AWS EC2 dynamic inventory plugin
ansible-galaxy collection install amazon.aws

echo "=== Ansible ready ==="

echo "=== Cloning Ansible Repo ==="
sudo yum install -y git
sudo mkdir -p /home/ec2-user/ansible
sudo chown ec2-user:ec2-user /home/ec2-user/ansible
sudo chmod 755 /home/ec2-user/ansible

git clone https://github.com/MrSaintJCodes/aws-sysadmin-lab.git /home/ec2-user/ansible

echo "=== Done at $(date) ==="