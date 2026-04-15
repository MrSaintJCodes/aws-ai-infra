#!/bin/bash
set -e
exec > /var/log/ollama-setup.log 2>&1
export OLLAMA_HOST="${ollama_host}:${ollama_port}"
export OLLAMA_MODELS="/var/ollama/models"

echo "=== Starting Ollama setup at $(date) ==="
sleep 10

echo "=== Updating system ==="
sudo apt-get update -y

echo "=== Installing dependencies ==="
sudo apt-get install -y curl unzip git binutils make gcc zstd nfs-common

echo "=== Installing amazon-efs-utils ==="
sudo apt-get install -y nfs-common

echo "=== Mounting Ollama EFS ==="
sudo mkdir -p /var/ollama

# Optional extra wait for network readiness
sleep 10
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "${efs_dns}":/ /var/ollama
# Fix Mounting with FSTAB
echo "${efs_dns}:/ /var/ollama nfs4 _netdev,nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" | sudo tee -a /etc/fstab

echo "=== Installing Ollama ==="
curl -fsSL https://ollama.com/install.sh | sudo sh

echo "=== Creating Ollama systemd service ==="
sudo tee /etc/systemd/system/ollama.service > /dev/null <<'SERVICE'
[Unit]
Description=Ollama AI server
After=network.target

[Service]
Type=simple
User=ollama
Environment="OLLAMA_HOST=${ollama_host}:${ollama_port}"
Environment="OLLAMA_MODELS=/var/ollama/models"
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama

echo "=== Waiting for Ollama API to be ready ==="
for i in $(seq 1 24); do
  if curl -s http://localhost:${ollama_port}/api/tags > /dev/null 2>&1; then
    echo "Ollama is ready after $${i} x 5s"
    break
  fi
  echo "Waiting... attempt $${i}"
  sleep 5
done

echo "=== Checking Ollama status ==="
sudo systemctl status ollama --no-pager

echo "=== Pulling model if not cached on EFS ==="
if [ ! -d /var/ollama/models/manifests ]; then
  echo "=== Pulling ${ollama_model} ==="
  sudo -u ollama \
    HOME=/home/ollama \
    OLLAMA_MODELS=/var/ollama/models \
    /usr/local/bin/ollama pull llama3.2
  echo "=== Model pulled successfully ==="
else
  echo "=== Model already on EFS, skipping pull ==="
fi

echo "=== Done at $(date) ==="