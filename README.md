# 🚀 Pterodactyl Panel Easy Installer

### Automated Pterodactyl Panel + HTTPS + Cloudflare Tunnel

> **Installer made by NegativeTier**
> **From SRNCLOUD Technologies**

[![Debian](https://img.shields.io/badge/Debian-13%20Trixie-A81D33?style=for-the-badge\&logo=debian\&logoColor=white)](https://www.debian.org/)
[![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Panel-000000?style=for-the-badge\&logo=pterodactyl\&logoColor=white)](https://pterodactyl.io/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-Tunnel-F38020?style=for-the-badge\&logo=cloudflare\&logoColor=white)](https://www.cloudflare.com/)
[![Bash](https://img.shields.io/badge/Bash-Script-121011?style=for-the-badge\&logo=gnu-bash\&logoColor=white)](https://www.gnu.org/software/bash/)

---

## 📖 About

**Pterodactyl Panel Easy Installer** is a Bash-based installer created to simplify the deployment of the **Pterodactyl Panel** on a fresh Debian 13 server.

It automates the majority of the setup process, including:

* PHP
* MariaDB
* Redis
* Nginx
* Composer
* Pterodactyl Panel
* Database configuration
* Admin account
* Queue worker
* Cron scheduler
* Local HTTPS
* Cloudflare Tunnel
* Service health checks

### 🎯 Goal

```text
Fresh Debian
     ↓
Run Installer
     ↓
Pterodactyl Panel
     ↓
Local HTTPS
     ↓
Cloudflare Tunnel
     ↓
Secure Panel Access
```

---

# ✨ Features

## 🐧 Debian

* Debian 13 (Trixie) validation
* amd64 architecture check
* Network validation
* DNS validation
* Automatic system update

## 🦖 Pterodactyl Panel

* Downloads the latest Panel release
* Composer 2 installation
* Automatic `.env` configuration
* Application key generation
* Database migration
* Administrator account creation
* File permissions

## 🗄️ Database

* MariaDB
* Automatic database creation
* Automatic database user
* Randomly generated database password
* Redis support

## 🌐 Nginx

* Nginx installation
* PHP-FPM configuration
* Local-only listener
* HTTPS support
* TLS certificate generation
* 100 MB upload support

The local Panel listens on:

```text
127.0.0.1:8443
```

---

# ☁️ Cloudflare Tunnel

Cloudflare Tunnel is optional.

During installation:

```text
Enable Cloudflare Tunnel? [y/N]:
```

Choose:

```text
y
```

The installer will ask for your Cloudflare Tunnel token.

The token is entered interactively and is **not hard-coded into the GitHub script**.

### Architecture

```text
                  INTERNET
                      │
                      ▼
              ┌──────────────┐
              │  CLOUDFLARE  │
              └──────┬───────┘
                     │
                     ▼
              ┌──────────────┐
              │ cloudflared  │
              └──────┬───────┘
                     │
              HTTPS :8443
                     │
                     ▼
              ┌──────────────┐
              │    NGINX     │
              │ 127.0.0.1    │
              └──────┬───────┘
                     │
                     ▼
              ┌──────────────┐
              │ PTERODACTYL  │
              │    PANEL     │
              └──────────────┘
```

---

# 🚀 Installation

## One Command

### Curl

```bash
curl -fsSL https://raw.githubusercontent.com/NegativeTiers/Pterodactyl-Panel/main/pterodactyl.sh | bash
```

### Wget

```bash
wget -qO- https://raw.githubusercontent.com/NegativeTiers/Pterodactyl-Panel/main/pterodactyl.sh | bash
```

---

# 📋 Requirements

| Requirement      | Details                                    |
| ---------------- | ------------------------------------------ |
| Operating System | Debian 13 Trixie                           |
| Architecture     | amd64                                      |
| Access           | Root                                       |
| Internet         | Required                                   |
| IPv4             | Required                                   |
| DNS              | Required                                   |
| Domain           | Required for normal HTTPS/Cloudflare setup |
| RAM              | 2 GB+ recommended                          |
| Storage          | 20 GB+ recommended                         |

> ⚠️ **Fresh Debian installation is strongly recommended.**

---

# 🧙 Installation Process

The installer asks for:

```text
Panel domain
Admin email
Admin username
Admin first name
Admin last name
Admin password
Cloudflare Tunnel
Cloudflare Tunnel Token
```

Example:

```text
Panel domain:
panel.example.com

Admin email:
admin@example.com

Admin username:
admin

Admin first name:
Negative

Admin last name:
Tier
```

The installer then generates a secure random MariaDB password automatically.

---

# 🔐 HTTPS

The installer creates a local TLS certificate and configures Nginx to listen only on:

```text
127.0.0.1:8443
```

The generated certificate is stored at:

```text
/etc/nginx/ssl/pterodactyl/
```

The Nginx configuration uses:

```text
TLS 1.2
TLS 1.3
```

and the Panel is not directly bound to the public interface.

---

# 🌎 Cloudflare Configuration

After installation, configure your Cloudflare Tunnel public hostname.

### Public hostname

```text
panel.example.com
```

### Service

```text
https://localhost:8443
```

Because this installer creates a local self-signed certificate, configure the Cloudflare origin to accept that certificate.

> ⚠️ Keep your Cloudflare Tunnel token private. Never commit it to GitHub.

---

# ⚙️ Services

The installer configures the following services:

```text
mariadb
redis-server
php8.3-fpm
nginx
pteroq
cron
cloudflared (optional)
```

The installer also performs a final health check for these services.

---

# 🔧 Useful Commands

## Pterodactyl Queue

```bash
systemctl status pteroq
```

Restart:

```bash
systemctl restart pteroq
```

Logs:

```bash
journalctl -u pteroq --no-pager -n 50
```

---

## Nginx

```bash
systemctl status nginx
```

Test configuration:

```bash
nginx -t
```

Restart:

```bash
systemctl restart nginx
```

---

## MariaDB

```bash
systemctl status mariadb
```

---

## Redis

```bash
systemctl status redis-server
```

---

## PHP-FPM

```bash
systemctl status php8.3-fpm
```

---

## Cloudflare Tunnel

```bash
systemctl status cloudflared
```

Restart:

```bash
systemctl restart cloudflared
```

Logs:

```bash
journalctl -u cloudflared --no-pager -n 50
```

---

# 🔍 Pterodactyl Logs

Panel logs:

```bash
tail -f /var/www/pterodactyl/storage/logs/laravel.log
```

Check Panel:

```bash
cd /var/www/pterodactyl
php artisan about
```

---

# 🌐 Test Local HTTPS

The local origin can be tested with:

```bash
curl -k https://127.0.0.1:8443
```

The installer also performs its own HTTPS health check before finishing.

---

# 📁 Important Files

### Pterodactyl

```text
/var/www/pterodactyl
```

### Environment

```text
/var/www/pterodactyl/.env
```

### Nginx

```text
/etc/nginx/sites-available/pterodactyl.conf
```

### TLS

```text
/etc/nginx/ssl/pterodactyl/
```

### Installation information

```text
/root/pterodactyl-install-info.txt
```

---

# 🔑 APP_KEY

Your Pterodactyl `APP_KEY` is stored inside:

```text
/var/www/pterodactyl/.env
```

### ⚠️ IMPORTANT

**Never expose or delete your APP_KEY.**

Back it up securely before performing migrations or reinstallations.

---

# 🛡️ Security

This installer changes system-level configuration.

It can modify:

* APT packages
* Nginx
* PHP-FPM
* MariaDB
* Redis
* Cron
* Systemd services
* `/var/www/pterodactyl`
* TLS configuration

Review the script before running it on an existing production server.

---

# 🐛 Troubleshooting

### Check all major services

```bash
systemctl status \
mariadb \
redis-server \
php8.3-fpm \
nginx \
pteroq
```

### Check Nginx

```bash
nginx -t
```

### Check Panel

```bash
cd /var/www/pterodactyl
php artisan about
```

### Check Laravel logs

```bash
tail -100 /var/www/pterodactyl/storage/logs/laravel.log
```

### Check queue

```bash
journalctl -u pteroq -n 100 --no-pager
```

### Check Cloudflare

```bash
journalctl -u cloudflared -n 100 --no-pager
```

---

# 📂 Repository

### GitHub

**NegativeTiers/Pterodactyl-Panel**

```text
https://github.com/NegativeTiers/Pterodactyl-Panel
```

### Installer

```text
https://raw.githubusercontent.com/NegativeTiers/Pterodactyl-Panel/main/pterodactyl.sh
```

---

# 🤝 Contributing

Pull requests, bug reports and improvements are welcome.

Before opening an issue, please provide:

```text
Debian version
Architecture
Error message
Relevant logs
Pterodactyl version
```

### Never include:

```text
Cloudflare Tunnel Token
Database Password
Admin Password
APP_KEY
Private Keys
```

---

# ⭐ Support

If this installer helped you:

⭐ Star the repository

🐛 Report bugs

💡 Suggest improvements

🔧 Submit pull requests

---

# 🏢 Credits

## Installer made by NegativeTier

### From SRNCLOUD Technologies

Built with the goal of making Pterodactyl deployment:

**Simple • Fast • Automated**

---

# ⚠️ Disclaimer

This is an independent third-party installation script.

It is **not an official Pterodactyl or Cloudflare installer**.

Always review scripts before running them on production infrastructure and maintain regular backups.

---

<p align="center">

## ⚡ NegativeTier

### SRNCLOUD Technologies

**Pterodactyl • Automation • Infrastructure**

</p>
