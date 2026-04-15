#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "=== Starting user_data at $(date) ==="

sleep 10

echo "=== Installing dependencies ==="
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y libapache2-mod-wsgi-py3
sudo apt-get install -y \
  apache2 \
  apache2-dev \
  git \
  python3 \
  python3-pip \
  python3-dev \
  gcc \
  nfs-common \
  stunnel4

echo "=== Installing amazon-efs-utils ==="
sudo apt-get install -y nfs-common

echo "=== Mounting EFS ==="
sudo mkdir -p /var/www/html
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "${efs_dns}":/ /var/www/html
echo "${efs_dns}:/ /var/www/html nfs4 _netdev,nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" | sudo tee -a /etc/fstab
  
echo "=== Setting permissions ==="
sudo chmod 755 /var/www/
sudo chown www-data:www-data /var/www/

sudo mkdir -p /var/www/ai_chat
echo "=== Cloning Django app - ${web_git_repo} ==="
if [ ! -d "/var/www/ai_chat/.git" ]; then
  #sudo rm -rf /var/www/ai_chat
  sudo git clone "https://github.com/MrSaintJCodes/ai-chat.git" /var/www/ai_chat
else
  cd /var/www/ai_chat && sudo git pull
fi

echo "=== Installing app Python dependencies ==="
pip3 install -r /var/www/ai_chat/ai_chat/requirements.txt

echo "=== Running Django migrations ==="
cd /var/www/ai_chat/ai_chat
sudo -E \
  DJANGO_SETTINGS_MODULE=ai_chat.settings \
  DJANGO_SECRET_KEY="${django_secret_key}" \
  DB_HOST="${db_host}" \
  DB_NAME="${db_name}" \
  DB_USER="${db_user}" \
  DB_PASS="${db_pass}" \
  OLLAMA_HOST="${ollama_host}" \
  OLLAMA_MODEL="${ollama_model}" \
  python3 manage.py migrate --noinput

echo "=== Collecting static files ==="
sudo -E \
  DJANGO_SETTINGS_MODULE=ai_chat.settings \
  DJANGO_SECRET_KEY="${django_secret_key}" \
  DB_HOST="${db_host}" \
  DB_NAME="${db_name}" \
  DB_USER="${db_user}" \
  DB_PASS="${db_pass}" \
  OLLAMA_HOST="${ollama_host}" \
  OLLAMA_MODEL="${ollama_model}" \
  python3 manage.py collectstatic --noinput

echo "=== Setting permissions ==="
sudo chown -R www-data:www-data /var/www/ai_chat

echo "=== Configuring Apache mod_wsgi ==="
sudo tee /etc/apache2/sites-available/ai_chat.conf > /dev/null <<APACHEEOF
<VirtualHost *:80>
    DocumentRoot /var/www/ai_chat

    WSGIDaemonProcess ai_chat \
        python-path=/var/www/ai_chat/ai_chat \
        processes=2 \
        threads=4 \
        environment="DJANGO_SETTINGS_MODULE=ai_chat.settings" \
        environment="DJANGO_SECRET_KEY=${django_secret_key}" \
        environment="DB_HOST=${db_host}" \
        environment="DB_NAME=${db_name}" \
        environment="DB_USER=${db_user}" \
        environment="DB_PASS=${db_pass}" \
        environment="OLLAMA_HOST=${ollama_host}" \
        environment="OLLAMA_MODEL=${ollama_model}" \
        environment="ALB_DNS=${alb_dns}"

    WSGIProcessGroup  ai_chat
    WSGIScriptAlias / /var/www/ai_chat/ai_chat/ai_chat/wsgi.py

    <Directory /var/www/ai_chat/ai_chat/ai_chat>
        <Files wsgi.py>
            Require all granted
        </Files>
    </Directory>

    Alias /static/ /var/www/ai_chat/ai_chat/static/
    <Directory /var/www/ai_chat/ai_chat/static>
        Require all granted
    </Directory>

    ErrorLog  /var/log/apache2/ai_chat-error.log
    CustomLog /var/log/apache2/ai_chat-access.log combined
</VirtualHost>
'''
sudo tee /etc/apache2/sites-available/ai_chat.conf > /dev/null <<APACHEEOF
<VirtualHost *:80>
    DocumentRoot /var/www/ai_chat/ai_chat

    WSGIDaemonProcess ai_chat \\
        python-path=/var/www/ai_chat/ai_chat \\
        processes=2 \\
        threads=4
    WSGIProcessGroup  ai_chat
    WSGIScriptAlias / /var/www/ai_chat/ai_chat/ai_chat/wsgi.py

    SetEnv DJANGO_SETTINGS_MODULE ai_chat.settings
    SetEnv DJANGO_SECRET_KEY      ${django_secret_key}
    SetEnv DB_HOST                ${db_host}
    SetEnv DB_NAME                ${db_name}
    SetEnv DB_USER                ${db_user}
    SetEnv DB_PASS                ${db_pass}
    SetEnv OLLAMA_HOST            ${ollama_host}
    SetEnv OLLAMA_MODEL           ${ollama_model}
    SetEnv ALB_DNS                ${alb_dns}

    <Directory /var/www/ai_chat/ai_chat/ai_chat>
        <Files wsgi.py>
            Require all granted
        </Files>
    </Directory>

    Alias /static/ /var/www/ai_chat/ai_chat/static/
    <Directory /var/www/ai_chat/ai_chat/static>
        Require all granted
    </Directory>

    ErrorLog  /var/log/apache2/ai_chat-error.log
    CustomLog /var/log/apache2/ai_chat-access.log combined
</VirtualHost>
APACHEEOF
'''
sudo a2enmod wsgi
sudo a2dissite 000-default
sudo a2ensite ai_chat
sudo systemctl enable apache2
sudo systemctl restart apache2