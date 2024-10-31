#!/bin/bash

# Colors
TEAL='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ASCII art and welcome message
echo -e "${TEAL}
  ____                                           
 |  _ \\                                          
 | |_) | __ _ ___  ___  ___ __ _ _ __ ___  _ __  
 |  _ < / _\` / __|/ _ \\/ __/ _\` | '_ \` _ \\| '_ \\ 
 | |_) | (_| \\__ \\  __/ (_| (_| | | | | | | |_) |
 |____/ \\__,_|___/\\___|\\___\\__,_|_| |_| |_| .__/ 
                                          | |    
                                          |_|    
${NC}
${GREEN}Get started by entering WordPress setup info.${NC}
"

# Collect user input
read -p "Site Name: " -e sitename_original
read -p "Username: " -e username
read -p "Password: " -e password
read -p "Email Address: " -e email
printf "\n"

# Convert sitename to lowercase and replace spaces with dashes
sitename=$(echo "$sitename_original" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

# Site local url
url="https://$sitename.lndo.site"

# Export the URL for use in other scripts
export WORDPRESS_URL="$url"

# Function to find and copy file
copy_file() {
    local source="$1"
    local dest="$2"
    if [ -f "$source" ]; then
        cp "$source" "$dest"
    elif [ -f "../$source" ]; then
        cp "../$source" "$dest"
    else
        echo "Error: $source not found in current or parent directory"
        exit 1
    fi
}


# Generate env file
copy_file ".env.example" ".env"
sed -i.bak "s#project-name#$sitename#g" .env && rm .env.bak

# Generate .lando.yml file
copy_file ".lando.example.yml" ".lando.yml"
sed -i.bak "s/project-name/$sitename/g" .lando.yml && rm .lando.yml.bak


sitename=$(echo "$sitename_original" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')


# Create directory structure first
echo "Creating directory structure..."
mkdir -p wp-content/{plugins,themes,mu-plugins,uploads}
chmod 755 wp-content
chmod 755 wp-content/{plugins,themes,mu-plugins}
chmod 775 wp-content/uploads

# Start Lando environment
echo "Starting Lando environment..."
if ! lando start; then
    echo -e "${RED}Failed to start Lando${NC}"
    exit 1
fi

# Install PHP dependencies
echo "Installing Composer dependencies..."
if ! lando composer install; then
    echo -e "${RED}Failed to install Composer dependencies${NC}"
    exit 1
fi


# Download WordPress core
# echo "Downloading WordPress core..."
# if ! lando wp core download; then
#     echo -e "${RED}Failed to download WordPress core${NC}"
#     exit 1
# fi

# Install WordPress
echo "Installing WordPress..."
if ! lando wp core install --url="https://$sitename.lndo.site" --title="$sitename_original" --admin_user="$username" --admin_password="$password" --admin_email="$email"; then
    echo -e "${RED}Failed to install WordPress${NC}"
    exit 1
fi

# Display WordPress login info
echo -e "\n${GREEN}WordPress login info:${NC}"
echo "URL: https://$sitename.lndo.site/wp-admin"
echo "Username: $username"
echo "Password: $password"
echo "Email: $email"

echo -e "\n${GREEN}Setup complete!${NC}"