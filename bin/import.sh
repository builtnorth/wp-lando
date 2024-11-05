#!/bin/bash

# Source common paths
source "$(dirname "$0")/common-paths.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if import directory exists and has content
check_import_source() {
    if [ ! -d "${IMPORT_DIR}" ]; then
        echo -e "${RED}Error: Import directory not found at ${IMPORT_DIR}${NC}"
        exit 1
    fi

    # Check for database dump
    if [ ! -f "${IMPORT_DIR}/database.sql.gz" ]; then
        echo -e "${RED}Error: Database dump not found at ${IMPORT_DIR}/database.sql.gz${NC}"
        exit 1
    fi

    # Check for wp-content directory
    if [ ! -d "${IMPORT_DIR}/wp-content" ]; then
        echo -e "${RED}Error: wp-content directory not found at ${IMPORT_DIR}/wp-content${NC}"
        exit 1
    fi
}

# Analyze wp-content directory and show what's available to import
analyze_content() {
    echo -e "\n${GREEN}Analyzing available content to import...${NC}"
    
    # Check uploads
    if [ -d "${IMPORT_DIR}/wp-content/uploads" ]; then
        UPLOADS_SIZE=$(du -sh "${IMPORT_DIR}/wp-content/uploads" | cut -f1)
        echo -e "${GREEN}✓${NC} Uploads directory found (${UPLOADS_SIZE})"
        HAS_UPLOADS=1
    else
        echo -e "${YELLOW}✗${NC} No uploads directory found"
    fi

    # Check plugins
    if [ -d "${IMPORT_DIR}/wp-content/plugins" ]; then
        PLUGIN_COUNT=$(ls -1 "${IMPORT_DIR}/wp-content/plugins" | wc -l)
        echo -e "${GREEN}✓${NC} Plugins directory found (${PLUGIN_COUNT} plugins)"
        HAS_PLUGINS=1
    else
        echo -e "${YELLOW}✗${NC} No plugins directory found"
    fi

    # Check themes
    if [ -d "${IMPORT_DIR}/wp-content/themes" ]; then
        THEME_COUNT=$(ls -1 "${IMPORT_DIR}/wp-content/themes" | wc -l)
        echo -e "${GREEN}✓${NC} Themes directory found (${THEME_COUNT} themes)"
        HAS_THEMES=1
    else
        echo -e "${YELLOW}✗${NC} No themes directory found"
    fi

    # Check mu-plugins
    if [ -d "${IMPORT_DIR}/wp-content/mu-plugins" ]; then
        MUPLUGIN_COUNT=$(ls -1 "${IMPORT_DIR}/wp-content/mu-plugins" | wc -l)
        echo -e "${GREEN}✓${NC} Must-use plugins directory found (${MUPLUGIN_COUNT} plugins)"
        HAS_MUPLUGINS=1
    else
        echo -e "${YELLOW}✗${NC} No must-use plugins directory found"
    fi
}

# Ask user what they want to import
get_user_preferences() {
    echo -e "\n${GREEN}What would you like to import?${NC}"
    
    if [ "$HAS_UPLOADS" = "1" ]; then
        read -p "Import uploads? (y/n): " IMPORT_UPLOADS
    fi
    
    if [ "$HAS_PLUGINS" = "1" ]; then
        read -p "Import plugins? (y/n): " IMPORT_PLUGINS
    fi
    
    if [ "$HAS_THEMES" = "1" ]; then
        read -p "Import themes? (y/n): " IMPORT_THEMES
    fi
    
    if [ "$HAS_MUPLUGINS" = "1" ]; then
        read -p "Import must-use plugins? (y/n): " IMPORT_MUPLUGINS
    fi

    read -p "Import database? (y/n): " IMPORT_DB
}

# Import database
import_database() {
    if [[ "${IMPORT_DB}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Importing database...${NC}"
        # Add your database import logic here
        # Example:
        # lando wp db import "${IMPORT_DIR}/database.sql.gz"
    fi
}

# Import content
import_content() {
    # Import uploads
    if [[ "${IMPORT_UPLOADS}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Importing uploads...${NC}"
        rsync -av --delete "${IMPORT_DIR}/wp-content/uploads/" "wp-content/uploads/"
    fi

    # Import plugins
    if [[ "${IMPORT_PLUGINS}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Importing plugins...${NC}"
        echo -e "${YELLOW}Warning: This may override composer-managed plugins${NC}"
        read -p "Are you sure? (y/n): " CONFIRM_PLUGINS
        if [[ "${CONFIRM_PLUGINS}" =~ ^[Yy]$ ]]; then
            rsync -av --delete "${IMPORT_DIR}/wp-content/plugins/" "wp-content/plugins/"
        fi
    fi

    # Import themes
    if [[ "${IMPORT_THEMES}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Importing themes...${NC}"
        echo -e "${YELLOW}Warning: This may override composer-managed themes${NC}"
        read -p "Are you sure? (y/n): " CONFIRM_THEMES
        if [[ "${CONFIRM_THEMES}" =~ ^[Yy]$ ]]; then
            rsync -av --delete "${IMPORT_DIR}/wp-content/themes/" "wp-content/themes/"
        fi
    fi

    # Import mu-plugins
    if [[ "${IMPORT_MUPLUGINS}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Importing must-use plugins...${NC}"
        rsync -av --delete "${IMPORT_DIR}/wp-content/mu-plugins/" "wp-content/mu-plugins/"
    fi
}

# Main execution
echo -e "${GREEN}Starting import process...${NC}"

check_import_source
analyze_content
get_user_preferences
import_database
import_content

echo -e "\n${GREEN}Import complete!${NC}"
