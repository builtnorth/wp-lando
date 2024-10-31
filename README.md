# WordPress Lando

Quick development environment for WordPress using Lando.

## Features

- 🐳 Containerized development with Lando
- 🔒 Secure configuration with env vars
- 📦 Composer-based WordPress management
- 🛠️ Modern tools (WP-CLI, PHP 8.2, Nginx)
- 📧 MailHog for email testing
- 📊 PHPMyAdmin included
- 🔄 Auto database backups on shutdown

## Install

1. Install required tools:
    - [Lando](https://docs.lando.dev/getting-started/installation.html)
    - [Composer](https://getcomposer.org/download/)
    - [Git](https://git-scm.com/downloads)

2. Clone and setup:
```bash
git clone https://github.com/builtnorth/wp-lando.git
cd wp-lando
```

3. Run setup script:
    - `./bin/setup.sh`
	- Follow prompts to enter site name, username, password, and email

4. Site is ready.

## Structure

```
wp-lando/
├── wp/                  # WordPress core
├── wp-content/          # Themes, plugins, uploads
├── wp-config/           # WP configuration (production, staging, development)
├── config/              # Server config
├── bin/                # Scripts
├── .env                # Environment variables
└── .lando.yml          # Lando config
```

## Commands

- `lando start` - Start environment
- `lando stop` - Stop environment
- `lando wp` - WP-CLI commands
- `lando composer` - Composer commands
- `lando npm` - NPM commands

## URLs

- Site: https://wp-lando.lndo.site
- Admin: https://wp-lando.lndo.site/wp/wp-admin
- Mail: https://mail.wp-lando.lndo.site
- PMA: https://pma.wp-lando.lndo.site

## Config

### Environment Variables

Required in `.env`:
```
WP_ENV=development
WP_HOME=https://wp-lando.lndo.site
DB_NAME=wordpress
DB_USER=wordpress
DB_PASSWORD=wordpress
```

### WordPress Config

Environment configs live in `wp-config/`. Simliar to [roots/bedrock](https://github.com/roots/bedrock), `application.php` contains the main config with the ability for `staging.php` and `development.php` to override environment specific settings.
