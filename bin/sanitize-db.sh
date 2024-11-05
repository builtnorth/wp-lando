#!/bin/bash

# Colors for output (if not already defined)
RED=${RED:-'\033[0;31m'}
GREEN=${GREEN:-'\033[0;32m'}
YELLOW=${YELLOW:-'\033[1;33m'}
NC=${NC:-'\033[0m'}

# Function to get WordPress table prefix
get_table_prefix() {
    # Try to get prefix from Lando WordPress first
    local PREFIX=$(lando wp config get table_prefix 2>/dev/null)
    
    # If that fails, try to get it from .env file
    if [ -z "$PREFIX" ] && [ -f ".env" ]; then
        PREFIX=$(grep "^DB_PREFIX=" .env | cut -d '=' -f2)
    fi
    
    # Default to wp_ if nothing else works
    echo "${PREFIX:-wp_}"
}

# Get the table prefix once at the start
TABLE_PREFIX=$(get_table_prefix)

# Function to sanitize database
sanitize_database() {
    local SQL_FILE="$1"
    local DB_NAME="$2"
    
    echo -e "\n${YELLOW}⚠️  Database Sanitization Warning${NC}"
    echo -e "This will remove Personal Identifiable Information (PII) from the export:"
    echo -e "- User data (emails, names, passwords)"
    echo -e "- Form submissions (Contact Form 7, Gravity Forms, etc.)"
    echo -e "- Comments"
    echo -e "- Order/Customer data (if WooCommerce is installed)"
    
    read -p "Would you like to remove PII data? (y/n): " SANITIZE_DB
    
    if [[ "${SANITIZE_DB}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Removing PII data...${NC}"
        
        # Step 1: Export structure for all tables
        lando wp db export "${SQL_FILE}" --no-data
        
        # Step 2: Export data for posts table with filtering
        lando wp db export "${SQL_FILE}.posts" \
            --tables="${TABLE_PREFIX}posts" \
            --where="post_type NOT IN ('shop_order', 'shop_order_refund', 'wpcf7_contact_form')"
        
        # Step 3: Export data for safe tables
        lando wp db export "${SQL_FILE}.safe" \
            --tables="${TABLE_PREFIX}options,${TABLE_PREFIX}postmeta,${TABLE_PREFIX}terms,${TABLE_PREFIX}term_relationships,${TABLE_PREFIX}term_taxonomy"
        
        # Step 4: Combine files
        cat "${SQL_FILE}.posts" >> "${SQL_FILE}"
        cat "${SQL_FILE}.safe" >> "${SQL_FILE}"
        
        # Step 5: Add sanitized admin user
        cat >> "${SQL_FILE}" << EOF
LOCK TABLES \`${TABLE_PREFIX}users\` WRITE;
INSERT INTO \`${TABLE_PREFIX}users\` VALUES (1,'admin','INVALID_PASSWORD','admin','admin@example.com','','2024-01-01 00:00:00','',0,'Admin');
UNLOCK TABLES;

LOCK TABLES \`${TABLE_PREFIX}usermeta\` WRITE;
INSERT INTO \`${TABLE_PREFIX}usermeta\` VALUES (1,1,'wp_capabilities','a:1:{s:13:\"administrator\";b:1;}');
INSERT INTO \`${TABLE_PREFIX}usermeta\` VALUES (2,1,'wp_user_level','10');
UNLOCK TABLES;
EOF
        
        # Clean up temporary files
        rm -f "${SQL_FILE}.posts" "${SQL_FILE}.safe"
        
        echo -e "${GREEN}✓${NC} PII data removed"
        return 0
    fi
    
    # If not sanitizing, just do a regular export
    lando wp db export "${SQL_FILE}"
    return 1
} 