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

VERSION="1.0.0"

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
# Domain / Admin configuration
# ============================================================

step "Panel configuration"

read -rp "Panel domain (example: panel.example.com): " PANEL_DOMAIN

[[ -n "$PANEL_DOMAIN" ]] || die "Panel domain cannot be empty."

if [[ "$PANEL_DOMAIN" =~ [/:[:space:]] ]]; then
    die "Enter only the hostname, e.g. panel.example.com"
fi

read -rp "Admin email: " ADMIN_EMAIL
[[ -n "$ADMIN_EMAIL" ]] || die "Admin email cannot be empty."

read -rp "Admin username: " ADMIN_USERNAME
[[ -n "$ADMIN_USERNAME" ]] || die "Admin username cannot be empty."

read -rp "Admin first name: " ADMIN_FIRSTNAME
[[ -n "$ADMIN_FIRSTNAME" ]] || die "First name cannot be empty."

read -rp "Admin last name: " ADMIN_LASTNAME
[[ -n "$ADMIN_LASTNAME" ]] || die "Last name cannot be empty."

read -rsp "Admin password: " ADMIN_PASSWORD
echo

[[ ${#ADMIN_PASSWORD} -ge 8 ]] ||
    die "Admin password must be at least 8 characters."

# ============================================================
# Cloudflare
# ============================================================

echo
read -rp "Enable Cloudflare Tunnel? [y/N]: " CF_ANSWER

if [[ "$CF_ANSWER" =~ ^[Yy]$ ]]; then

    CF_ENABLE="true"

    echo
    echo "Paste your Cloudflare Tunnel token."
    echo "The token is NOT saved in this script."
    echo

    read -rsp "Cloudflare Tunnel Token: " CF_TOKEN
    echo

    [[ -n "$CF_TOKEN" ]] ||
        die "Cloudflare Tunnel token cannot be empty."

fi

# ============================================================
# Database password
# ============================================================

DB_PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"

# ============================================================
# Confirmation
# ============================================================

echo
echo -e "${BOLD}Installation Summary${RESET}"
echo "------------------------------------------"
echo "Panel Domain : https://$PANEL_DOMAIN"
echo "Panel Port   : localhost:$LOCAL_PORT"
echo "Admin Email  : $ADMIN_EMAIL"
echo "Database     : $DB_NAME"
echo "DB User      : $DB_USER"
echo "Cloudflare   : $CF_ENABLE"
echo "------------------------------------------"
echo

read -rp "Continue installation? [Y/n]: " CONFIRM

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# ============================================================
# Network
# ============================================================

step "Checking network"

if ! ip route get 1.1.1.1 >/dev/null 2>&1; then
    die "No working IPv4 route detected."
fi

if ! getent hosts github.com >/dev/null 2>&1; then
    die "DNS resolution is not working."
fi

success "Network is working."

# ============================================================
# System update
# ============================================================

step "Updating Debian"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y

# ============================================================
# Dependencies
# ============================================================

step "Installing Pterodactyl dependencies"

apt-get install -y \
    ca-certificates \
    curl \
    wget \
    gnupg \
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
    software-properties-common \
    php8.3 \
    php8.3-cli \
    php8.3-common \
    php8.3-gd \
    php8.3-mysql \
    php8.3-mbstring \
    php8.3-bcmath \
    php8.3-xml \
    php8.3-fpm \
    php8.3-curl \
    php8.3-zip

success "Dependencies installed."

# ============================================================
# Composer
# ============================================================

step "Installing Composer"

if ! command -v composer >/dev/null 2>&1; then

    curl -fsSL https://getcomposer.org/installer \
        | php -- \
        --install-dir=/usr/local/bin \
        --filename=composer

fi

composer self-update --2 >/dev/null 2>&1 || true

success "Composer installed."

composer --version

# ============================================================
# Services
# ============================================================

step "Starting services"

systemctl enable --now mariadb
systemctl enable --now redis-server
systemctl enable --now nginx
systemctl enable --now php8.3-fpm
systemctl enable --now cron

success "MariaDB started."
success "Redis started."
success "Nginx started."
success "PHP-FPM started."

# ============================================================
# Database
# ============================================================

step "Creating Pterodactyl database"

mariadb <<EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD';
ALTER USER '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF

success "Database configured."

# ============================================================
# Download Panel
# ============================================================

step "Downloading Pterodactyl Panel"

mkdir -p "$PANEL_DIR"

cd "$PANEL_DIR"

curl -fL \
    -o panel.tar.gz \
    https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz

tar -xzf panel.tar.gz

rm -f panel.tar.gz

chmod -R 755 storage bootstrap/cache

success "Pterodactyl Panel downloaded."

# ============================================================
# Composer dependencies
# ============================================================

step "Installing Panel dependencies"

cp .env.example .env

COMPOSER_ALLOW_SUPERUSER=1 \
composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction \
    --no-progress

success "Panel dependencies installed."

# ============================================================
# Application key
# ============================================================

step "Generating application key"

php artisan key:generate --force

success "Application encryption key generated."

# ============================================================
# Pterodactyl environment
# ============================================================

step "Configuring Panel environment"

php artisan p:environment:setup \
    -n \
    --author="$ADMIN_EMAIL" \
    --url="https://$PANEL_DOMAIN" \
    --timezone="UTC" \
    --cache="redis" \
    --session="redis" \
    --queue="redis" \
    --redis-host="127.0.0.1" \
    --redis-pass="null" \
    --redis-port="6379"

php artisan p:environment:database \
    --host="127.0.0.1" \
    --port="3306" \
    --database="$DB_NAME" \
    --username="$DB_USER" \
    --password="$DB_PASSWORD"

success "Panel environment configured."

# ============================================================
# Database migration
# ============================================================

step "Migrating Pterodactyl database"

php artisan migrate --seed --force

success "Database migration completed."

# ============================================================
# Create Admin
# ============================================================

step "Creating administrator account"

php artisan p:user:make \
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

step "Configuring file permissions"

chown -R www-data:www-data "$PANEL_DIR"

chmod -R 755 \
    "$PANEL_DIR/storage" \
    "$PANEL_DIR/bootstrap/cache"

success "Permissions configured."

# ============================================================
# Local TLS certificate
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

chmod 600 /etc/nginx/ssl/pterodactyl/panel.key
chmod 644 /etc/nginx/ssl/pterodactyl/panel.crt

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
# Pterodactyl queue
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

success "Queue worker enabled."

# ============================================================
# Cron
# ============================================================

step "Configuring Panel scheduler"

CRON_LINE="* * * * * php ${PANEL_DIR}/artisan schedule:run >> /dev/null 2>&1"

if ! crontab -l 2>/dev/null | grep -Fq "$CRON_LINE"; then
    (
        crontab -l 2>/dev/null || true
        echo "$CRON_LINE"
    ) | crontab -
fi

success "Panel scheduler configured."

# ============================================================
# Cloudflare
# ============================================================

if [[ "$CF_ENABLE" == "true" ]]; then

    step "Installing Cloudflare Tunnel"

    mkdir -p /usr/share/keyrings

    curl -fsSL \
        https://pkg.cloudflare.com/cloudflare-main.gpg \
        | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
        > /etc/apt/sources.list.d/cloudflared.list

    apt-get update
    apt-get install -y cloudflared

    success "cloudflared installed."

    step "Installing Cloudflare Tunnel service"

    cloudflared service uninstall >/dev/null 2>&1 || true

    cloudflared service install "$CF_TOKEN"

    systemctl enable cloudflared
    systemctl restart cloudflared

    success "Cloudflare Tunnel service installed."

    # --------------------------------------------------------
    # Configure origin settings
    #
    # Cloudflare's dashboard route should point to:
    #
    # https://localhost:8443
    #
    # Because this origin uses a self-signed certificate,
    # enable "No TLS Verify" for the origin in Cloudflare.
    # --------------------------------------------------------

    echo
    warn "Cloudflare origin configuration:"
    echo
    echo "Service URL:"
    echo "https://localhost:${LOCAL_PORT}"
    echo
    echo "In Cloudflare Tunnel > Public Hostname:"
    echo "  Hostname : ${PANEL_DOMAIN}"
    echo "  Service  : https://localhost:${LOCAL_PORT}"
    echo
    echo "Because the local certificate is self-signed,"
    echo "set TLS -> No TLS Verify = ON for this origin."
    echo

fi

# ============================================================
# Final checks
# ============================================================

step "Running final health checks"

FAILED=0

SERVICES=(
    mariadb
    redis-server
    php8.3-fpm
    nginx
    pteroq
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

# Local HTTPS check
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
# Save credentials
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

Back up the APP_KEY from:

${PANEL_DIR}/.env

Never lose your APP_KEY.

============================================================
EOF

chmod 600 /root/pterodactyl-install-info.txt

# ============================================================
# Final
# ============================================================

echo
echo -e "${GREEN}${BOLD}"
echo "============================================================"
echo "       PTERODACTYL PANEL INSTALLATION COMPLETE"
echo "============================================================"
echo -e "${RESET}"

echo "Panel:"
echo "https://${PANEL_DOMAIN}"

echo
echo "Local origin:"
echo "https://127.0.0.1:${LOCAL_PORT}"

echo
echo "Admin:"
echo "$ADMIN_USERNAME"

echo
echo "Installation information:"
echo "/root/pterodactyl-install-info.txt"

if [[ "$CF_ENABLE" == "true" ]]; then
    echo
    echo "Cloudflare Tunnel:"
    echo "Enabled"
    echo
    echo "Cloudflare origin:"
    echo "https://localhost:${LOCAL_PORT}"
fi

echo

if [[ "$FAILED" -eq 0 ]]; then
    success "All required services are running."
else
    warn "One or more services need attention."
fi

echo
echo "============================================================"
echo "        Installer made by NegativeTier"
echo "        From SRNCLOUD Technologies"
echo "============================================================"
echo
