#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get current datetime for folder names
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEMP_DIR="data/tmp/export-${TIMESTAMP}"
EXPORT_FILE="data/export-${TIMESTAMP}.tar.gz"

# Create directories
mkdir -p "${TEMP_DIR}"
mkdir -p "$(dirname "${EXPORT_FILE}")"


# Get table prefix
DB_PREFIX=$(lando wp config get table_prefix --quiet)

# Ask about PII data
echo -e "\n${YELLOW}Would you like to remove PII?${NC}"
echo -e "This includes: users, comments, orders, form submissions, etc."
echo -e "A new admin user will be created with the details you provide.\n"
read -p "Remove PII? (y/n): " REMOVE_PII

if [[ "${REMOVE_PII}" =~ ^[Yy]$ ]]; then
    # Get admin user details
    echo -e "\n${GREEN}Enter details for the admin user:${NC}"
    read -p "Username (default: admin): " ADMIN_USER
    read -p "Email (default: admin@example.com): " ADMIN_EMAIL
    read -p "Password (default: admin): " ADMIN_PASS
    
    # Set defaults if empty
    ADMIN_USER=${ADMIN_USER:-admin}
    ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}
    ADMIN_PASS=${ADMIN_PASS:-admin}

    # List of tables to exclude
    declare -a TABLES_TO_EXCLUDE=(
        "${DB_PREFIX}users"
        "${DB_PREFIX}usermeta"
        "${DB_PREFIX}comments"
        "${DB_PREFIX}commentmeta"
        
        # WooCommerce
        "${DB_PREFIX}wc_customer_lookup"
        "${DB_PREFIX}wc_order_stats"
        "${DB_PREFIX}wc_order_product_lookup"
        "${DB_PREFIX}wc_order_tax_lookup"
        "${DB_PREFIX}wc_order_coupon_lookup"
        "${DB_PREFIX}wc_download_log"
        "${DB_PREFIX}wc_webhooks"
        
        # Form Submissions
        "${DB_PREFIX}pf_submit"
        "${DB_PREFIX}pf_submit_meta"
        "${DB_PREFIX}gf_entry"
        "${DB_PREFIX}gf_entry_meta"
        "${DB_PREFIX}gf_entry_notes"
        
        # Logs and Sessions
        "${DB_PREFIX}actionscheduler_actions"
        "${DB_PREFIX}actionscheduler_logs"
        "${DB_PREFIX}woocommerce_sessions"
        "${DB_PREFIX}woocommerce_api_keys"
    )

    # Convert array to comma-separated list
    EXCLUDE_TABLES=$(IFS=,; echo "${TABLES_TO_EXCLUDE[*]}")

    # Export structure without data for excluded tables
    lando wp db export "${TEMP_DIR}/structure.sql" \
        --tables=$(echo "$EXCLUDE_TABLES" | tr ',' ' ') \
        --no-data \
        --quiet >/dev/null 2>&1

    # Then export data from safe tables (excluding sensitive ones)
    lando wp db export "${TEMP_DIR}/data.sql" \
        --exclude_tables=${EXCLUDE_TABLES} \
        --where="post_type NOT IN ('shop_order','shop_subscription','revision','wpcf7_contact_form')" \
        --quiet >/dev/null 2>&1

    # Combine files
    cat "${TEMP_DIR}/structure.sql" > "${TEMP_DIR}/database.sql"
    cat "${TEMP_DIR}/data.sql" >> "${TEMP_DIR}/database.sql"
    rm "${TEMP_DIR}/structure.sql" "${TEMP_DIR}/data.sql"

    # Add admin user
    cat >> "${TEMP_DIR}/database.sql" << EOF
-- Add admin user
INSERT INTO \`${DB_PREFIX}users\` VALUES (1,'${ADMIN_USER}',MD5('${ADMIN_PASS}'),'${ADMIN_USER}','${ADMIN_EMAIL}','','2024-01-01 00:00:00','',0,'Admin');
INSERT INTO \`${DB_PREFIX}usermeta\` VALUES (1,1,'${DB_PREFIX}capabilities','a:1:{s:13:\"administrator\";b:1;}');
INSERT INTO \`${DB_PREFIX}usermeta\` VALUES (2,1,'${DB_PREFIX}user_level','10');
EOF
else
    # Export entire database
    lando wp db export "${TEMP_DIR}/database.sql" --quiet >/dev/null 2>&1
fi

# Export wp-content
rsync -aq --delete --exclude 'upgrade' "wp-content/" "${TEMP_DIR}/wp-content/"

# Create final archive
tar -czf "${EXPORT_FILE}" -C "${TEMP_DIR}" .
rm -rf "$(dirname "${TEMP_DIR}")"

echo -e "\n${GREEN}Export complete!${NC}"
echo -e "Location: ${EXPORT_FILE}"
echo -e "Size: $(du -h "${EXPORT_FILE}" | cut -f1)"

# Cleanup function for interrupts
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    rm -rf "$(dirname "${TEMP_DIR}")"
    exit 1
}

trap cleanup INT TERM
