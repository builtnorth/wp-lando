#!/bin/bash

# Source common paths
source "$(dirname "$0")/helpers/variables.sh"
source "$(dirname "$0")/helpers/colors.sh"

# Prompt for import path
echo -e "\n${GREEN}Where is your import file?${NC}"
echo -e "Should be in the format of: ${IMPORT_DIR}/${EXPORT_FILE_NAME}"
read -p "Import path: " CUSTOM_IMPORT_PATH

# Use custom path if provided, otherwise use default
IMPORT_PATH=${CUSTOM_IMPORT_PATH:-$IMPORT_DIR}

# Check if import file exists and extract if needed
check_import_source() {
    if [ ! -f "${IMPORT_PATH}" ]; then
        echo -e "${RED}Error: Import file not found at ${IMPORT_PATH}${NC}"
        exit 1
    fi

    # Create temp directory
    mkdir -p "${TEMP_DIR}"

    # Extract archive
    echo -e "\n${GREEN}Extracting import file...${NC}"
    tar -xzf "${IMPORT_PATH}" -C "${TEMP_DIR}"

    # Verify required files exist - check in TEMP_DIR, not IMPORT_PATH
    if [ ! -f "${TEMP_DIR}/database.sql" ]; then
        echo -e "${RED}Error: Database dump not found${NC}"
        exit 1
    fi

    if [ ! -d "${TEMP_DIR}/wp-content" ]; then
        echo -e "${RED}Error: wp-content directory not found${NC}"
        exit 1
    fi
}

# Analyze wp-content directory and show what's available to import
analyze_content() {
    echo -e "\n${GREEN}Analyzing available content to import...${NC}"
    
    # Check uploads
    if [ -d "${TEMP_DIR}/wp-content/uploads" ]; then
        UPLOADS_SIZE=$(du -sh "${TEMP_DIR}/wp-content/uploads" | cut -f1)
        echo -e "${GREEN}✓${NC} Uploads directory found (${UPLOADS_SIZE})"
        HAS_UPLOADS=1
    else
        echo -e "${YELLOW}✗${NC} No uploads directory found"
    fi

    # Check plugins
    if [ -d "${TEMP_DIR}/wp-content/plugins" ]; then
        PLUGIN_COUNT=$(ls -1 "${TEMP_DIR}/wp-content/plugins" | wc -l)
        echo -e "${GREEN}✓${NC} Plugins directory found (${PLUGIN_COUNT} plugins)"
        HAS_PLUGINS=1
    else
        echo -e "${YELLOW}✗${NC} No plugins directory found"
    fi

    # Check themes
    if [ -d "${TEMP_DIR}/wp-content/themes" ]; then
        THEME_COUNT=$(ls -1 "${TEMP_DIR}/wp-content/themes" | wc -l)
        echo -e "${GREEN}✓${NC} Themes directory found (${THEME_COUNT} themes)"
        HAS_THEMES=1
    else
        echo -e "${YELLOW}✗${NC} No themes directory found"
    fi

    # Check mu-plugins
    if [ -d "${TEMP_DIR}/wp-content/mu-plugins" ]; then
        MUPLUGIN_COUNT=$(ls -1 "${TEMP_DIR}/wp-content/mu-plugins" | wc -l)
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
        # lando wp db import "${IMPORT_PATH}/database.sql"
    fi
}

# Import content
import_content() {
    # Import uploads
    if [[ "${IMPORT_UPLOADS}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Importing uploads...${NC}"
        rsync -av --delete "${TEMP_DIR}/wp-content/uploads/" "wp-content/uploads/"
    fi

    # Import plugins
    if [[ "${IMPORT_PLUGINS}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Importing plugins...${NC}"
        echo -e "${YELLOW}Warning: This may override composer-managed plugins${NC}"
        read -p "Are you sure? (y/n): " CONFIRM_PLUGINS
        if [[ "${CONFIRM_PLUGINS}" =~ ^[Yy]$ ]]; then
            rsync -av --delete "${TEMP_DIR}/wp-content/plugins/" "wp-content/plugins/"
        fi
    fi

    # Import themes
    if [[ "${IMPORT_THEMES}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Importing themes...${NC}"
        echo -e "${YELLOW}Warning: This may override composer-managed themes${NC}"
        read -p "Are you sure? (y/n): " CONFIRM_THEMES
        if [[ "${CONFIRM_THEMES}" =~ ^[Yy]$ ]]; then
            rsync -av --delete "${TEMP_DIR}/wp-content/themes/" "wp-content/themes/"
        fi
    fi

    # Import mu-plugins
    if [[ "${IMPORT_MUPLUGINS}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Importing must-use plugins...${NC}"
        rsync -av --delete "${TEMP_DIR}/wp-content/mu-plugins/" "wp-content/mu-plugins/"
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
