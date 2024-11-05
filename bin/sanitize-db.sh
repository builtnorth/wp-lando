#!/bin/bash

# Colors for output (if not already defined)
RED=${RED:-'\033[0;31m'}
GREEN=${GREEN:-'\033[0;32m'}
YELLOW=${YELLOW:-'\033[1;33m'}
NC=${NC:-'\033[0m'}

# Function to sanitize user data
sanitize_users() {
    echo "Removing user data..."
    lando wp db query "DELETE FROM wp_users WHERE ID > 1;"
    lando wp db query "DELETE FROM wp_usermeta WHERE user_id > 1;"
    
    # Reset admin user
    lando wp user update 1 --user_email="admin@example.com" --display_name="Admin" --first_name="" --last_name=""
}

# Function to remove comments
sanitize_comments() {
    echo "Removing comments..."
    lando wp db query "TRUNCATE wp_comments;"
    lando wp db query "TRUNCATE wp_commentmeta;"
}

# Function to clean form submissions
sanitize_forms() {

	# Polaris Forms
	if lando wp plugin is-active polaris-forms; then
		echo "Checking for Polaris Forms submissions...";
		lando wp db query "TRUNCATE TABLE wp_pf_submit;"
		lando wp db query "TRUNCATE TABLE wp_pf_submit_meta;"
	fi

    # Contact Form 7
    if lando wp plugin is-active contact-form-7; then
	    echo "Checking for Contact Form 7 submissions...";
        lando wp db query "DELETE FROM wp_posts WHERE post_type = 'wpcf7_contact_form';"
    fi
    
    # Gravity Forms
    if lando wp plugin is-active gravityforms; then
	    echo "Checking for Gravity Forms entries...";
        lando wp db query "TRUNCATE TABLE wp_gf_entry;"
        lando wp db query "TRUNCATE TABLE wp_gf_entry_meta;"
        lando wp db query "TRUNCATE TABLE wp_gf_entry_notes;"
    fi
}

# Function to clean WooCommerce data
sanitize_woocommerce() {
    if lando wp plugin is-active woocommerce; then
	    echo "Checking for WooCommerce data...";
        lando wp db query "DELETE FROM wp_posts WHERE post_type IN ('shop_order', 'shop_order_refund');"
        lando wp db query "DELETE FROM wp_postmeta WHERE post_id NOT IN (SELECT ID FROM wp_posts);"
        lando wp db query "TRUNCATE TABLE wp_wc_customer_lookup;"
        lando wp db query "TRUNCATE TABLE wp_wc_order_stats;"
        lando wp db query "TRUNCATE TABLE wp_wc_order_product_lookup;"
        lando wp db query "TRUNCATE TABLE wp_wc_order_tax_lookup;"
        lando wp db query "TRUNCATE TABLE wp_wc_order_coupon_lookup;"
    fi
}

# Main sanitization function
sanitize_database() {
    echo -e "\n${YELLOW}⚠️  Database Sanitization Warning${NC}"
    echo -e "This will remove Personal Identifiable Information (PII):"
    echo -e "- User data (emails, names, passwords)"
    echo -e "- Form submissions (Contact Form 7, Gravity Forms, etc.)"
    echo -e "- Comments"
    echo -e "- Order/Customer data (if WooCommerce is installed)"
    
    read -p "Would you like to remove PII data? (y/n): " SANITIZE_DB
    
    if [[ "${SANITIZE_DB}" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Removing PII data...${NC}"
        
        sanitize_users
        sanitize_comments
        sanitize_forms
        sanitize_woocommerce
        
        echo -e "${GREEN}✓${NC} PII data removed"
        return 0
    fi
    return 1
} 