#!/bin/bash

# Source common paths
source "$(dirname "$0")/common-paths.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create temporary export directory
TEMP_EXPORT_DIR="/tmp/wp-export-$(date +%Y%m%d-%H%M%S)"
ARCHIVE_NAME="wp-export-$(date +%Y%m%d-%H%M%S).tar.gz"

# Create temporary export directory structure
create_temp_dirs() {
    # echo -e "\n${GREEN}Creating temporary export directory...${NC}"
    mkdir -p "${TEMP_EXPORT_DIR}"
}

# Check if we're in the right directory
check_wordpress_root() {
    if [ ! -f "wp-config.php" ]; then
        echo -e "${RED}Error: wp-config.php not found${NC}"
        echo -e "Please run this script from the WordPress root directory"
        exit 1
    fi
}

# Export database
export_database() {
    echo -e "\n${GREEN}Exporting database...${NC}"
    
    # Source PII sanitization functions
    source "$(dirname "$0")/sanitize-db.sh"
    
    # Offer to sanitize PII
    sanitize_database
    
    # Export using Lando's configured database connection
    lando wp db export - | gzip > "${TEMP_EXPORT_DIR}/database.sql.gz"
    
    if [ $? -eq 0 ]; then
        DB_SIZE=$(du -sh "${TEMP_EXPORT_DIR}/database.sql.gz" | cut -f1)
        echo -e "${GREEN}✓${NC} Database exported successfully (${DB_SIZE})"
        
        # Check if the exported file is too small
        if [ $(stat -f%z "${TEMP_EXPORT_DIR}/database.sql.gz") -lt 1000 ]; then
            echo -e "${YELLOW}Warning: Database export seems very small. Might be empty.${NC}"
        fi
    else
        echo -e "${RED}✗${NC} Database export failed"
        exit 1
    fi
}

# Export content
export_content() {
    echo -e "\n${GREEN}Exporting wp-content...${NC}"
    rsync -aq --delete --exclude 'upgrade' "wp-content/" "${TEMP_EXPORT_DIR}/wp-content/"
    CONTENT_SIZE=$(du -sh "${TEMP_EXPORT_DIR}/wp-content" | cut -f1)
    echo -e "${GREEN}✓${NC} Content exported successfully (${CONTENT_SIZE})"
}

# Create archive
create_archive() {
    # Ensure data directory exists
    DATA_DIR="data"
    if [ ! -d "${DATA_DIR}" ]; then
        echo -e "\n${GREEN}Creating data directory...${NC}"
        mkdir -p "${DATA_DIR}"
    fi

    echo -e "\n${GREEN}Creating archive...${NC}"
    FULL_PATH="${DATA_DIR}/${ARCHIVE_NAME}"
    tar -czf "${FULL_PATH}" -C "${TEMP_EXPORT_DIR}" .
    
    if [ $? -eq 0 ]; then
        ARCHIVE_SIZE=$(du -sh "${FULL_PATH}" | cut -f1)
        echo -e "${GREEN}✓${NC} Archive created successfully:"
        echo -e "Location: ${FULL_PATH}"
        echo -e "Size: ${ARCHIVE_SIZE}"
    else
        echo -e "${RED}✗${NC} Archive creation failed"
        exit 1
    fi
}

# Main execution
echo -e "${GREEN}Starting export process...${NC}"

check_wordpress_root
create_temp_dirs
export_database
export_content
create_archive

echo -e "\n${GREEN}Export complete!${NC}"
