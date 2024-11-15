#!/bin/bash

# Source the database helpers
source "$(dirname "$0")/db-helpers.sh"

# Set up database commands for the current environment
setup_db_commands || exit 1

# Get WordPress configuration
DB_PREFIX=$(get_wp_config "table_prefix" "wp_")
DB_NAME=$(get_wp_config "DB_NAME")

# Function to sanitize database
sanitize_database() {
    local SQL_FILE="$1"
    
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
        db_export "${SQL_FILE}" "" "--no-data"
        
        # Step 2: Export data for posts table with filtering
        db_export "${SQL_FILE}.posts" "${DB_PREFIX}posts" \
            "post_type NOT IN ('shop_order', 'shop_order_refund', 'wpcf7_contact_form')"
        
        # Step 3: Export data for safe tables
        SAFE_TABLES="${DB_PREFIX}options,${DB_PREFIX}postmeta,${DB_PREFIX}terms,${DB_PREFIX}term_relationships,${DB_PREFIX}term_taxonomy"
        db_export "${SQL_FILE}.safe" "${SAFE_TABLES}"
        
        
    fi
} 