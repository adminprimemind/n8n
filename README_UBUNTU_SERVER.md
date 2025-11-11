# n8n Ubuntu Server Setup Guide

Complete guide to set up and run n8n on Ubuntu Server (20.04, 22.04, or 24.04).

## Table of Contents

- [System Requirements](#system-requirements)
- [Prerequisites Installation](#prerequisites-installation)
- [Project Setup](#project-setup)
- [Building the Project](#building-the-project)
- [Running n8n](#running-n8n)
- [Production Deployment](#production-deployment)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

---

## System Requirements

- **Ubuntu Server**: 20.04 LTS, 22.04 LTS, or 24.04 LTS
- **Node.js**: Version 22.16 or newer
- **pnpm**: Version 10.18.3 or newer
- **RAM**: Minimum 2GB (4GB+ recommended)
- **Disk Space**: Minimum 5GB free space
- **CPU**: 2+ cores recommended

---

## Prerequisites Installation

### Step 1: Update System Packages

```bash
sudo apt update
sudo apt upgrade -y
```

### Step 2: Install Build Tools and Dependencies

n8n requires build tools to compile native modules (like sqlite3):

```bash
sudo apt install -y build-essential python3 python3-pip git curl
```

**Additional dependencies for n8n features:**

```bash
# For GraphicsMagick (image processing)
sudo apt install -y graphicsmagick

# For Git operations
sudo apt install -y git

# For SSL/TLS
sudo apt install -y ca-certificates
```

### Step 3: Install Node.js 22.x

**Option A: Using NodeSource (Recommended)**

```bash
# Install Node.js 22.x
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version  # Should show v22.16 or higher
npm --version
```

**Option B: Using nvm (Node Version Manager)**

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reload shell configuration
source ~/.bashrc

# Install Node.js 22
nvm install 22
nvm use 22
nvm alias default 22

# Verify installation
node --version
npm --version
```

### Step 4: Install pnpm

**Using corepack (Recommended - comes with Node.js):**

```bash
# Enable corepack
sudo corepack enable

# Prepare pnpm
sudo corepack prepare pnpm@10.18.3 --activate

# Verify installation
pnpm --version  # Should show 10.18.3 or higher
```

**Alternative: Using npm**

```bash
npm install -g pnpm@10.18.3
pnpm --version
```

### Step 5: Verify All Prerequisites

```bash
# Check versions
node --version   # Should be >= 22.16
npm --version
pnpm --version   # Should be >= 10.18.3

# Check build tools
gcc --version
python3 --version
```

---

## Project Setup

### Step 1: Transfer Project to Server

**Option A: Using Git (if project is in a repository)**

```bash
# Clone the repository
git clone <your-repository-url>
cd n8n-master
```

**Option B: Using SCP (from your local machine)**

```bash
# From your local machine
scp -r /path/to/n8n-master user@your-server-ip:/home/user/
```

**Option C: Using rsync (recommended for large projects)**

```bash
# From your local machine
rsync -avz --progress /path/to/n8n-master user@your-server-ip:/home/user/
```

### Step 2: Navigate to Project Directory

```bash
cd ~/n8n-master  # or wherever you placed the project
```

### Step 3: Install Dependencies

```bash
# Install all project dependencies
pnpm install

# This may take 5-15 minutes depending on your server speed
# If you encounter errors, see Troubleshooting section
```

**Note:** If `pnpm install` fails with sqlite3 errors, run:

```bash
# Rebuild native modules
pnpm rebuild sqlite3
```

### Step 4: Build the Project

```bash
# Build all packages
pnpm build

# This may take 10-20 minutes on first build
# Subsequent builds will be faster due to caching
```

**If build fails for @n8n/nodes-langchain:**

The langchain package may fail to build due to sqlite3. You can either:

1. **Fix it:**
   ```bash
   cd packages/@n8n/nodes-langchain
   pnpm rebuild sqlite3
   cd ../../..
   pnpm build
   ```

2. **Skip it (if you don't need AI/LangChain features):**
   ```bash
   # The main n8n will still work without this package
   ```

---

## Running n8n

### Development Mode

```bash
# Start n8n in development mode (with hot reload)
pnpm dev

# Or start in production mode
pnpm start
```

n8n will be accessible at: **http://your-server-ip:5678**

### Production Mode

For production, use a process manager (see Production Deployment section below).

---

## Production Deployment

### Option 1: Using PM2 (Recommended)

**Install PM2:**

```bash
npm install -g pm2
```

**Create PM2 ecosystem file:**

Create `ecosystem.config.js` in the project root:

```javascript
module.exports = {
  apps: [{
    name: 'n8n',
    script: './packages/cli/bin/n8n',
    cwd: '/home/user/n8n-master',  // Update with your actual path
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      N8N_PORT: 5678,
      N8N_PROTOCOL: 'http',
      N8N_HOST: '0.0.0.0',
      // Add other environment variables as needed
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    max_memory_restart: '1G',
  }]
};
```

**Start with PM2:**

```bash
# Create logs directory
mkdir -p logs

# Start n8n
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
# Follow the instructions provided by the command
```

**PM2 Management Commands:**

```bash
pm2 status          # Check status
pm2 logs n8n        # View logs
pm2 restart n8n      # Restart
pm2 stop n8n        # Stop
pm2 monit           # Monitor resources
```

### Option 2: Using systemd

**Create systemd service file:**

```bash
sudo nano /etc/systemd/system/n8n.service
```

Add the following content:

```ini
[Unit]
Description=n8n workflow automation
After=network.target

[Service]
Type=simple
User=your-username  # Change to your username
WorkingDirectory=/home/your-username/n8n-master  # Update path
Environment="NODE_ENV=production"
Environment="N8N_PORT=5678"
Environment="N8N_PROTOCOL=http"
Environment="N8N_HOST=0.0.0.0"
ExecStart=/usr/bin/node /home/your-username/n8n-master/packages/cli/bin/n8n start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Enable and start the service:**

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable n8n

# Start the service
sudo systemctl start n8n

# Check status
sudo systemctl status n8n

# View logs
sudo journalctl -u n8n -f
```

### Option 3: Using Docker (Alternative)

If you prefer Docker, you can build and run n8n in a container:

```bash
# Build Docker image
pnpm build:docker

# Run with Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  n8nio/n8n:latest
```

---

## Environment Variables

Create a `.env` file in the project root for configuration:

```bash
nano .env
```

**Common environment variables:**

```env
# Server Configuration
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=0.0.0.0

# Database (SQLite by default)
DB_TYPE=sqlite
DB_SQLITE_DATABASE=/home/user/n8n-data/database.sqlite
DB_SQLITE_POOL_SIZE=10

# Security
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-secure-password

# Task Runners (recommended)
N8N_RUNNERS_ENABLED=true

# Security Settings
N8N_BLOCK_ENV_ACCESS_IN_NODE=false
N8N_GIT_NODE_DISABLE_BARE_REPOS=true

# Timezone
TZ=UTC

# Production optimizations
NODE_ENV=production
N8N_METRICS=true
```

**Load environment variables:**

If using PM2, update `ecosystem.config.js` to load from `.env`:

```bash
npm install -g pm2-dotenv
```

Or manually add variables to the PM2 config.

---

## Firewall Configuration

**Allow n8n port through firewall:**

```bash
# UFW (Ubuntu Firewall)
sudo ufw allow 5678/tcp
sudo ufw reload

# Or if using iptables
sudo iptables -A INPUT -p tcp --dport 5678 -j ACCEPT
```

**For production, consider using a reverse proxy (Nginx):**

```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/n8n
```

Add:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable and restart:

```bash
sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Troubleshooting

### Issue: sqlite3 Build Failures

**Solution:**

```bash
# Install additional dependencies
sudo apt install -y libsqlite3-dev

# Rebuild sqlite3
cd packages/@n8n/nodes-langchain  # or root directory
pnpm rebuild sqlite3

# Or rebuild all native modules
pnpm rebuild
```

### Issue: Port Already in Use

**Solution:**

```bash
# Find process using port 5678
sudo lsof -i :5678
# or
sudo netstat -tulpn | grep 5678

# Kill the process
sudo kill -9 <PID>

# Or change n8n port in .env
N8N_PORT=5679
```

### Issue: Permission Denied Errors

**Solution:**

```bash
# Fix ownership
sudo chown -R $USER:$USER ~/n8n-master

# Fix permissions
chmod +x packages/cli/bin/n8n
```

### Issue: Out of Memory During Build

**Solution:**

```bash
# Increase Node.js memory limit
export NODE_OPTIONS="--max-old-space-size=4096"
pnpm build

# Or for install
NODE_OPTIONS="--max-old-space-size=4096" pnpm install
```

### Issue: pnpm Command Not Found

**Solution:**

```bash
# Re-enable corepack
sudo corepack enable
corepack prepare pnpm@10.18.3 --activate

# Or add to PATH
export PATH="$PATH:$(npm config get prefix)/bin"
```

### Issue: Build Takes Too Long

**Solution:**

```bash
# Use turbo cache (if available)
# Or build specific packages only
pnpm --filter=n8n build
```

### Issue: Cannot Access n8n from Remote

**Solution:**

1. Check firewall rules (see Firewall Configuration)
2. Verify N8N_HOST is set to `0.0.0.0` (not `localhost`)
3. Check server security groups (if using cloud provider)

---

## Maintenance

### Updating n8n

```bash
# Pull latest changes (if using git)
git pull origin main

# Reinstall dependencies
pnpm install

# Rebuild
pnpm build

# Restart service
pm2 restart n8n
# or
sudo systemctl restart n8n
```

### Backup

**Backup n8n data:**

```bash
# Create backup directory
mkdir -p ~/n8n-backups

# Backup database and workflows
cp -r ~/.n8n ~/n8n-backups/n8n-$(date +%Y%m%d-%H%M%S)

# Or if using custom data directory
cp -r /path/to/n8n-data ~/n8n-backups/n8n-$(date +%Y%m%d-%H%M%S)
```

### Logs

**View logs:**

```bash
# PM2 logs
pm2 logs n8n

# systemd logs
sudo journalctl -u n8n -f

# Application logs (if configured)
tail -f ~/n8n-data/logs/n8n.log
```

### Monitoring

**Check resource usage:**

```bash
# System resources
htop

# PM2 monitoring
pm2 monit

# Disk usage
df -h

# Process status
ps aux | grep n8n
```

---

## Quick Start Checklist

- [ ] Ubuntu Server updated
- [ ] Build tools installed (`build-essential`, `python3`)
- [ ] Node.js 22.x installed and verified
- [ ] pnpm 10.18.3+ installed and verified
- [ ] Project transferred to server
- [ ] Dependencies installed (`pnpm install`)
- [ ] Project built (`pnpm build`)
- [ ] Environment variables configured (`.env`)
- [ ] Firewall configured (port 5678)
- [ ] Process manager setup (PM2 or systemd)
- [ ] Service started and running
- [ ] n8n accessible at http://your-server-ip:5678

---

## Support

- **Documentation**: https://docs.n8n.io
- **Community Forum**: https://community.n8n.io
- **GitHub Issues**: https://github.com/n8n-io/n8n/issues

---

## Security Recommendations

1. **Use HTTPS** in production (via reverse proxy with Let's Encrypt)
2. **Enable Basic Auth** or use proper authentication
3. **Keep system updated**: `sudo apt update && sudo apt upgrade`
4. **Use firewall**: Only open necessary ports
5. **Regular backups**: Automate backup process
6. **Monitor logs**: Set up log rotation
7. **Use environment variables**: Don't hardcode secrets
8. **Limit file permissions**: Use proper user permissions

---

**Last Updated**: 2024
**n8n Version**: 1.119.0


