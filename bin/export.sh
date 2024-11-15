#!/bin/bash

# Source common paths and colors
source "$(dirname "$0")/helpers/variables.sh"
source "$(dirname "$0")/helpers/colors.sh"

# Source the .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
    echo "DEBUG - Table prefix from .env: ${DB_PREFIX}"
else
    echo "Error: .env file not found"
    exit 1
fi

# Create directories
mkdir -p "${TEMP_DIR}"
mkdir -p "$(dirname "${EXPORT_FILE}")"

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
        "${DB_PREFIX}woocommerce_sessions"
        "${DB_PREFIX}woocommerce_api_keys"
        "${DB_PREFIX}woocommerce_order_items"
        "${DB_PREFIX}woocommerce_order_itemmeta"

		# Polaris Forms
        "${DB_PREFIX}pf_submit"
        "${DB_PREFIX}pf_submit_meta"
        
        # Gravity Forms
        "${DB_PREFIX}gf_entry"
        "${DB_PREFIX}gf_entry_meta"
        "${DB_PREFIX}gf_entry_notes"
        "${DB_PREFIX}gf_form_revisions"
        "${DB_PREFIX}gf_form_view"

		# WPForms
        "${DB_PREFIX}wpforms_entries"
        "${DB_PREFIX}wpforms_entry_fields"
        "${DB_PREFIX}wpforms_entry_meta"
        "${DB_PREFIX}wpforms_tasks_meta"
        "${DB_PREFIX}wpforms_payment_meta"

		# Flamingo
        "${DB_PREFIX}flamingo_contact"
        "${DB_PREFIX}flamingo_inbound"
        "${DB_PREFIX}flamingo_outbound"
        
        # Logs and Sessions
        "${DB_PREFIX}actionscheduler_actions"
        "${DB_PREFIX}actionscheduler_claims"
        "${DB_PREFIX}actionscheduler_groups"
        "${DB_PREFIX}actionscheduler_logs"
        
        # Yoast SEO
        "${DB_PREFIX}yoast_indexable"
        "${DB_PREFIX}yoast_indexable_hierarchy"
        "${DB_PREFIX}yoast_migrations"
        "${DB_PREFIX}yoast_seo_links"
        "${DB_PREFIX}yoast_seo_meta"
        
        # Amazon/eBay Integration (if used)
        "${DB_PREFIX}amazon_feeds"
        "${DB_PREFIX}amazon_jobs"
        "${DB_PREFIX}amazon_log"
        "${DB_PREFIX}amazon_orders"
        "${DB_PREFIX}amazon_reports"
        "${DB_PREFIX}amazon_stock_log"
        "${DB_PREFIX}ebay_jobs"
        "${DB_PREFIX}ebay_log"
        "${DB_PREFIX}ebay_messages"
        "${DB_PREFIX}ebay_orders"
        "${DB_PREFIX}ebay_stocks_log"
        "${DB_PREFIX}ebay_transactions"
    )

    # Convert array to comma-separated list
    EXCLUDE_TABLES=$(IFS=,; echo "${TABLES_TO_EXCLUDE[*]}")
    
    # echo "DEBUG - Full exclude string: ${EXCLUDE_TABLES}"

    # Export database
    lando wp db export "${TEMP_DIR}/database.sql" --exclude_tables="${EXCLUDE_TABLES}" --quiet

    # Add admin user
    cat >> "${TEMP_DIR}/database.sql" << EOF
-- Add admin user
INSERT INTO \`${DB_PREFIX}users\` VALUES (1,'${ADMIN_USER}',MD5('${ADMIN_PASS}'),'${ADMIN_USER}','${ADMIN_EMAIL}','','2024-01-01 00:00:00','',0,'Admin');
INSERT INTO \`${DB_PREFIX}usermeta\` VALUES (1,1,'${DB_PREFIX}capabilities','a:1:{s:13:\"administrator\";b:1;}');
INSERT INTO \`${DB_PREFIX}usermeta\` VALUES (2,1,'${DB_PREFIX}user_level','10');
EOF
else
    # Export entire database
    lando wp db export "${TEMP_DIR}/database.sql" --quiet
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
