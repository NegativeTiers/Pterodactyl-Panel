# 🚀 Pterodactyl Panel Easy Installer

### ⚡ Automated Pterodactyl Panel + HTTPS + Cloudflare Tunnel Installer

> **Installer made by NegativeTier**
> **From SRNCLOUD Technologies**

[![Debian](https://img.shields.io/badge/Debian-13%20Trixie-A81D33?style=for-the-badge\&logo=debian\&logoColor=white)](https://www.debian.org/)
[![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Panel-000000?style=for-the-badge\&logo=pterodactyl\&logoColor=white)](https://pterodactyl.io/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-Tunnel-F38020?style=for-the-badge\&logo=cloudflare\&logoColor=white)](https://www.cloudflare.com/)
[![Bash](https://img.shields.io/badge/Language-Bash-121011?style=for-the-badge\&logo=gnu-bash\&logoColor=white)](https://www.gnu.org/software/bash/)

---

## 📖 About

**Pterodactyl Panel Easy Installer** is an automated Bash installer designed to make deploying the **Pterodactyl Panel** on Debian simple and fast.

The installer handles the main requirements automatically, including:

* PHP
* MariaDB
* Redis
* Nginx
* Composer
* Pterodactyl Panel
* Database configuration
* HTTPS
* Queue worker
* Scheduler
* Cloudflare Tunnel

The goal is simple:

> **Run one installer → configure Pterodactyl → connect Cloudflare → start managing your servers.**

---

# ✨ Features

### 🐧 Operating System

* Debian 13 (Trixie) detection
* amd64 architecture validation
* Network and DNS checks
* Automatic package updates

### 🦖 Pterodactyl Panel

* Latest Pterodactyl Panel release
* Automatic Composer installation
* Automatic `.env` configuration
* Database creation
* Database migrations
* Admin account creation
* Correct storage permissions

### 🗄️ Database & Cache

* MariaDB
* Redis
* Automatic database/user creation
* Secure randomly generated database password

### 🌐 Nginx

* Automatic Nginx installation
* Local-only origin
* HTTPS enabled
* TLS certificate generation
* PHP-FPM configuration
* Upload size configuration

### ☁️ Cloudflare Tunnel

Optional Cloudflare Tunnel support:

```text
Internet
   │
   ▼
Cloudflare
   │
   ▼
Cloudflare Tunnel
   │
   ▼
HTTPS localhost:8443
   │
   ▼
Nginx
   │
   ▼
Pterodactyl Panel
```

This allows the Panel origin to remain bound to localhost instead of exposing Nginx directly to the public internet.

### ⚙️ Background Services

Automatically configures:

```text
pteroq.service
cron
PHP-FPM
MariaDB
Redis
Nginx
cloudflared
```

---

# 📋 Requirements

| Requirement  | Details                             |
| ------------ | ----------------------------------- |
| OS           | Debian 13 Trixie                    |
| Architecture | amd64                               |
| Access       | Root                                |
| RAM          | Recommended 2 GB+                   |
| Storage      | Recommended 20 GB+                  |
| Network      | Working IPv4 + DNS                  |
| Domain       | Required for HTTPS/Cloudflare setup |

> ⚠️ A fresh Debian installation is strongly recommended.

---

# 🚀 Installation

## 1️⃣ Download & Run

### Curl

```bash
curl -fsSL https://raw.githubusercontent.com/NegativeTiers/Pterodactyl-Installer/main/install-pterodactyl.sh | bash
```

### Wget

```bash
wget -qO- https://raw.githubusercontent.com/NegativeTiers/Pterodactyl-Installer/main/install-pterodactyl.sh | bash
```

---

# 🧙 Installer Setup

During installation, the script will ask for:

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

---

# ☁️ Cloudflare Tunnel Setup

If you select:

```text
Enable Cloudflare Tunnel? [y/N]: y
```

the installer will ask for your Cloudflare Tunnel token.

The token is **not stored inside the GitHub repository**.

The installer then installs `cloudflared` and configures it as a system service.

---

## Cloudflare Origin

After installation, configure the Tunnel public hostname in Cloudflare:

```text
Hostname:
panel.example.com

Service:
https://localhost:8443
```

### Origin Settings

Because the installer creates a local self-signed certificate, configure the Cloudflare origin to allow the self-signed certificate.

```text
TLS
└── No TLS Verify
       ON
```

> ⚠️ Do not publish your Cloudflare Tunnel token. Anyone who has the token may be able to run the tunnel connector.

---

# 🔐 HTTPS Architecture

The installer does **not** expose the local Nginx HTTPS listener publicly.

It listens on:

```text
127.0.0.1:8443
```

Architecture:

```text
                   INTERNET
                       │
                       ▼
                ┌─────────────┐
                │  Cloudflare │
                └──────┬──────┘
                       │
                       ▼
                ┌─────────────┐
                │ cloudflared │
                └──────┬──────┘
                       │
                 HTTPS :8443
                       │
                       ▼
                ┌─────────────┐
                │    Nginx    │
                │ 127.0.0.1   │
                └──────┬──────┘
                       │
                       ▼
                ┌─────────────┐
                │ Pterodactyl │
                │    Panel    │
                └─────────────┘
```

---

# 🌐 Panel Access

After Cloudflare is configured:

```text
https://panel.example.com
```

Login using the administrator account created during installation.

---

# 🛠️ Installed Components

The installer configures:

```text
Pterodactyl Panel
PHP 8.3
PHP-FPM
MariaDB
Redis
Nginx
Composer 2
Cron
Cloudflared (optional)
```

---

# ⚙️ Service Management

### Pterodactyl Queue

```bash
systemctl status pteroq
```

Restart:

```bash
systemctl restart pteroq
```

---

### Nginx

```bash
systemctl status nginx
```

Restart:

```bash
systemctl restart nginx
```

---

### MariaDB

```bash
systemctl status mariadb
```

---

### Redis

```bash
systemctl status redis-server
```

---

### Cloudflare Tunnel

```bash
systemctl status cloudflared
```

Restart:

```bash
systemctl restart cloudflared
```

---

# 🔍 Troubleshooting

## Check Pterodactyl

```bash
cd /var/www/pterodactyl

php artisan about
```

## Check Pterodactyl logs

```bash
tail -f /var/www/pterodactyl/storage/logs/laravel.log
```

## Check Nginx

```bash
nginx -t
```

## Check Nginx logs

```bash
journalctl -u nginx --no-pager -n 50
```

## Check queue worker

```bash
journalctl -u pteroq --no-pager -n 50
```

## Check Cloudflare

```bash
journalctl -u cloudflared --no-pager -n 50
```

## Check local HTTPS

```bash
curl -k https://127.0.0.1:8443
```

---

# 🔑 Installation Information

The installer stores installation information at:

```text
/root/pterodactyl-install-info.txt
```

This contains:

```text
Panel URL
Database name
Database username
Database password
Admin username
```

### ⚠️ Keep this file private.

It contains sensitive credentials.

Permissions are automatically set to:

```text
600
```

---

# 🔐 APP_KEY

Your Pterodactyl application key is stored in:

```text
/var/www/pterodactyl/.env
```

### ⚠️ NEVER delete or expose your `APP_KEY`.

Always back it up before migrating or reinstalling the Panel.

---

# 🧹 Uninstall

This installer does **not** provide an automatic uninstall command.

This is intentional because removing Pterodactyl, MariaDB, Redis, and Nginx automatically could destroy existing server data.

If you want to remove the installation, manually review the services and data before deleting anything.

---

# 🐛 Reporting Issues

If you encounter an issue:

1. Check the troubleshooting commands above.
2. Check the service logs.
3. Make sure you're using Debian 13.
4. Make sure DNS is configured correctly.
5. Open a GitHub issue.

Please include:

```text
Debian version
Architecture
Pterodactyl version
Error message
Relevant logs
```

**Do not post:**

```text
Cloudflare Tunnel Token
Database Password
APP_KEY
Admin Password
Private Keys
```

---

# 📂 Repository

### GitHub

**NegativeTiers/Pterodactyl-Installer**

```text
https://github.com/NegativeTiers/Pterodactyl-Installer
```

### Installer

```text
install-pterodactyl.sh
```

---

# ⭐ Support the Project

If this installer helped you deploy Pterodactyl:

⭐ **Star the repository**

🐛 **Report bugs**

💡 **Suggest improvements**

🔧 **Submit pull requests**

---

# 🏢 Credits

## Installer made by NegativeTier

### From SRNCLOUD Technologies

Built for simple, fast and automated Pterodactyl deployments.

---

# 📜 Disclaimer

This is a third-party installation script and is not an official Pterodactyl or Cloudflare product.

Always review scripts before executing them on production infrastructure.

Use this installer at your own risk and maintain regular backups of your Panel and database.

---

<p align="center">

### ⚡ Built by NegativeTier

### 🏢 SRNCLOUD Technologies

**Simple • Fast • Automated**

</p>
