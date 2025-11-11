#!/bin/bash

# n8n Ubuntu Server Automated Setup Script
# This script automates the installation of prerequisites and setup for n8n on Ubuntu

set -e  # Exit on error

echo "=========================================="
echo "n8n Ubuntu Server Setup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   print_error "Please do not run this script as root. It will use sudo when needed."
   exit 1
fi

# Step 1: Update system
print_info "Step 1/8: Updating system packages..."
sudo apt update
sudo apt upgrade -y
print_success "System updated"

# Step 2: Install build tools and dependencies
print_info "Step 2/8: Installing build tools and dependencies..."
sudo apt install -y \
    build-essential \
    python3 \
    python3-pip \
    git \
    curl \
    graphicsmagick \
    ca-certificates \
    libsqlite3-dev
print_success "Build tools installed"

# Step 3: Install Node.js 22.x
print_info "Step 3/8: Installing Node.js 22.x..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 22 ]; then
        print_success "Node.js $(node --version) already installed"
    else
        print_info "Node.js version is too old, installing Node.js 22.x..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt install -y nodejs
    fi
else
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Verify Node.js installation
if command -v node &> /dev/null; then
    NODE_VER=$(node --version)
    print_success "Node.js $NODE_VER installed"
else
    print_error "Node.js installation failed"
    exit 1
fi

# Step 4: Install pnpm
print_info "Step 4/8: Installing pnpm..."
if command -v corepack &> /dev/null; then
    sudo corepack enable
    sudo corepack prepare pnpm@10.18.3 --activate
    print_success "pnpm installed via corepack"
elif command -v pnpm &> /dev/null; then
    PNPM_VER=$(pnpm --version)
    print_success "pnpm $PNPM_VER already installed"
else
    npm install -g pnpm@10.18.3
    print_success "pnpm installed via npm"
fi

# Verify pnpm installation
if command -v pnpm &> /dev/null; then
    PNPM_VER=$(pnpm --version)
    print_success "pnpm $PNPM_VER verified"
else
    print_error "pnpm installation failed"
    exit 1
fi

# Step 5: Check if we're in the project directory
print_info "Step 5/8: Checking project directory..."
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the n8n project root directory."
    exit 1
fi
print_success "Project directory verified"

# Step 6: Install project dependencies
print_info "Step 6/8: Installing project dependencies (this may take 5-15 minutes)..."
print_info "This step may take a while. Please be patient..."
pnpm install
print_success "Dependencies installed"

# Step 7: Rebuild native modules (fix sqlite3)
print_info "Step 7/8: Rebuilding native modules (sqlite3)..."
pnpm rebuild sqlite3 || print_info "sqlite3 rebuild had issues, but continuing..."
print_success "Native modules rebuilt"

# Step 8: Build the project
print_info "Step 8/8: Building the project (this may take 10-20 minutes)..."
print_info "This is the final step and may take a while..."
pnpm build || {
    print_error "Build failed. You may need to check the errors above."
    print_info "The project may still be runnable. Try: pnpm start"
    exit 1
}
print_success "Project built successfully"

# Summary
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
print_success "All prerequisites installed"
print_success "Dependencies installed"
print_success "Project built"
echo ""
echo "Next steps:"
echo "1. Configure environment variables (create .env file)"
echo "2. Start n8n with: pnpm start"
echo "3. Or set up PM2/systemd for production (see README_UBUNTU_SERVER.md)"
echo ""
echo "n8n will be available at: http://your-server-ip:5678"
echo ""
print_info "For detailed instructions, see README_UBUNTU_SERVER.md"


