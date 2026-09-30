#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
#              SRNCLOUD Technologies
#          Pterodactyl Panel Installer
#
#              Installer made by
#                 NegativeTier
#
#              Debian 13 (Trixie)
# ============================================================

VERSION="1.1.0"

PANEL_DIR="/var/www/pterodactyl"
PANEL_DOMAIN=""
ADMIN_EMAIL=""
ADMIN_USERNAME=""
ADMIN_FIRSTNAME=""
ADMIN_LASTNAME=""
ADMIN_PASSWORD=""

DB_NAME="panel"
DB_USER="pterodactyl"
DB_PASSWORD=""

LOCAL_PORT="8443"

CF_ENABLE="false"
CF_TOKEN=""

PHP_VERSION="8.3"

# ============================================================
# Colors
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ============================================================
# Functions
# ============================================================

info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

die() {
    error "$1"
    exit 1
}

step() {
    echo
    echo -e "${CYAN}${BOLD}==> $1${RESET}"
    echo
}

# ------------------------------------------------------------
# IMPORTANT:
# Read interactive input from /dev/tty so that:
#
# curl ... | bash
#
# works correctly.
# ------------------------------------------------------------

ask() {
    local prompt="$1"
    local variable="$2"
    local value

    if [[ ! -r /dev/tty ]]; then
        die "Interactive terminal (/dev/tty) is unavailable. Run this script from an interactive SSH terminal."
    fi

    read -r -p "$prompt" value </dev/tty
    printf -v "$variable" '%s' "$value"
}

ask_secret() {
    local prompt="$1"
    local variable="$2"
    local value

    if [[ ! -r /dev/tty ]]; then
        die "Interactive terminal (/dev/tty) is unavailable."
    fi

    read -r -s -p "$prompt" value </dev/tty
    echo
    printf -v "$variable" '%s' "$value"
}

confirm() {
    local prompt="$1"
    local answer

    if [[ ! -r /dev/tty ]]; then
        die "Interactive terminal (/dev/tty) is unavailable."
    fi

    read -r -p "$prompt" answer </dev/tty
    echo "$answer"
}

trap 'error "Installation failed on line $LINENO."' ERR

# ============================================================
# Banner
# ============================================================

clear 2>/dev/null || true

echo -e "${CYAN}"

cat <<'EOF'

███████╗██████╗ ███╗   ██╗ ██████╗██╗      ██████╗ ██╗   ██╗██████╗
██╔════╝██╔══██╗████╗  ██║██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
███████╗██████╔╝██╔██╗ ██║██║     ██║     ██║   ██║██║   ██║██║  ██║
╚════██║██╔══██╗██║╚██╗██║██║     ██║     ██║   ██║██║   ██║██║  ██║
███████║██████╔╝██║ ╚████║╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
╚══════╝╚═════╝ ╚═╝  ╚═══╝ ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝

EOF

echo -e "${RESET}"

echo -e "${BOLD}        Pterodactyl Panel Easy Installer${RESET}"
echo
echo -e "        ${GREEN}Installer made by NegativeTier${RESET}"
echo -e "        ${CYAN}From SRNCLOUD Technologies${RESET}"
echo
echo "        Version: $VERSION"
echo "        Target : Debian 13 (Trixie)"
echo

# ============================================================
# Root
# ============================================================

if [[ "$EUID" -ne 0 ]]; then
    die "Run this installer as root."
fi

# ============================================================
# OS
# ============================================================

step "Checking operating system"

if [[ ! -f /etc/os-release ]]; then
    die "Cannot detect operating system."
fi

source /etc/os-release

if [[ "${ID:-}" != "debian" ]]; then
    die "This installer requires Debian."
fi

if [[ "${VERSION_CODENAME:-}" != "trixie" ]]; then
    die "Debian 13 Trixie is required. Detected: ${VERSION_CODENAME:-unknown}"
fi

success "Debian 13 Trixie detected."

# ============================================================
# Architecture
# ============================================================

ARCH="$(dpkg --print-architecture)"

if [[ "$ARCH" != "amd64" ]]; then
    die "This installer currently supports amd64 only."
fi

success "Architecture: $ARCH"

# ============================================================
# Network
# ============================================================

step "Checking network connectivity"

if ! ip route get 1.1.1.1 >/dev/null 2>&1; then
    die "No working IPv4 route detected."
fi

