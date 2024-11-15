#!/bin/bash

# Timestamp (YYYY-MM-DD-HHMMSS)
TIMESTAMP=$(date "+%F-%H%M%S")

# Common paths for import/export scripts
DATA_DIR="data"
IMPORT_DIR="${DATA_DIR}/imports"
EXPORT_DIR="${DATA_DIR}/exports"

# Temp directories
TEMP_DIR="data/tmp/wp-export-${TIMESTAMP}"

# Export file
EXPORT_FILE_NAME="wordpress-${TIMESTAMP}.tar.gz"
EXPORT_FILE="${EXPORT_DIR}/${EXPORT_FILE_NAME}"
