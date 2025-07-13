<?php
/**
 * Simple basecamp command to set up a BuiltNorth project
 */

if (!class_exists('WP_CLI')) {
    return;
}

/**
 * Simple Basecamp Command
 */
class Basecamp_Command {
    
    /**
     * Bootstrap a new project
     * 
     * ## OPTIONS
     * 
     * [--name=<name>]
     * : Project name (required)
     * 
     * [--username=<username>]
     * : WordPress admin username (default: admin)
     * 
     * [--password=<password>]
     * : WordPress admin password (required)
     * 
     * [--email=<email>]
     * : WordPress admin email (required)
     * 
     * ## EXAMPLES
     * 
     *     wp basecamp --name="My Project" --email="admin@example.com" --password="secure123"
     * 
     * @when before_wp_load
     */
    public function __invoke($args, $assoc_args) {
        WP_CLI::line('WordPress Setup');
        WP_CLI::line('===============');
        WP_CLI::line('');
        
        // Get values from args (these should be passed from bootstrap.php)
        $name = $assoc_args['name'] ?? WP_CLI::error('Missing --name parameter');
        $username = $assoc_args['username'] ?? 'admin';
        $email = $assoc_args['email'] ?? WP_CLI::error('Missing --email parameter');
        $password = $assoc_args['password'] ?? WP_CLI::error('Missing --password parameter');
        
        // Sanitize project name
        $sitename = strtolower(str_replace(' ', '-', $name));
        $url = "https://{$sitename}.lndo.site";
        
        // Step 1: Install WordPress
        WP_CLI::line('Installing WordPress...');
        
        // First ensure WordPress core files exist
        if (!file_exists('wp/index.php')) {
            WP_CLI::error('WordPress core files not found. Please ensure composer install has run successfully.');
        }
        
        $this->wait_for_db();
        
        // Check if WordPress is already installed
        exec('wp core is-installed 2>&1', $output, $return_code);
        if ($return_code === 0) {
            WP_CLI::warning('WordPress appears to be already installed. Resetting database...');
            exec('wp db reset --yes 2>&1', $reset_output, $reset_return);
            if ($reset_return !== 0) {
                WP_CLI::error('Failed to reset database: ' . implode(' ', $reset_output));
            }
        } else {
            // WordPress not installed, ensure database exists
            WP_CLI::line('Ensuring database exists...');
            exec('wp db create 2>&1', $db_output, $db_return);
            if ($db_return === 0) {
                WP_CLI::success('Database created successfully');
            } else {
                // Check if it's just because database already exists
                exec('wp db check 2>&1', $check_output, $check_return);
                if ($check_return === 0) {
                    WP_CLI::line('Database already exists and is accessible');
                } else {
                    WP_CLI::error('Database issue: ' . implode(' ', $db_output));
                }
            }
        }
        
        $install_cmd = sprintf(
            'wp core install --url="%s" --title="%s" --admin_user="%s" --admin_password="%s" --admin_email="%s" --skip-email',
            $url,
            $name,
            $username,
            $password,
            $email
        );
        
        WP_CLI::line("Running: $install_cmd");
        
        // Use passthru to see real-time output
        passthru($install_cmd, $return_code);
        
        if ($return_code !== 0) {
            WP_CLI::error('WordPress installation failed. Please check the configuration.');
        }
        
        // Verify installation
        WP_CLI::line('Verifying installation...');
        exec('wp core is-installed 2>&1', $installed_check, $installed_return);
        if ($installed_return === 0) {
            WP_CLI::success('WordPress is installed');
            
            // Get key options
            exec('wp option get siteurl 2>&1', $siteurl_output);
            exec('wp option get home 2>&1', $home_output);
            exec('wp db prefix 2>&1', $prefix_output);
            
            WP_CLI::line('Site URL: ' . implode('', $siteurl_output));
            WP_CLI::line('Home URL: ' . implode('', $home_output));
            WP_CLI::line('Table prefix: ' . implode('', $prefix_output));
            WP_CLI::line('Expected URL: ' . $url);
        } else {
            WP_CLI::error('WordPress installation verification failed: ' . implode(' ', $installed_check));
        }
        
        // Step 2: Configure WordPress
        WP_CLI::line('Configuring WordPress...');
        
        // Handle theme installation
        WP_CLI::line('Checking for themes...');
        
        // 1. Check if composer has theme packages
        $composer_file = dirname(__DIR__) . '/composer.json';
        $has_composer_themes = false;
        
        if (file_exists($composer_file)) {
            $composer_json = json_decode(file_get_contents($composer_file), true);
            
            // Check both require and require-dev for theme packages
            foreach (['require', 'require-dev'] as $section) {
                foreach ($composer_json[$section] ?? [] as $package => $version) {
                    // Common theme package patterns
                    if (strpos($package, '/theme') !== false || 
                        strpos($package, 'wp-content/themes/') !== false ||
                        preg_match('/themes?\//', $package)) {
                        $has_composer_themes = true;
                        WP_CLI::line("Found theme package in composer.json: {$package}");
                        break 2;
                    }
                }
            }
        }
        
        // 2. Check for themes in setup/data/themes
        $themes_source_dir = dirname(__DIR__) . '/setup/data/themes';
        $themes_to_copy = [];
        
        if (is_dir($themes_source_dir)) {
            $themes_to_copy = glob($themes_source_dir . '/*', GLOB_ONLYDIR);
            if (!empty($themes_to_copy)) {
                WP_CLI::line('Found ' . count($themes_to_copy) . ' theme(s) in setup/data/themes/');
            }
        }
        
        // 3. Copy themes from setup/data if found
        $themes_dest_dir = dirname(__DIR__) . '/wp-content/themes';
        foreach ($themes_to_copy as $theme_path) {
            $theme_name = basename($theme_path);
            $dest_path = $themes_dest_dir . '/' . $theme_name;
            
            WP_CLI::line("Copying theme: {$theme_name}");
            
            // Use recursive copy
            exec("cp -r {$theme_path} {$dest_path} 2>&1", $copy_output, $copy_return);
            
            if ($copy_return === 0) {
                WP_CLI::success("Copied theme: {$theme_name}");
            } else {
                WP_CLI::warning("Failed to copy theme {$theme_name}: " . implode(' ', $copy_output));
            }
        }
        
        // 4. Check what themes are now available
        $available_themes = glob($themes_dest_dir . '/*', GLOB_ONLYDIR);
        $theme_count = count($available_themes);
        
        // 5. Only install default theme if no themes exist
        if (!$has_composer_themes && empty($themes_to_copy) && $theme_count === 0) {
            WP_CLI::line('No themes found, installing default theme...');
            
            $themes_to_try = ['twentytwentyfive', 'twentytwentyfour', 'twentytwentythree'];
            $theme_installed = false;
            
            foreach ($themes_to_try as $theme) {
                exec("wp theme install $theme --activate 2>&1", $theme_output, $theme_return);
                if ($theme_return === 0) {
                    WP_CLI::success("Theme $theme installed and activated");
                    $theme_installed = true;
                    break;
                }
            }
            
            if (!$theme_installed) {
                WP_CLI::warning('Could not install any default theme. You may need to install one manually.');
            }
        } else {
            WP_CLI::line("Found {$theme_count} theme(s) in wp-content/themes/");
            
            // Activate the first available theme
            if ($theme_count > 0) {
                $first_theme = basename($available_themes[0]);
                exec("wp theme activate {$first_theme} 2>&1", $activate_output, $activate_return);
                
                if ($activate_return === 0) {
                    WP_CLI::success("Activated theme: {$first_theme}");
                } else {
                    WP_CLI::warning("Failed to activate theme {$first_theme}: " . implode(' ', $activate_output));
                }
            }
        }
        
        // Activate plugins
        exec('wp plugin list --format=count 2>&1', $plugin_count, $plugin_return);
        if ($plugin_return === 0 && intval($plugin_count[0] ?? 0) > 0) {
            WP_CLI::line('Activating plugins...');
            exec('wp plugin activate --all 2>&1', $activate_output, $activate_return);
            if ($activate_return !== 0) {
                WP_CLI::warning('Some plugins may not have activated: ' . implode(' ', $activate_output));
            }
        } else {
            WP_CLI::line('No plugins to activate');
        }
        
        // Configure settings
        WP_CLI::line('Configuring settings...');
        exec('wp option update timezone_string "America/New_York" 2>&1', $tz_output, $tz_return);
        if ($tz_return !== 0) {
            WP_CLI::warning('Failed to set timezone: ' . implode(' ', $tz_output));
        }
        
        exec('wp option update uploads_use_yearmonth_folders "0" 2>&1', $upload_output, $upload_return);
        if ($upload_return !== 0) {
            WP_CLI::warning('Failed to set upload settings: ' . implode(' ', $upload_output));
        }
        
        exec('wp rewrite structure "/%postname%/" 2>&1', $rewrite_output, $rewrite_return);
        if ($rewrite_return !== 0) {
            WP_CLI::warning('Failed to set rewrite structure: ' . implode(' ', $rewrite_output));
        }
        
        exec('wp rewrite flush 2>&1', $flush_output, $flush_return);
        if ($flush_return !== 0) {
            WP_CLI::warning('Failed to flush rewrites: ' . implode(' ', $flush_output));
        }
        
        // Check for content files to import
        $content_dir = dirname(__DIR__) . '/setup/data/content';
        $content_files = [];
        
        if (is_dir($content_dir)) {
            $content_files = glob($content_dir . '/*.xml');
        }
        
        // Import content if XML files exist
        if (!empty($content_files)) {
            WP_CLI::line('Found ' . count($content_files) . ' content file(s) to import...');
            
            // Ensure importer is installed
            exec('wp plugin is-installed wordpress-importer 2>&1', $importer_check, $importer_return);
            if ($importer_return !== 0) {
                exec('wp plugin install wordpress-importer --activate 2>&1', $install_output, $install_return);
                if ($install_return !== 0) {
                    WP_CLI::warning('Failed to install importer: ' . implode(' ', $install_output));
                    WP_CLI::warning('Skipping content import');
                }
            } else {
                exec('wp plugin activate wordpress-importer 2>&1', $activate_output, $activate_return);
                if ($activate_return !== 0) {
                    WP_CLI::warning('Failed to activate importer: ' . implode(' ', $activate_output));
                    WP_CLI::warning('Skipping content import');
                }
            }
            
            // Import each XML file
            foreach ($content_files as $file) {
                WP_CLI::line('Importing: ' . basename($file));
                exec("wp import {$file} --authors=create 2>&1", $import_output, $import_return);
                if ($import_return !== 0) {
                    WP_CLI::warning('Failed to import ' . basename($file) . ': ' . implode(' ', $import_output));
                } else {
                    WP_CLI::success('Imported ' . basename($file));
                }
            }
            
            // Only remove default content if we successfully imported content
            WP_CLI::line('Cleaning default content...');
            
            // Delete default posts
            exec('wp post delete 1 --force 2>&1', $del1_output, $del1_return); // Hello World post
            
            // Delete default page only if we have pages in imported content
            $imported_pages = false;
            foreach ($content_files as $file) {
                $content = file_get_contents($file);
                if (strpos($content, '<wp:post_type>page</wp:post_type>') !== false) {
                    $imported_pages = true;
                    break;
                }
            }
            
            if ($imported_pages) {
                exec('wp post delete 2 --force 2>&1', $del2_output, $del2_return); // Sample Page
            } else {
                WP_CLI::line('Keeping default Sample Page as no pages were imported');
            }
            
            // Delete default comment
            exec('wp comment delete 1 --force 2>&1', $comment_output, $comment_return);
        } else {
            WP_CLI::line('No content files found in setup/data/content/, keeping default content');
        }
        
        
        // Import media
        $images_dir = dirname(__DIR__) . '/setup/data/images';
        $logo_id = null;
        $icon_id = null;
        
        if (is_dir($images_dir)) {
            // Get all image files
            $image_extensions = ['png', 'jpg', 'jpeg', 'gif', 'webp'];
            $media_files = [];
            
            foreach ($image_extensions as $ext) {
                $media_files = array_merge($media_files, glob($images_dir . '/*.' . $ext));
            }
            
            if (!empty($media_files)) {
                WP_CLI::line('Importing ' . count($media_files) . ' media file(s)...');
                
                foreach ($media_files as $file) {
                    // Clear output array before each import
                    $media_output = [];
                    exec("wp media import $file --porcelain 2>&1", $media_output, $media_return);
                    if ($media_return !== 0) {
                        WP_CLI::warning('Failed to import media ' . basename($file) . ': ' . implode(' ', $media_output));
                    } else {
                        $attachment_id = trim($media_output[0]);
                        $filename = basename($file);
                        
                        // Track logo and icon IDs by filename
                        if (strpos(strtolower($filename), 'logo') !== false && $logo_id === null) {
                            $logo_id = $attachment_id;
                            WP_CLI::success("Imported {$filename} as site logo (ID: {$logo_id})");
                        } elseif (strpos(strtolower($filename), 'icon') !== false && $icon_id === null) {
                            $icon_id = $attachment_id;
                            WP_CLI::success("Imported {$filename} as site icon (ID: {$icon_id})");
                        } else {
                            WP_CLI::success("Imported {$filename} (ID: {$attachment_id})");
                        }
                    }
                }
            } else {
                WP_CLI::line('No media files found in setup/data/images/');
            }
        } else {
            WP_CLI::line('No images directory found at setup/data/images/');
        }
        
        // Set site logo and icon
        if ($logo_id || $icon_id) {
            WP_CLI::line('Setting site logo and icon...');
            
            // Get current theme
            exec('wp option get stylesheet 2>&1', $theme_output, $theme_return);
            $current_theme = ($theme_return === 0) ? trim($theme_output[0]) : 'twentytwentyfive';
            
            if ($logo_id) {
                // Set site logo - this is stored in the site_logo option
                exec("wp option update site_logo {$logo_id} 2>&1", $logo_output, $logo_return);
                if ($logo_return === 0) {
                    WP_CLI::success('Set site logo');
                } else {
                    WP_CLI::warning('Failed to set site logo: ' . implode(' ', $logo_output));
                }
            }
            
            if ($icon_id) {
                // Set site icon (favicon)
                exec("wp option update site_icon {$icon_id} 2>&1", $icon_output, $icon_return);
                if ($icon_return === 0) {
                    WP_CLI::success('Set site icon');
                } else {
                    WP_CLI::warning('Failed to set site icon: ' . implode(' ', $icon_output));
                }
            }
        }
        
        
        // Setup home and blog pages if they exist
        WP_CLI::line('Checking for home and blog pages...');
        exec('wp post list --post_type=page --format=json 2>&1', $pages_output, $pages_return);
        
        if ($pages_return === 0) {
            $pages = json_decode(implode('', $pages_output), true);
            $home_id = null;
            $blog_id = null;
            
            // Look for pages with specific slugs or titles
            foreach ($pages as $page) {
                $slug = strtolower($page['post_name']);
                $title = strtolower($page['post_title']);
                
                // Check for home page
                if (!$home_id && ($slug === 'home' || $slug === 'homepage' || $title === 'home' || $title === 'homepage')) {
                    $home_id = $page['ID'];
                }
                
                // Check for blog page
                if (!$blog_id && ($slug === 'blog' || $slug === 'news' || $title === 'blog' || $title === 'news')) {
                    $blog_id = $page['ID'];
                }
            }
            
            // Set up pages if found
            if ($home_id || $blog_id) {
                WP_CLI::line('Configuring page settings...');
                
                if ($home_id && $blog_id) {
                    exec("wp option update page_for_posts {$blog_id} 2>&1", $posts_output, $posts_return);
                    exec("wp option update page_on_front {$home_id} 2>&1", $front_output, $front_return);
                    exec("wp option update show_on_front page 2>&1", $show_output, $show_return);
                    
                    if ($posts_return === 0 && $front_return === 0 && $show_return === 0) {
                        WP_CLI::success("Set home page (ID: {$home_id}) and blog page (ID: {$blog_id})");
                    }
                } elseif ($home_id) {
                    exec("wp option update page_on_front {$home_id} 2>&1", $front_output, $front_return);
                    exec("wp option update show_on_front page 2>&1", $show_output, $show_return);
                    
                    if ($front_return === 0 && $show_return === 0) {
                        WP_CLI::success("Set home page (ID: {$home_id})");
                    }
                }
            } else {
                WP_CLI::line('No home or blog pages found, using default WordPress settings');
            }
        }
        
        // Success!
        WP_CLI::line('');
        WP_CLI::success('Bootstrap complete!');
        WP_CLI::line('');
        
        // Final verification
        exec('wp core is-installed 2>&1', $final_check, $final_return);
        if ($final_return === 0) {
            WP_CLI::success('WordPress installation verified!');
            WP_CLI::line('');
            WP_CLI::line("Frontend: {$url}");
            WP_CLI::line("Admin: {$url}/wp/wp-admin");
            WP_CLI::line("Username: {$username}");
            WP_CLI::line("Password: {$password}");
        } else {
            WP_CLI::warning('WordPress may not be properly installed. Please check your site.');
            WP_CLI::line("Try visiting: {$url}");
        }
    }
    
    /**
     * Wait for database to be ready
     */
    private function wait_for_db() {
        $max_attempts = 60; // Increased to 60 attempts (2 minutes total)
        $attempt = 0;
        
        WP_CLI::line('Waiting for database to be ready...');
        
        while ($attempt < $max_attempts) {
            // Clear previous output
            $output = [];
            
            // For initial setup, just check if we can connect to MySQL
            exec('wp db query "SELECT 1" 2>&1', $output, $return_code);
            
            if ($return_code === 0) {
                WP_CLI::success('Database is ready');
                return;
            }
            
            $attempt++;
            
            // Show progress
            if ($attempt === 1) {
                WP_CLI::line("Database service is starting up...");
            } elseif ($attempt % 10 === 0) {
                WP_CLI::line("Still waiting... (attempt {$attempt}/{$max_attempts})");
            }
            
            if ($attempt >= $max_attempts) {
                WP_CLI::error('Database connection timeout after 2 minutes. Please check your configuration.');
            }
            
            sleep(2); // Check every 2 seconds
        }
    }
}

// Register the basecamp command
if (class_exists('WP_CLI')) {
    WP_CLI::add_command('basecamp', 'Basecamp_Command');
}