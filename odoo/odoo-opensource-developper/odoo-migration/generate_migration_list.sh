#!/bin/bash
# Migration Module List Generator
# Usage: ./generate_migration_list.sh <database_name> <target_version> [openupgrade_path]
# Example: ./generate_migration_list.sh my_database_14 14.0 /opt/odoo-migration/14.0/openupgrade_scripts/scripts

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <database_name> <target_version> [openupgrade_path]"
    echo "Example: $0 my_database_14 14.0 /opt/odoo-migration/14.0/openupgrade_scripts/scripts"
    exit 1
fi

DB_NAME="$1"
TARGET_VERSION="$2"
OPENUPGRADE_PATH="${3:-/opt/odoo-migration/${TARGET_VERSION}/openupgrade_scripts/scripts}"

# Verify database connection
if ! psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo "❌ Database '$DB_NAME' does not exist"
    exit 1
fi

echo "🔍 Analyzing migration requirements for database: $DB_NAME"
echo "📊 Target version: $TARGET_VERSION"
echo ""

# Get installed modules (excluding base/web/openupgrade)
INSTALLED_MODULES=$(psql -d "$DB_NAME" -c "
    SELECT name 
    FROM ir_module_module 
    WHERE state='installed' 
      AND name NOT LIKE 'base%' 
      AND name NOT LIKE 'web%' 
      AND name NOT LIKE 'openupgrade%' 
      AND name NOT LIKE 'auth%' 
      AND name NOT LIKE 'mail%' 
    ORDER BY name
" -t | tr -d ' ' | grep -v "^$")

# Get available migration scripts
AVAILABLE_SCRIPTS=$(find "$OPENUPGRADE_PATH" -maxdepth 1 -name "*.py" 2>/dev/null | xargs -n1 basename | sed 's/\.py$//' | sort)

echo "=== 📋 INSTALLED MODULES ==="
echo "$INSTALLED_MODULES" | nl
echo ""

echo "=== ✅ AVAILABLE MIGRATION SCRIPTS ==="
if [ -z "$AVAILABLE_SCRIPTS" ]; then
    echo "⚠️ No migration scripts found at: $OPENUPGRADE_PATH"
else
    echo "$AVAILABLE_SCRIPTS" | nl
fi
echo ""

echo "=== ❌ MISSING MIGRATION SCRIPTS ==="
MISSING_COUNT=0
MISSING_MODULES=""

for module in $INSTALLED_MODULES; do
    if ! echo "$AVAILABLE_SCRIPTS" | grep -qx "$module"; then
        echo "$module"
        MISSING_MODULES="${MISSING_MODULES}${module} "
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done

echo ""

if [ $MISSING_COUNT -eq 0 ]; then
    echo "✅ All installed modules have migration scripts!"
else
    echo "⚠️  $MISSING_COUNT modules are missing migration scripts"
    echo ""
    echo "=== 📝 RECOMMENDATION ==="
    echo "You need to create migration scripts for these modules:"
    echo "$MISSING_MODULES"
    echo ""
    echo "Use this template for each missing module:"
    cat << 'EOF'

# Template for custom migration script
# Save as: /opt/odoo-migration/{VERSION}/openupgrade_scripts/scripts/{module_name}.py

from openupgradelib import openupgrade

@openupgrade.migrate()
def migrate(cr, version):
    """
    Migration script for {module_name} from {FROM_VERSION} to {TO_VERSION}
    
    Check the official documentation for migration patterns:
    https://oca.github.io/OpenUpgrade/080_migration_script_development.html
    """
    # Add your migration logic here
    # Common patterns:
    
    # 1. Field renames
    # if openupgrade.column_exists(cr, 'table_name', 'old_field'):
    #     openupgrade.rename_columns(cr, {'table_name': [('old_field', 'new_field')]})
    
    # 2. Field type changes
    # openupgrade.convert_field(cr, 'model_name', 'field_name', 'new_type')
    
    # 3. XML ID updates
    # openupgrade.update_xmlids(cr, {'old_module.old_id': 'new_module.new_id'})
    
    # 4. Data conversion
    # cr.execute("UPDATE table_name SET new_field = old_field WHERE old_field IS NOT NULL")
    
    pass
EOF
fi

echo ""
echo "=== 📊 COVERAGE SUMMARY ==="
TOTAL_MODULES=$(echo "$INSTALLED_MODULES" | wc -w)
COVERED_MODULES=$((TOTAL_MODULES - MISSING_COUNT))
COVERAGE_PCT=$(echo "scale=1; $COVERED_MODULES * 100 / $TOTAL_MODULES" | bc)

echo "Total installed modules: $TOTAL_MODULES"
echo "Modules with migration scripts: $COVERED_MODULES"
echo "Modules missing scripts: $MISSING_COUNT"
echo "Coverage: ${COVERAGE_PCT}%"
