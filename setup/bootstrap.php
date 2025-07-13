<?php
/**
 * Initial bootstrap script - runs outside of Lando
 * This creates config files and starts Lando
 */

// Ensure this script is run from CLI only
if (php_sapi_name() !== 'cli') {
    exit('This script can only be run from the command line.');
}

// Check prerequisites
check_prerequisites();

// Display welcome message
display_ascii_art();

// Get values from command line args or prompt
$options = getopt('', ['name:', 'email:', 'password:', 'username:']);

$name = $options['name'] ?? prompt('Project Name');
$username = $options['username'] ?? prompt('Admin Username', 'admin');
$email = $options['email'] ?? prompt_email('Admin Email');
$password = $options['password'] ?? prompt_password('Admin Password');

// Sanitize project name
$sitename = sanitize_project_name($name);

echo "\nCreating configuration files...\n";

// Generate .env file
create_env_file($sitename);

// Generate .lando.yml file
create_lando_config($sitename);

// Start Lando with better error handling
start_lando();

// Create necessary directories
create_required_directories();

// Run composer install
run_composer_install();

// Handle NPM dependencies
handle_npm_dependencies();

// Run WordPress setup
run_wordpress_setup($name, $email, $password, $username);

echo "\n✅ Setup completed successfully!\n";

/**
 * Generate a random salt
 */
function generate_salt() {
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?';
    $salt = '';
    for ($i = 0; $i < 64; $i++) {
        $salt .= $chars[random_int(0, strlen($chars) - 1)];
    }
    return $salt;
}

/**
 * Display ASCII art
 */
function display_ascii_art() {
    echo "▖  ▖▄▖  ▄                \n";
    echo "▌▞▖▌▙▌  ▙▘▀▌▛▘█▌▛▘▀▌▛▛▌▛▌\n";
    echo "▛ ▝▌▌   ▙▘█▌▄▌▙▖▙▖█▌▌▌▌▙▌\n";
    echo "                       ▌ \n";
}

/**
 * Prompt for user input
 */
function prompt($question, $default = '') {
    if ($default) {
        $question .= " [{$default}]";
    }
    echo $question . ': ';
    
    $answer = trim(fgets(STDIN));
    return $answer ?: $default;
}

/**
 * Prompt for email with validation
 */
function prompt_email($question) {
    while (true) {
        $email = prompt($question);
        if (filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return $email;
        }
        echo "⚠️  Invalid email format. Please try again.\n";
    }
}

/**
 * Prompt for password (hidden)
 */
function prompt_password($question) {
    echo $question . ': ';
    
    if (PHP_OS === 'WINNT') {
        $password = trim(fgets(STDIN));
    } else {
        system('stty -echo');
        $password = trim(fgets(STDIN));
        system('stty echo');
        echo "\n";
    }
    
    return $password;
}

/**
 * Check if required tools are installed
 */
function check_prerequisites() {
    $missing = [];
    
    // Check for Lando
    exec('which lando 2>&1', $output, $return_code);
    if ($return_code !== 0) {
        $missing[] = 'Lando (https://lando.dev/download/)';
    }
    
    if (!empty($missing)) {
        error_exit("Missing required tools:\n- " . implode("\n- ", $missing));
    }
}

/**
 * Create .env file with proper error handling
 */
function create_env_file($sitename) {
    $env_example = dirname(__DIR__) . '/.env.example';
    $env_file = dirname(__DIR__) . '/.env';
    
    if (!file_exists($env_example)) {
        error_exit(".env.example file not found");
    }
    
    if (file_exists($env_file)) {
        $overwrite = prompt("⚠️  .env file already exists. Overwrite? (y/N)", 'n');
        if (strtolower($overwrite) !== 'y') {
            echo "Keeping existing .env file\n";
            return;
        }
    }
    
    $content = file_get_contents($env_example);
    $content = str_replace('project-name', $sitename, $content);
    
    // Generate salts
    echo "Generating secure salts...\n";
    $salts = [
        'AUTH_KEY', 'SECURE_AUTH_KEY', 'LOGGED_IN_KEY', 'NONCE_KEY',
        'AUTH_SALT', 'SECURE_AUTH_SALT', 'LOGGED_IN_SALT', 'NONCE_SALT'
    ];
    
    // Process salts in reverse order to avoid substring replacement issues
    foreach (array_reverse($salts) as $salt) {
        $salt_value = generate_salt();
        $content = preg_replace("/^{$salt}=generate$/m", "{$salt}='{$salt_value}'", $content);
    }
    
    if (!file_put_contents($env_file, $content)) {
        error_exit("Failed to create .env file");
    }
    
    echo "✓ Created .env with generated salts\n";
}

/**
 * Create Lando configuration
 */
function create_lando_config($sitename) {
    $lando_example = dirname(__DIR__) . '/.lando.example.yml';
    $lando_file = dirname(__DIR__) . '/.lando.yml';
    
    if (!file_exists($lando_example)) {
        error_exit(".lando.example.yml file not found");
    }
    
    if (file_exists($lando_file)) {
        $overwrite = prompt("⚠️  .lando.yml file already exists. Overwrite? (y/N)", 'n');
        if (strtolower($overwrite) !== 'y') {
            echo "Keeping existing .lando.yml file\n";
            return;
        }
    }
    
    $content = file_get_contents($lando_example);
    $content = str_replace('project-name', $sitename, $content);
    
    if (!file_put_contents($lando_file, $content)) {
        error_exit("Failed to create .lando.yml file");
    }
    
    echo "✓ Created .lando.yml\n";
}

