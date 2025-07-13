# WordPress Lando Dev Setup (WP Bascamp)

Quick development environment setup for WordPress using Lando with sensible defaults.

## Features

- Containerized development with Lando & Docker
- Secure configuration with environment variables.
- Environment-specific configuration files.
- omposer-based WordPress management
- Modern tools (WP-CLI, PHP 8.2, Nginx)
- MailHog for email testing
- PHPMyAdmin for database management
- Auto database backups on shutdown
- Bare-bones starter FSE starter theme installation ([Compass](https://github.com/builtnorth/compass.git))

### Prerequisites

- [Lando](https://lando.dev/download/)
- [OrbStack](https://orbstack.dev/) or [Docker](https://www.docker.com/)

### Installation

1. **Clone this repository:**
   ```bash
   git clone git@github.com:builtnorth/wp-lando.git project-name
   cd project-name
   ```

2. **Run the setup script:**
   ```bash
   php setup/bootstrap.php
   ```

   Or with command line arguments:
   ```bash
   php setup/bootstrap.php --name="My Project" --email="admin@example.com" --password="mypassword" --username="admin"
   ```

The setup process will:
- Check for required dependencies
- Prompt for project details (if not provided via CLI)
- Generate `.env` and `.lando.yml` files with secure salts
- Start the Lando environment
- Install all dependencies (Composer & npm)
- Install and configure WordPress
- Import media files and set site logo/icon
- Configure default pages and settings

### What's Included

After setup completes, you'll have:
- WordPress installed at `https://[project-name].lndo.site`
- Admin panel at `https://[project-name].lndo.site/wp/wp-admin`
- MailHog for email testing at `https://mail.[project-name].lndo.site`
- phpMyAdmin at `https://pma.[project-name].lndo.site`
- Automatic database backups on `lando stop`


## Structure

```
wp-lando/
├── wp/                  # WordPress core
├── wp-content/          # Themes, plugins, uploads
├── wp-config/           # WP configuration (production, staging, development)
├── setup/                # Bootstrap and setup
├── .env                # Environment variables
└── .lando.yml          # Lando config
```

## Commands

- `php setup/bootstrap.php` - Boostrap and run setup
- `lando start` - Start environment
- `lando stop` - Stop environment
- `lando wp` - WP-CLI commands
- `lando composer` - Composer commands
- `lando npm` - NPM commands


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


## Disclaimer

This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

Use of this library is at your own risk. The authors and contributors of this project are not responsible for any damage to your website or any loss of data that may result from the use of this library.

While we strive to keep this library up-to-date and secure, we make no guarantees about its performance, reliability, or suitability for any particular purpose. Users are advised to thoroughly test the library in a safe environment before deploying it to a live site.

By using this library, you acknowledge that you have read this disclaimer and agree to its terms.