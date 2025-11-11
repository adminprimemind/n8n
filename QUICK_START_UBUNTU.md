# Quick Start Guide - Ubuntu Server

## Fast Setup (Automated)

```bash
# 1. Make script executable
chmod +x setup-ubuntu.sh

# 2. Run the setup script
./setup-ubuntu.sh

# 3. Start n8n
pnpm start
```

## Manual Setup (Step by Step)

### 1. Install Prerequisites

```bash
sudo apt update
sudo apt install -y build-essential python3 python3-pip git curl graphicsmagick libsqlite3-dev
```

### 2. Install Node.js 22.x

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node --version  # Verify: should be >= 22.16
```

### 3. Install pnpm

```bash
sudo corepack enable
sudo corepack prepare pnpm@10.18.3 --activate
pnpm --version  # Verify: should be >= 10.18.3
```

### 4. Install Dependencies

```bash
cd /path/to/n8n-master
pnpm install
```

### 5. Rebuild Native Modules

```bash
pnpm rebuild sqlite3
```

### 6. Build Project

```bash
pnpm build
```

### 7. Start n8n

```bash
pnpm start
```

Access at: **http://your-server-ip:5678**

## Production Setup with PM2

### 1. Install PM2

```bash
npm install -g pm2
```

### 2. Create Config

```bash
cp ecosystem.config.js.example ecosystem.config.js
nano ecosystem.config.js  # Edit paths and passwords
```

### 3. Create Logs Directory

```bash
mkdir -p logs
```

### 4. Start with PM2

```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup  # Follow instructions to enable on boot
```

## Production Setup with systemd

### 1. Create Service File

```bash
sudo nano /etc/systemd/system/n8n.service
```

Paste:

```ini
[Unit]
Description=n8n workflow automation
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/home/YOUR_USERNAME/n8n-master
Environment="NODE_ENV=production"
Environment="N8N_PORT=5678"
Environment="N8N_HOST=0.0.0.0"
ExecStart=/usr/bin/node /home/YOUR_USERNAME/n8n-master/packages/cli/bin/n8n start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 2. Enable and Start

```bash
sudo systemctl daemon-reload
sudo systemctl enable n8n
sudo systemctl start n8n
sudo systemctl status n8n
```

## Firewall

```bash
sudo ufw allow 5678/tcp
sudo ufw reload
```

## Troubleshooting

### sqlite3 Build Error
```bash
sudo apt install -y libsqlite3-dev
pnpm rebuild sqlite3
```

### Port Already in Use
```bash
sudo lsof -i :5678
sudo kill -9 <PID>
```

### Permission Denied
```bash
sudo chown -R $USER:$USER /path/to/n8n-master
chmod +x packages/cli/bin/n8n
```

## Full Documentation

See **README_UBUNTU_SERVER.md** for complete documentation.


