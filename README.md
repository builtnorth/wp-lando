# WordPress Lando Dev Setup (WP Basecamp)

Quick development environment setup for WordPress using Lando with sensible defaults.

## Features

- Containerized development with Lando & Docker
- Secure configuration with environment variables
- Environment-specific configuration files
- Composer-based WordPress management
- Modern tools (WP-CLI, PHP 8.2, Nginx)
- MailHog for email testing
- phpMyAdmin for database management
- Auto database backups on shutdown
- Media import with automatic site logo/icon configuration

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
- Check for required dependencies (Lando)
- Prompt for project details (if not provided via CLI)
- Generate `.env` and `.lando.yml` files with secure salts
- Start the Lando environment
- Install all dependencies (Composer & npm)
- Install and configure WordPress
- Import any XML content files from `setup/data/content/`
- Import all images from `setup/data/images/` (auto-detects logo/icon)
- Configure pages and settings based on imported content

### What's Included

After setup completes, you'll have:
- WordPress installed at `https://[project-name].lndo.site`
- Admin panel at `https://[project-name].lndo.site/wp/wp-admin`
- MailHog for email testing at `https://mail.[project-name].lndo.site`
- phpMyAdmin at `https://pma.[project-name].lndo.site`
- Automatic database backups on `lando stop`


## Project Structure (After Setup)

```
project-name/
├── setup/               # Setup scripts and data
│   ├── bootstrap.php    # Initial setup script
│   ├── setup.php        # WP-CLI basecamp command
│   └── data/            # Setup resources (optional)
│       ├── content/     # XML content files to import
│       ├── images/      # Images to import (logo/icon auto-detected)
│       └── themes/      # Custom theme folders to install
├── wp/                  # WordPress core files (composer managed)
├── wp-content/          # WordPress content directory
│   ├── themes/          # WordPress themes
│   ├── plugins/         # WordPress plugins
│   ├── mu-plugins/      # Must-use plugins
│   └── uploads/         # Media uploads
├── wp-config/           # WordPress configuration
│   ├── application.php  # Main config file
│   └── environments/    # Environment-specific configs
├── .env                 # Environment variables (generated)
├── .env.example         # Environment template
├── .lando.yml           # Lando configuration (generated)
├── .lando.example.yml   # Lando template
├── composer.json        # PHP dependencies
├── package.json         # Node dependencies
└── wp-cli.yml           # WP-CLI configuration
```

## Commands

### Setup Commands
- `php setup/bootstrap.php` - Initial project setup (run once)
- `lando wp basecamp` - WordPress setup command (called by bootstrap.php)

### Development Commands
- `lando start` - Start the development environment
- `lando stop` - Stop environment (creates database backup)
- `lando rebuild` - Rebuild containers
- `lando wp` - Run WP-CLI commands
- `lando composer` - Run Composer commands
- `lando npm` - Run NPM commands in Node container
- `lando node` - Access Node directly
- `lando db` - Access MySQL CLI

### Useful WP-CLI Commands
```bash
# Create a new user
lando wp user create username email@example.com --role=administrator

# Update plugins
lando wp plugin update --all

# Export database
lando wp db export backup.sql

# Search and replace URLs
lando wp search-replace 'old-url.com' 'new-url.com'
```

## Configuration

### Environment Variables

The `.env` file is automatically generated during setup with secure salts. Key variables:

```bash
# Environment type
WP_ENV=development

# URLs (automatically set based on project name)
WP_HOME=https://[project-name].lndo.site
WP_SITEURL=https://[project-name].lndo.site/wp

# Database credentials (Lando defaults)
DB_NAME=wordpress
DB_USER=wordpress
DB_PASSWORD=wordpress
DB_HOST=database

# Salts (automatically generated)
AUTH_KEY='...'
SECURE_AUTH_KEY='...'
# ... etc
```

### WordPress Configuration

Environment configs live in `wp-config/`. Similar to [roots/bedrock](https://github.com/roots/bedrock), but uses the [builtnorth/wp-config](https://github.com/builtnorth/wp-config.git) composer package:
- `application.php` - Main configuration file
- `environments/development.php` - Development-specific settings
- `environments/staging.php` - Staging-specific settings
- `environments/production.php` - Production-specific settings

## Customizing Setup Content

The setup process is flexible and adapts to available content:

### Theme Installation
Themes are handled in priority order:
1. **Composer packages** - If theme packages are found in composer.json
2. **Custom themes** - Place theme folders in `setup/data/themes/`
3. **Default theme** - Only installs twentytwenty* if no themes exist

To include a custom theme, simply place the entire theme folder in `setup/data/themes/` before running setup.

### Content Import
- Place WordPress export files (`.xml`) in `setup/data/content/`
- All XML files in this directory will be imported
- Default WordPress content is only removed if you provide replacement content

### Media Import  
- Place images in `setup/data/images/`
- Supports: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`
- Files with "logo" in the name → set as site logo
- Files with "icon" in the name → set as site icon
- All other images are imported to the media library

### Plugin Management
- Plugins are managed via composer.json only
- All plugins found in wp-content/plugins/ will be activated
- No default plugins are installed

### No Content Provided?
If no content, themes, or media files are provided:
- WordPress default content remains (Hello World, Sample Page)
- A default twentytwenty* theme is installed
- No media is imported
- Basic WordPress installation is completed

## Troubleshooting

**Database connection issues during setup**
- The setup script waits up to 2 minutes for the database to be ready
- If issues persist, try `lando rebuild` and run setup again

**NPM not available**
- The node service may not have started properly
- Run `lando rebuild` to ensure all services are running
- Manually run `lando npm install` and `lando npm run build` if needed

**Lando commands not working**
- Ensure you're in the project directory
- Check that Lando is running: `lando list`
- Verify Docker/OrbStack is running

## License
GNU General Public License v2.0 or later


## Disclaimer

This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

Use of this library is at your own risk. The authors and contributors of this project are not responsible for any damage to your website or any loss of data that may result from the use of this library.

While we strive to keep this library up-to-date and secure, we make no guarantees about its performance, reliability, or suitability for any particular purpose. Users are advised to thoroughly test the library in a safe environment before deploying it to a live site.

By using this library, you acknowledge that you have read this disclaimer and agree to its terms.