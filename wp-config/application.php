<?php

/**
 * Base Configuration File
 *
 * This file contains production-ready defaults. Environment-specific
 * overrides should go in their respective config/environments/{{WP_ENV}}.php file.
 *
 * @package BuiltNorth\WPConfig
 */

use BuiltNorth\WPConfig\Config;

use function Env\env;

use Dotenv\Dotenv;

/**
 * Environment Variable Handling
 */
Env\Env::$options = 31; // USE_ENV_ARRAY + CONVERT_* + STRIP_QUOTES

/**
 * Directory Setup
 */
$root_dir = dirname(__DIR__);
$webroot_dir = $root_dir;

/**
 * Load Environment Files
 *
 * Loads .env files in order:
 * 1. .env.shared (version controlled, shared defaults)
 * 2. .env.local (local overrides, not version controlled)
 * 3. .env (environment-specific, not version controlled)
 */
if (file_exists($root_dir . '/.env')) {
	$env_files = file_exists($root_dir . '/.env.local')
		? ['.env', '.env.local']
		: ['.env'];

	$dotenv = Dotenv::createImmutable($root_dir, $env_files, false);
	$dotenv->load();

	// Required variables
	$dotenv->required(['WP_HOME', 'WP_ENV']);
	if (!env('DATABASE_URL')) {
		$dotenv->required(['DB_NAME', 'DB_USER', 'DB_PASSWORD']);
	}
}

/**
 * Set up our global environment constant and load its config first
 * Default: production
 */
Config::define('WP_ENV', env('WP_ENV') ?: 'production');

/**
 * Infer WP_ENVIRONMENT_TYPE based on WP_ENV
 */
if (!env('WP_ENVIRONMENT_TYPE') && in_array(Config::get('WP_ENV'), ['production', 'staging', 'development', 'local'])) {
	Config::define('WP_ENVIRONMENT_TYPE', Config::get('WP_ENV'));
}

/**
 * URLs
 */
Config::define('WP_HOME', env('WP_HOME'));
Config::define('WP_SITEURL', env('WP_SITEURL') ?: env('WP_HOME') . '/wp');

/**
 * Custom Content Directory
 */
Config::define('CONTENT_DIR', '/wp-content');
Config::define('WP_CONTENT_DIR', $webroot_dir . Config::get('CONTENT_DIR'));
Config::define('WP_CONTENT_URL', Config::get('WP_HOME') . Config::get('CONTENT_DIR'));

/**
 * DB settings
 */
if (env('DATABASE_URL')) {
	$dsn = (object) parse_url(env('DATABASE_URL'));
	Config::define('DB_NAME', substr($dsn->path, 1));
	Config::define('DB_USER', $dsn->user);
	Config::define('DB_PASSWORD', isset($dsn->pass) ? $dsn->pass : null);
	Config::define('DB_HOST', isset($dsn->port) ? "{$dsn->host}:{$dsn->port}" : $dsn->host);
} else {
	Config::define('DB_NAME', env('DB_NAME'));
	Config::define('DB_USER', env('DB_USER'));
	Config::define('DB_PASSWORD', env('DB_PASSWORD'));
	Config::define('DB_HOST', env('DB_HOST') ?: 'localhost');
}

Config::define('DB_CHARSET', 'utf8mb4');
Config::define('DB_COLLATE', '');
$table_prefix = env('DB_PREFIX') ?: 'wp_';

/**
 * Authentication Unique Keys and Salts
 */
Config::define('AUTH_KEY', env('AUTH_KEY'));
Config::define('SECURE_AUTH_KEY', env('SECURE_AUTH_KEY'));
Config::define('LOGGED_IN_KEY', env('LOGGED_IN_KEY'));
Config::define('NONCE_KEY', env('NONCE_KEY'));
Config::define('AUTH_SALT', env('AUTH_SALT'));
Config::define('SECURE_AUTH_SALT', env('SECURE_AUTH_SALT'));
Config::define('LOGGED_IN_SALT', env('LOGGED_IN_SALT'));
Config::define('NONCE_SALT', env('NONCE_SALT'));

/**
 * Default Settings
 */
Config::define('AUTOMATIC_UPDATER_DISABLED', true);
Config::define('DISABLE_WP_CRON', env('DISABLE_WP_CRON') ?: false);
Config::define('DISALLOW_FILE_EDIT', true);
Config::define('DISALLOW_FILE_MODS', true);
Config::define('WP_POST_REVISIONS', env('WP_POST_REVISIONS') ?? 20);
Config::define('EMPTY_TRASH_DAYS', env('EMPTY_TRASH_DAYS') ?? 90);

/**
 * Security Settings
 */
Config::define('FORCE_SSL_ADMIN', true);
Config::define('FORCE_SSL_LOGIN', true);

/**
 * Performance Settings
 */
Config::define('WP_CACHE', true);
Config::define('WP_MEMORY_LIMIT', env('WP_MEMORY_LIMIT') ?: '256M');

/**
 * Debug Settings
 */
Config::define('WP_DEBUG', false);
Config::define('WP_DEBUG_DISPLAY', false);
Config::define('WP_DEBUG_LOG', false);
Config::define('SCRIPT_DEBUG', false);
ini_set('display_errors', '0');

/**
 * Handle Reverse Proxy
 */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
	$_SERVER['HTTPS'] = 'on';
}

/**
 * Load Environment Config
 */
$env_config = __DIR__ . '/environments/' . Config::get('WP_ENV') . '.php';

if (file_exists($env_config)) {
	require_once $env_config;
}

/**
 * Apply Configurations
 */
Config::apply();

/**
 * Bootstrap WordPress
 */
if (!defined('ABSPATH') && !defined('WP_CLI')) {
	define('ABSPATH', $webroot_dir . '/wp/');
}


/**
 * Auth K
 */
Config::define('SAMPLE_API', env('SAMPLE_API'));
Config::define('JWT_AUTH_SECRET_KEY', env('JWT_AUTH_SECRET_KEY'));	