if ! getent hosts github.com >/dev/null 2>&1; then
    die "DNS resolution is not working."
fi

success "Network connectivity is working."

# ============================================================
# Panel Configuration
# ============================================================

step "Panel configuration"

ask "Panel domain (example: panel.example.com): " PANEL_DOMAIN

[[ -n "$PANEL_DOMAIN" ]] ||
    die "Panel domain cannot be empty."

if [[ "$PANEL_DOMAIN" =~ [/:[:space:]] ]]; then
    die "Enter only the hostname, for example: panel.example.com"
fi

if [[ ! "$PANEL_DOMAIN" =~ ^[A-Za-z0-9.-]+$ ]]; then
    die "Invalid domain name."
fi

ask "Admin email: " ADMIN_EMAIL

[[ -n "$ADMIN_EMAIL" ]] ||
    die "Admin email cannot be empty."

if [[ ! "$ADMIN_EMAIL" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; then
    die "Invalid email address."
fi

ask "Admin username: " ADMIN_USERNAME

[[ -n "$ADMIN_USERNAME" ]] ||
    die "Admin username cannot be empty."

ask "Admin first name: " ADMIN_FIRSTNAME

[[ -n "$ADMIN_FIRSTNAME" ]] ||
    die "First name cannot be empty."

ask "Admin last name: " ADMIN_LASTNAME

[[ -n "$ADMIN_LASTNAME" ]] ||
    die "Last name cannot be empty."

ask_secret "Admin password: " ADMIN_PASSWORD

[[ ${#ADMIN_PASSWORD} -ge 8 ]] ||
    die "Admin password must be at least 8 characters."

# Pterodactyl requires mixed case + number.
if [[ ! "$ADMIN_PASSWORD" =~ [A-Z] ]]; then
    die "Admin password must contain at least one uppercase letter."
fi

if [[ ! "$ADMIN_PASSWORD" =~ [a-z] ]]; then
    die "Admin password must contain at least one lowercase letter."
fi

if [[ ! "$ADMIN_PASSWORD" =~ [0-9] ]]; then
    die "Admin password must contain at least one number."
fi

# ============================================================
# Cloudflare
# ============================================================

echo

CF_ANSWER="$(confirm "Enable Cloudflare Tunnel? [y/N]: ")"

if [[ "$CF_ANSWER" =~ ^[Yy]$ ]]; then

    CF_ENABLE="true"

    echo
    echo "Paste your Cloudflare Tunnel token."
    echo "The token will not be stored in this script."
    echo

    ask_secret "Cloudflare Tunnel Token: " CF_TOKEN

    [[ -n "$CF_TOKEN" ]] ||
        die "Cloudflare Tunnel token cannot be empty."
fi

# ============================================================
# Generate Database Password
# ============================================================

DB_PASSWORD="$(openssl rand -hex 24)"

[[ -n "$DB_PASSWORD" ]] ||
    die "Could not generate database password."

# ============================================================
# Summary
# ============================================================

echo
echo -e "${BOLD}Installation Summary${RESET}"
echo "------------------------------------------"
echo "Panel Domain : https://$PANEL_DOMAIN"
echo "Local Origin : https://127.0.0.1:$LOCAL_PORT"
echo "Admin Email  : $ADMIN_EMAIL"
echo "Database     : $DB_NAME"
echo "DB User      : $DB_USER"
echo "Cloudflare   : $CF_ENABLE"
echo "------------------------------------------"
echo

CONFIRM="$(confirm "Continue installation? [Y/n]: ")"

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo
    warn "Installation cancelled."
    exit 0
fi

# ============================================================
# System Update
# ============================================================

step "Updating Debian"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y

# ============================================================
# Base Dependencies
# ============================================================

step "Installing base dependencies"

apt-get install -y \
    ca-certificates \
    curl \
    wget \
    gnupg \
    gnupg2 \
    unzip \
    tar \
    git \
    nginx \
    mariadb-server \
    redis-server \
    cron \
    openssl \
    lsb-release \
    apt-transport-https \
    software-properties-common

success "Base dependencies installed."

# ============================================================
# PHP Repository
# ============================================================

step "Configuring PHP 8.3 repository"

install -d -m 0755 /etc/apt/keyrings

curl -fsSL \
    https://packages.sury.org/php/apt.gpg \
    -o /etc/apt/keyrings/sury-php.gpg

chmod 0644 /etc/apt/keyrings/sury-php.gpg

cat > /etc/apt/sources.list.d/php.list <<EOF
deb [signed-by=/etc/apt/keyrings/sury-php.gpg] https://packages.sury.org/php/ trixie main
EOF

apt-get update

success "PHP repository configured."

# ============================================================
# PHP
# ============================================================

step "Installing PHP $PHP_VERSION"

apt-get install -y \
    "php${PHP_VERSION}" \
    "php${PHP_VERSION}-cli" \
    "php${PHP_VERSION}-common" \
    "php${PHP_VERSION}-gd" \
    "php${PHP_VERSION}-mysql" \
    "php${PHP_VERSION}-mbstring" \
    "php${PHP_VERSION}-bcmath" \
    "php${PHP_VERSION}-xml" \
    "php${PHP_VERSION}-fpm" \
    "php${PHP_VERSION}-curl" \
    "php${PHP_VERSION}-zip"

success "PHP $PHP_VERSION installed."

php -v

# ============================================================
# Services
# ============================================================

step "Starting required services"

systemctl enable --now mariadb
systemctl enable --now redis-server
systemctl enable --now nginx
systemctl enable --now "php${PHP_VERSION}-fpm"
systemctl enable --now cron

success "MariaDB started."
success "Redis started."
success "Nginx started."
success "PHP-FPM started."
success "Cron started."

# ============================================================
# Composer
# ============================================================

step "Installing Composer 2"

if ! command -v composer >/dev/null 2>&1; then

    curl -fsSL \
        https://getcomposer.org/installer \
        -o /tmp/composer-setup.php

    php /tmp/composer-setup.php \
        --install-dir=/usr/local/bin \
        --filename=composer

    rm -f /tmp/composer-setup.php
fi

composer self-update --2 >/dev/null 2>&1 || true

success "Composer installed."

composer --version

# ============================================================
# Database
# ============================================================

step "Creating Pterodactyl database"

mariadb <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1'
    IDENTIFIED BY '${DB_PASSWORD}';

ALTER USER '${DB_USER}'@'127.0.0.1'
    IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES
    ON \`${DB_NAME}\`.*
    TO '${DB_USER}'@'127.0.0.1';

FLUSH PRIVILEGES;
EOF

success "Database configured."

# ============================================================
# Download Pterodactyl
# ============================================================

step "Downloading Pterodactyl Panel"

mkdir -p "$PANEL_DIR"

cd "$PANEL_DIR"

rm -f panel.tar.gz

curl -fL \
    --retry 3 \
    --retry-delay 2 \
    -o panel.tar.gz \
    https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz

tar -xzf panel.tar.gz

rm -f panel.tar.gz

success "Pterodactyl Panel downloaded."

# ============================================================
# Permissions Before Composer
# ============================================================

chmod -R 755 \
    "$PANEL_DIR/storage" \
    "$PANEL_DIR/bootstrap/cache"

# ============================================================
# Composer Dependencies
# ============================================================

step "Installing Pterodactyl dependencies"

cp -f .env.example .env

COMPOSER_ALLOW_SUPERUSER=1 \
composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction \
    --no-progress

success "Pterodactyl dependencies installed."

# ============================================================
# Application Key
# ============================================================

step "Generating application key"

php artisan key:generate --force

success "Application key generated."

# ============================================================
# Environment
# ============================================================

step "Configuring Pterodactyl environment"

php artisan p:environment:setup \
    -n \
    --author="$ADMIN_EMAIL" \
    --url="https://$PANEL_DOMAIN" \
    --timezone="UTC" \
    --cache="redis" \
    --session="redis" \
    --queue="redis" \
    --redis-host="127.0.0.1" \
    --redis-pass="" \
    --redis-port="6379"

php artisan p:environment:database \
    -n \
    --host="127.0.0.1" \
    --port="3306" \
    --database="$DB_NAME" \
    --username="$DB_USER" \
    --password="$DB_PASSWORD"

# Trust local reverse proxy / tunnel.
if grep -q '^TRUSTED_PROXIES=' .env; then
    sed -i 's/^TRUSTED_PROXIES=.*/TRUSTED_PROXIES=127.0.0.1/' .env
else
    echo 'TRUSTED_PROXIES=127.0.0.1' >> .env
fi

success "Pterodactyl environment configured."

# ============================================================
# Database Migration
# ============================================================

step "Migrating Pterodactyl database"

php artisan migrate --seed --force

success "Database migration completed."

# ============================================================
# Admin Account
# ============================================================

step "Creating administrator account"

php artisan p:user:make \
    -n \
    --email="$ADMIN_EMAIL" \
    --username="$ADMIN_USERNAME" \
    --name-first="$ADMIN_FIRSTNAME" \
    --name-last="$ADMIN_LASTNAME" \
    --password="$ADMIN_PASSWORD" \
    --admin=1

success "Administrator account created."

# ============================================================
# Permissions
# ============================================================

step "Configuring Panel permissions"

chown -R www-data:www-data "$PANEL_DIR"

chmod -R 755 \
    "$PANEL_DIR/storage" \
    "$PANEL_DIR/bootstrap/cache"

success "Panel permissions configured."

# ============================================================
# Local TLS Certificate
# ============================================================

step "Creating local HTTPS certificate"

mkdir -p /etc/nginx/ssl/pterodactyl

openssl req \
    -x509 \
    -nodes \
    -newkey rsa:2048 \
    -days 825 \
    -keyout /etc/nginx/ssl/pterodactyl/panel.key \
    -out /etc/nginx/ssl/pterodactyl/panel.crt \
    -subj "/CN=$PANEL_DOMAIN" \
    -addext "subjectAltName=DNS:$PANEL_DOMAIN,DNS:localhost,IP:127.0.0.1"

chmod 600 \
    /etc/nginx/ssl/pterodactyl/panel.key

chmod 644 \
    /etc/nginx/ssl/pterodactyl/panel.crt

success "Local TLS certificate created."

# ============================================================
# Nginx
# ============================================================

step "Configuring Nginx"

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/pterodactyl.conf

cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 127.0.0.1:${LOCAL_PORT} ssl;
    server_name ${PANEL_DOMAIN};

    root ${PANEL_DIR}/public;
    index index.php;

    ssl_certificate /etc/nginx/ssl/pterodactyl/panel.crt;
    ssl_certificate_key /etc/nginx/ssl/pterodactyl/panel.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "same-origin" always;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;

        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;

        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";

        fastcgi_intercept_errors off;

        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;

        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;

        fastcgi_param PHP_VALUE "upload_max_filesize=100M
post_max_size=100M";
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf \
    /etc/nginx/sites-available/pterodactyl.conf \
    /etc/nginx/sites-enabled/pterodactyl.conf

nginx -t

systemctl restart nginx

success "Nginx configured on 127.0.0.1:${LOCAL_PORT}."

# ============================================================
# Queue Worker
# ============================================================

step "Configuring Pterodactyl queue worker"

cat > /etc/systemd/system/pteroq.service <<'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service
Wants=redis-server.service

[Service]
User=www-data
Group=www-data

Restart=always
RestartSec=5

ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

StartLimitInterval=180
StartLimitBurst=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now pteroq.service

success "Pterodactyl queue worker enabled."

# ============================================================
# Cron
# ============================================================

step "Configuring Panel scheduler"

CRON_LINE="* * * * * php ${PANEL_DIR}/artisan schedule:run >> /dev/null 2>&1"

CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

if ! grep -Fq "$CRON_LINE" <<< "$CURRENT_CRON"; then
    {
        printf '%s\n' "$CURRENT_CRON"
        printf '%s\n' "$CRON_LINE"
    } | crontab -
fi

success "Panel scheduler configured."

# ============================================================
# Cloudflare Tunnel
# ============================================================

if [[ "$CF_ENABLE" == "true" ]]; then

    step "Installing Cloudflare Tunnel"

    mkdir -p /usr/share/keyrings

    curl -fsSL \
        https://pkg.cloudflare.com/cloudflare-main.gpg \
        -o /usr/share/keyrings/cloudflare-main.gpg

    chmod 0644 /usr/share/keyrings/cloudflare-main.gpg

    cat > /etc/apt/sources.list.d/cloudflared.list <<EOF
deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main
EOF

    apt-get update
    apt-get install -y cloudflared

    success "cloudflared installed."

    step "Installing Cloudflare Tunnel service"

    cloudflared service uninstall >/dev/null 2>&1 || true

    cloudflared service install "$CF_TOKEN"

    systemctl enable cloudflared
    systemctl restart cloudflared

    success "Cloudflare Tunnel service installed."

    echo
    echo -e "${YELLOW}${BOLD}Cloudflare configuration${RESET}"
    echo
    echo "Public hostname:"
    echo "  $PANEL_DOMAIN"
    echo
    echo "Service URL:"
    echo "  https://localhost:${LOCAL_PORT}"
    echo
    echo "Origin Server Name:"
    echo "  $PANEL_DOMAIN"
    echo
    echo "Because this installer creates a self-signed local"
    echo "certificate, Cloudflare Tunnel must either trust"
    echo "the certificate through a CA pool or temporarily"
    echo "use:"
    echo
    echo "  Disable TLS Verification = ON"
    echo
    echo "Cloudflare documents originServerName and noTLSVerify"
    echo "for HTTPS origins."
    echo

fi

# ============================================================
# Local HTTPS Test
# ============================================================

step "Testing local HTTPS"

if curl \
    -k \
    -fsS \
    --resolve "${PANEL_DOMAIN}:${LOCAL_PORT}:127.0.0.1" \
    "https://${PANEL_DOMAIN}:${LOCAL_PORT}/" \
    >/dev/null; then

    success "Local HTTPS endpoint is responding."

else

    warn "Local HTTPS endpoint did not return a successful response."

fi

# ============================================================
# Service Health
# ============================================================

step "Running service health checks"

FAILED=0

SERVICES=(
    mariadb
    redis-server
    "php${PHP_VERSION}-fpm"
    nginx
    pteroq
    cron
)

if [[ "$CF_ENABLE" == "true" ]]; then
    SERVICES+=(cloudflared)
fi

for SERVICE in "${SERVICES[@]}"; do

    if systemctl is-active --quiet "$SERVICE"; then
        success "$SERVICE is running"
    else
        error "$SERVICE is NOT running"
        FAILED=1
    fi

done

# ============================================================
# Save Installation Information
# ============================================================

step "Saving installation information"

cat > /root/pterodactyl-install-info.txt <<EOF
============================================================
Pterodactyl Installation Information
============================================================

Installer:
NegativeTier
SRNCLOUD Technologies

Panel:
https://${PANEL_DOMAIN}

Local Origin:
https://127.0.0.1:${LOCAL_PORT}

Database:
Database: ${DB_NAME}
Username: ${DB_USER}
Password: ${DB_PASSWORD}

Admin:
Username: ${ADMIN_USERNAME}
Email: ${ADMIN_EMAIL}

============================================================
IMPORTANT
============================================================

APP_KEY:
${PANEL_DIR}/.env

BACK UP YOUR APP_KEY.

Never expose:
- APP_KEY
- Database password
- Admin password
- Cloudflare Tunnel token

============================================================
EOF

chmod 600 /root/pterodactyl-install-info.txt

success "Installation information saved."

# ============================================================
# Final
# ============================================================

echo

echo -e "${GREEN}${BOLD}"
echo "============================================================"
echo "       PTERODACTYL PANEL INSTALLATION COMPLETE"
echo "============================================================"
echo -e "${RESET}"

echo
echo -e "${BOLD}Panel:${RESET}"
echo "https://${PANEL_DOMAIN}"

echo
echo -e "${BOLD}Local origin:${RESET}"
echo "https://127.0.0.1:${LOCAL_PORT}"

echo
echo -e "${BOLD}Admin:${RESET}"
echo "$ADMIN_USERNAME"

echo
echo -e "${BOLD}Credentials file:${RESET}"
echo "/root/pterodactyl-install-info.txt"

if [[ "$CF_ENABLE" == "true" ]]; then
    echo
    echo -e "${BOLD}Cloudflare Tunnel:${RESET}"
    echo "Enabled"

    echo
    echo -e "${BOLD}Cloudflare service:${RESET}"
    echo "https://localhost:${LOCAL_PORT}"

    echo
    echo -e "${YELLOW}Cloudflare dashboard:${RESET}"
    echo "Public hostname : $PANEL_DOMAIN"
    echo "Service         : https://localhost:${LOCAL_PORT}"
    echo "Origin Server Name : $PANEL_DOMAIN"
fi

echo

if [[ "$FAILED" -eq 0 ]]; then
    success "All required services are running."
else
    warn "One or more services need attention."
    echo
    echo "Check with:"
    echo
    echo "systemctl status mariadb redis-server nginx pteroq"
fi

echo
echo "============================================================"
echo "        Installer made by NegativeTier"
echo "        From SRNCLOUD Technologies"
echo "============================================================"
echo
