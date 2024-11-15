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

## WIP

- The `./bin/export.sh` has not been fully tested. Not reccomend for use on production (or anywhere really).
- The `./bin/import.sh` does not currently work.

## Disclaimer

This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

Use of this library is at your own risk. The authors and contributors of this project are not responsible for any damage to your website or any loss of data that may result from the use of this library.

While we strive to keep this library up-to-date and secure, we make no guarantees about its performance, reliability, or suitability for any particular purpose. Users are advised to thoroughly test the library in a safe environment before deploying it to a live site.

By using this library, you acknowledge that you have read this disclaimer and agree to its terms.