/**
 * Start Lando with proper error handling
 */
function start_lando() {
    echo "\nStarting Lando...\n";
    
    // Check if Lando is already running
    exec('lando list 2>&1', $output, $return_code);
    $project_name = basename(dirname(__DIR__));
    
    foreach ($output as $line) {
        if (strpos($line, $project_name) !== false && strpos($line, 'RUNNING') !== false) {
            echo "✓ Lando is already running for this project\n";
            return;
        }
    }
    
    // Start Lando
    $output = [];
    exec('lando start 2>&1', $output, $return_code);
    
    if ($return_code !== 0) {
        echo "Lando output:\n" . implode("\n", $output) . "\n";
        error_exit("Failed to start Lando. Please check the error messages above.");
    }
    
    // Display relevant information
    foreach ($output as $line) {
        if (preg_match('/(NAME|LOCATION|SERVICES|Your app is|vitals|https?:\/\/)/', $line)) {
            echo $line . "\n";
        }
    }
    
    echo "✓ Lando started successfully\n";
}

/**
 * Create required directories
 */
function create_required_directories() {
    echo "\nCreating required directories...\n";
    
    $base_dir = dirname(__DIR__);
    $dirs = [
        'wp-content/plugins',
        'wp-content/themes',
        'wp-content/mu-plugins',
        'wp-content/uploads'
    ];
    
    foreach ($dirs as $dir) {
        $full_path = $base_dir . '/' . $dir;
        if (!is_dir($full_path)) {
            if (!mkdir($full_path, 0755, true)) {
                error_exit("Failed to create directory: $dir");
            }
            echo "✓ Created $dir\n";
        }
    }
}

/**
 * Run composer install
 */
function run_composer_install() {
    echo "\nInstalling Composer dependencies...\n";
    
    $output = [];
    exec('lando composer install 2>&1', $output, $return_code);
    
    if ($return_code !== 0) {
        echo "Composer output:\n" . implode("\n", $output) . "\n";
        error_exit("Composer install failed");
    }
    
    echo "✓ Composer dependencies installed\n";
}

/**
 * Handle NPM dependencies
 */
function handle_npm_dependencies() {
    if (!file_exists(dirname(__DIR__) . '/package.json')) {
        echo "No package.json found, skipping NPM setup\n";
        return;
    }
    
    echo "\nChecking for NPM...\n";
    
    // Check if node service is available
    exec('lando node --version 2>&1', $output, $return_code);
    
    if ($return_code !== 0) {
        echo "⚠️  Node service not available. You may need to:\n";
        echo "   1. Run 'lando rebuild' to ensure the node service is started\n";
        echo "   2. Manually run 'lando npm install' and 'lando npm run build' later\n";
        return;
    }
    
    // Install dependencies
    echo "Installing NPM dependencies...\n";
    exec('lando npm install 2>&1', $output, $return_code);
    
    if ($return_code !== 0) {
        echo "⚠️  NPM install failed. You may need to run it manually later.\n";
        return;
    }
    
    // Check if build script exists
    $package_json = json_decode(file_get_contents(dirname(__DIR__) . '/package.json'), true);
    if (isset($package_json['scripts']['build'])) {
        echo "Building assets...\n";
        exec('lando npm run build 2>&1', $output, $return_code);
        
        if ($return_code === 0) {
            echo "✓ Assets built successfully\n";
        } else {
            echo "⚠️  Build failed. You may need to run 'lando npm run build' manually.\n";
        }
    }
}

/**
 * Run WordPress setup
 */
function run_wordpress_setup($name, $email, $password, $username) {
    echo "\nRunning WordPress setup...\n";
    
    $cmd = sprintf(
        'lando wp bootstrap --name="%s" --email="%s" --password="%s" --username="%s" 2>&1',
        addslashes($name),
        addslashes($email),
        addslashes($password),
        addslashes($username)
    );
    
    passthru($cmd, $return_code);
    
    if ($return_code !== 0) {
        error_exit("WordPress setup failed. Please check the error messages above.");
    }
}

/**
 * Sanitize project name for use in URLs
 */
function sanitize_project_name($name) {
    // Convert to lowercase and replace spaces with hyphens
    $sanitized = strtolower(str_replace(' ', '-', $name));
    
    // Remove any characters that aren't alphanumeric or hyphens
    $sanitized = preg_replace('/[^a-z0-9-]/', '', $sanitized);
    
    // Remove multiple consecutive hyphens
    $sanitized = preg_replace('/-+/', '-', $sanitized);
    
    // Remove leading/trailing hyphens
    $sanitized = trim($sanitized, '-');
    
    // Ensure it's not empty
    if (empty($sanitized)) {
        error_exit("Project name results in empty string after sanitization");
    }
    
    return $sanitized;
}

/**
 * Exit with error message
 */
function error_exit($message) {
    echo "\n❌ ERROR: $message\n\n";
    exit(1);
}