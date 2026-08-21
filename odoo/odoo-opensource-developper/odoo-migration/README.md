# Odoo Community Migration Guide: 14.0 → 18.0

**Complete migration framework using OpenUpgrade for Odoo Community Edition**

This guide provides a **production-ready** migration path from **Odoo 14.0 → 15.0 → 16.0 → 17.0 → 18.0** using the official [OCA/OpenUpgrade](https://github.com/OCA/OpenUpgrade) project, integrated with your existing **Kubernetes/RKE2 infrastructure** from `docker-vps-prod-v14/`.

**Primary Question for Users:** *"Which is your list of modules you need to migrate?"*

---

## 🎯 **Overview: Multi-Version Migration**

```
Odoo 14.0 → Odoo 15.0 → Odoo 16.0 → Odoo 17.0 → Odoo 18.0
     ↓          ↓          ↓          ↓          ↓
  [14.0]    [15.0]    [16.0]    [17.0]    [18.0]
  OpenUpgrade branch
```

**Important**: OpenUpgrade **does not support skipping versions**. You **must** migrate sequentially through each major version.

---

## 📚 **Reference Documentation**

| Source | Description |
|--------|-------------|
| [OCA/OpenUpgrade GitHub](https://github.com/OCA/OpenUpgrade/tree/14.0) | Official repository with migration scripts |
| [OpenUpgrade Documentation](https://oca.github.io/OpenUpgrade/) | Complete migration guide and API reference |
| [Module Coverage Status](https://oca.github.io/OpenUpgrade/status.html) | Check which modules have migration scripts |
| [Your Entrypoint Script](docker-vps-prod-v14/odoo18-fnfe-front/start-entrypoint.d/004_open_upgrade) | Production-ready migration trigger |

---

## ✅ **Prerequisites**

### From Your Existing Infrastructure (`docker-vps-prod-v14/`)

Your environment already includes:
- ✅ **RKE2 Kubernetes Cluster** (OVH VPS)
- ✅ **PostgreSQL 14/16** (multi-version support)
- ✅ **Docker-based Odoo deployments** (Bedrock + Docky)
- ✅ **Git-aggregator (ak)** for multi-repo management
- ✅ **CI/CD Pipeline** (GitLab)
- ✅ **Persistent storage** for databases and filestores

### Required for Migration

| Component | Purpose | Your Existing Setup |
|-----------|---------|---------------------|
| OpenUpgrade 14.0 | 14.0 → 15.0 | Needs to be added |
| OpenUpgrade 15.0 | 15.0 → 16.0 | Needs to be added |
| OpenUpgrade 16.0 | 16.0 → 17.0 | Needs to be added |
| OpenUpgrade 17.0 | 17.0 → 18.0 | Needs to be added |
| openupgradelib | Migration utilities | `pip install git+https://github.com/OCA/openupgradelib.git@master` |
| PostgreSQL | Database storage | `postgres-14` service |
| Docker | Container runtime | Existing |
| Git | Version control | Existing |

---

## 📦 **Step 1: Prepare Migration Environment**

### 1.1 Clone OpenUpgrade Repositories

```bash
# Create migration workspace
mkdir -p /opt/odoo-migration/{14.0,15.0,16.0,17.0,18.0}
cd /opt/odoo-migration

# Clone all required OpenUpgrade branches
git clone --branch 14.0 https://github.com/OCA/OpenUpgrade.git 14.0
git clone --branch 15.0 https://github.com/OCA/OpenUpgrade.git 15.0
git clone --branch 16.0 https://github.com/OCA/OpenUpgrade.git 16.0
git clone --branch 17.0 https://github.com/OCA/OpenUpgrade.git 17.0
git clone --branch 18.0 https://github.com/OCA/OpenUpgrade.git 18.0

# Install openupgradelib
pip install git+https://github.com/OCA/openupgradelib.git@master#egg=openupgradelib
```

### 1.2 Install OpenUpgrade in Your Odoo Instances

For **each Odoo version**, ensure `openupgrade_framework` and `openupgrade_scripts` are in the addons path:

```bash
# For Odoo 14.0 instance
ln -s /opt/odoo-migration/14.0/openupgrade /odoo/14.0/links/openupgrade

# For Odoo 15.0 instance  
ln -s /opt/odoo-migration/15.0/openupgrade /odoo/15.0/links/openupgrade

# For Odoo 16.0 instance
ln -s /opt/odoo-migration/16.0/openupgrade /odoo/16.0/links/openupgrade

# For Odoo 17.0 instance
ln -s /opt/odoo-migration/17.0/openupgrade /odoo/17.0/links/openupgrade

# For Odoo 18.0 instance (target)
ln -s /opt/odoo-migration/18.0/openupgrade /odoo/18.0/links/openupgrade
```

### 1.3 Verify OpenUpgrade Installation

```bash
# For each version, check modules are available
odoo --addons-path=/odoo/14.0/links/openupgrade:/odoo/14.0/addons \
     --without-demo=all --stop-after-init \
     -d your_db -i openupgrade_framework,openupgrade_scripts
```

---

## 🔄 **Step 2: Migration Process (14.0 → 18.0)**

### **Critical Rule**: Always migrate **one version at a time** sequentially.

```
14.0 → 15.0 → 16.0 → 17.0 → 18.0
```

### 2.1 Phase 1: 14.0 → 15.0

```bash
# Environment variables for tracking
export OPENUPGRADE_TARGET_VERSION=15.0

# Using your entrypoint script pattern from docker-vps-prod-v14/
DB_NAME="your_database_14"
ODOO_VERSION="15.0"

# Migration command (based on your 004_open_upgrade script)
odoo \
  --logfile=/data/odoo/shared/migration_to_${ODOO_VERSION}.log \
  --update all \
  --upgrade-path=/odoo/links/openupgrade_scripts/scripts \
  --load=base,web,openupgrade_framework \
  --stop-after-init \
  -d ${DB_NAME} \
  --addons-path=/odoo/links/openupgrade,/odoo/addons
```

**Check for errors:**
```bash
tail -f /data/odoo/shared/migration_to_15.0.log | grep -i error
grep -i "not found" /data/odoo/shared/migration_to_15.0.log
grep -i "missing" /data/odoo/shared/migration_to_15.0.log
```

### 2.2 Phase 2: 15.0 → 16.0

```bash
export OPENUPGRADE_TARGET_VERSION=16.0

# Use the upgraded database
DB_NAME="your_database_15"  # Same DB, now at 15.0

odoo \
  --logfile=/data/odoo/shared/migration_to_16.0.log \
  --update all \
  --upgrade-path=/odoo/links/openupgrade_scripts/scripts \
  --load=base,web,openupgrade_framework \
  --stop-after-init \
  -d ${DB_NAME} \
  --addons-path=/odoo/links/openupgrade,/odoo/addons
```

### 2.3 Phase 3: 16.0 → 17.0

```bash
export OPENUPGRADE_TARGET_VERSION=17.0

odoo \
  --logfile=/data/odoo/shared/migration_to_17.0.log \
  --update all \
  --upgrade-path=/odoo/links/openupgrade_scripts/scripts \
  --load=base,web,openupgrade_framework \
  --stop-after-init \
  -d ${DB_NAME} \
  --addons-path=/odoo/links/openupgrade,/odoo/addons
```

### 2.4 Phase 4: 17.0 → 18.0 (Target)

```bash
export OPENUPGRADE_TARGET_VERSION=18.0

odoo \
  --logfile=/data/odoo/shared/migration_to_18.0.log \
  --update all \
  --upgrade-path=/odoo/links/openupgrade_scripts/scripts \
  --load=base,web,openupgrade_framework \
  --stop-after-init \
  -d ${DB_NAME} \
  --addons-path=/odoo/links/openupgrade,/odoo/addons
```

---

## 📋 **Step 3: Migration Script Generation**

**Primary Question for Users:** *"How can I help you on the script generation?"*

### 3.1 Identify Missing Migration Scripts

Before starting, check which modules need migration scripts:

```bash
# List all installed modules
psql -d your_database -c "SELECT name FROM ir_module_module WHERE state='installed'" -t | tr -d ' '

# Check OpenUpgrade coverage for each migration step
# Example for 14.0 → 15.0:
cd /opt/odoo-migration/14.0/openupgrade_scripts/scripts
find . -name "*.py" | sed 's|./||;s|/.*||' | sort | uniq
```

### 3.2 Generate Module List for Migration

Create a script to compare installed modules vs. available migration scripts:

```bash
#!/bin/bash
# save as: generate_migration_list.sh

DB_NAME="$1"
TARGET_VERSION="$2"
OPENUPGRADE_PATH="/opt/odoo-migration/${TARGET_VERSION}/openupgrade_scripts/scripts"

# Get installed modules
INSTALLED_MODULES=$(psql -d "$DB_NAME" -c "SELECT name FROM ir_module_module WHERE state='installed' AND name NOT LIKE 'base%' AND name NOT LIKE 'web%' AND name NOT LIKE 'openupgrade%'" -t | tr -d ' ' | grep -v "^$")

# Get available migration scripts
AVAILABLE_SCRIPTS=$(find "$OPENUPGRADE_PATH" -name "*.py" | sed 's|.*/||;s|\.py$||' | sort | uniq)

echo "=== Installed Modules ==="
echo "$INSTALLED_MODULES"
echo ""

echo "=== Available Migration Scripts ==="
echo "$AVAILABLE_SCRIPTS"
echo ""

echo "=== Missing Migration Scripts ==="
for module in $INSTALLED_MODULES; do
    if ! echo "$AVAILABLE_SCRIPTS" | grep -q "^${module}$"; then
        echo "$module"
    fi
done
```

**Usage:**
```bash
chmod +x generate_migration_list.sh
./generate_migration_list.sh your_database_14 14.0
```

### 3.3 Create Custom Migration Scripts

For modules without migration scripts, create them in the appropriate version directory:

```python
# Example: /opt/odoo-migration/14.0/openupgrade_scripts/scripts/your_custom_module.py

from openupgradelib import openupgrade

@openupgrade.migrate()
def migrate(cr, version):
    """Migration script for your_custom_module from 14.0 to 15.0"""
    
    # Example: Rename a field
    if openupgrade.column_exists(cr, 'your_table', 'old_field'):
        openupgrade.rename_columns(cr, {'your_table': [('old_field', 'new_field')]})
    
    # Example: Convert data
    cr.execute("""
        UPDATE your_table
        SET new_field = old_field
        WHERE old_field IS NOT NULL
    """)
    
    # Example: Add missing required fields
    openupgrade.add_fields(cr, [
        ('your_table', 'your_module', 'new_required_field', 'varchar')
    ])
```

**Common Migration Patterns:**
- Field renames: `openupgrade.rename_columns()`
- Field type changes: `openupgrade.convert_field()`
- Model renames: `openupgrade.rename_models()`
- XML ID updates: `openupgrade.update_xmlids()`
- Data conversions: Direct SQL or ORM
- Module dependencies: Update `__manifest__.py`

### 3.4 Test Migration Scripts

```bash
# Test a single module migration
odoo \
  --addons-path=/odoo/links/openupgrade,/odoo/addons \
  -d your_database \
  -i your_custom_module \
  --stop-after-init

# Run the migration
odoo \
  --addons-path=/odoo/links/openupgrade,/odoo/addons \
  --upgrade-path=/odoo/links/openupgrade_scripts/scripts \
  --load=base,web,openupgrade_framework,your_custom_module \
  --stop-after-init \
  -d your_database
```

---

## 🎛️ **Step 4: Production Migration Script (Based on Your Entrypoint)**

From your `docker-vps-prod-v14/odoo18-fnfe-front/start-entrypoint.d/004_open_upgrade`:

```bash
#!/bin/bash
# Production-Ready OpenUpgrade Migration Script
# Usage: ./migrate_database.sh <db_name> <target_version>

set -eu -o pipefail

DB_NAME="$1"
TARGET_VERSION="$2"
LOG_FILE="/data/odoo/shared/migration_to_${TARGET_VERSION}.log"

# Verify database exists and is initialized
if [ "$(psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")" != '1' ]; then
    echo "❌ Database $DB_NAME does not exist"
    exit 1
fi

if [ "$(psql $DB_NAME -tAc "SELECT 1 FROM pg_tables WHERE tablename='ir_config_parameter'")" != '1' ]; then
    echo "❌ Database $DB_NAME not initialized"
    exit 1
fi

# Check if database is incompatible (needs migration)
IS_DB_INCOMPATIBLE=$(python -c "from odoo import service; print(len(service.db.list_db_incompatible(('$DB_NAME',))) > 0)")

if [ "$IS_DB_INCOMPATIBLE" == "False" ]; then
    echo "✅ Database $DB_NAME is compatible with current version"
    exit 0
fi

# Verify OpenUpgrade is available
if [ ! -d "/odoo/links/openupgrade_scripts/" ]; then
    echo "❌ openupgrade_scripts not in the path"
    echo "Ensure openupgrade in spec.yaml"
    exit 1
fi

IS_OPENUPGRADE_AVAILABLE=$(python -c 'from odoo import modules, tools; tools.config.parse_config(); print(modules.get_module_path("openupgrade_framework") and modules.get_module_path("openupgrade_scripts"))')

if [ "$IS_OPENUPGRADE_AVAILABLE" ]; then
    echo "🚀 Starting OpenUpgrade Migration to ${TARGET_VERSION}..."
    echo "📝 Log file: ${LOG_FILE}"
    
    # Set target version environment variable
    export OPENUPGRADE_TARGET_VERSION="$TARGET_VERSION"
    
    # Run migration
    odoo \
      --logfile="$LOG_FILE" \
      --update all \
      --upgrade-path=/odoo/links/openupgrade_scripts/scripts \
      --load=base,web,openupgrade_framework \
      --stop-after-init \
      -d "$DB_NAME" || exit 1
    
    echo "✅ OpenUpgrade Migration to ${TARGET_VERSION} completed successfully"
    echo "📊 Log: $LOG_FILE"
    exit 0
else
    echo "❌ OpenUpgrade framework or scripts not available"
    exit 1
fi
```

---

## 📊 **Step 5: Multi-Version Migration Workflow**

### 5.1 Sequential Migration Script

```bash
#!/bin/bash
# Full 14.0 → 18.0 migration workflow
# Usage: ./migrate_full.sh <db_name>

set -eu -o pipefail

DB_NAME="$1"
BASE_DIR="/opt/odoo-migration"

# Function to migrate between versions
migrate_version() {
    local from_version="$1"
    local to_version="$2"
    
    echo "=========================================="
    echo "Migrating from ${from_version} to ${to_version}"
    echo "=========================================="
    
    # Set the addons path for this version
    export ODOO_ADDONS="/odoo/${from_version}/links/openupgrade:/odoo/${from_version}/addons"
    
    # Set target version
    export OPENUPGRADE_TARGET_VERSION="$to_version"
    
    # Run migration
    odoo \
      --addons-path="$ODOO_ADDONS" \
      --logfile="/data/odoo/shared/migration_to_${to_version}.log" \
      --update all \
      --upgrade-path="${BASE_DIR}/${from_version}/openupgrade_scripts/scripts" \
      --load=base,web,openupgrade_framework \
      --stop-after-init \
      -d "$DB_NAME" || return 1
    
    echo "✅ Migration to ${to_version} completed"
    return 0
}

# Main migration sequence
echo "Starting full migration: 14.0 → 18.0"
echo "Database: $DB_NAME"
echo ""

# 14.0 → 15.0
migrate_version 14.0 15.0 || { echo "❌ Migration failed at 14.0→15.0"; exit 1; }
echo ""

# 15.0 → 16.0  
migrate_version 15.0 16.0 || { echo "❌ Migration failed at 15.0→16.0"; exit 1; }
echo ""

# 16.0 → 17.0
migrate_version 16.0 17.0 || { echo "❌ Migration failed at 16.0→17.0"; exit 1; }
echo ""

# 17.0 → 18.0
migrate_version 17.0 18.0 || { echo "❌ Migration failed at 17.0→18.0"; exit 1; }
echo ""

echo "🎉 Full migration 14.0 → 18.0 completed successfully!"
```

### 5.2 Docker-Based Migration (For Your Kubernetes Environment)

```yaml
# Example Kubernetes Job for migration
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate-db-14-to-18
  namespace: fnfe-test
spec:
  template:
    spec:
      containers:
      - name: migration
        image: ghcr.io/akretion/odoo-docker:18.0-light
        command: ["/bin/bash", "-c"]
        args:
          - |
            set -eu
            # Wait for PostgreSQL
            until pg_isready -h postgres-14 -p 5432; do sleep 5; done
            
            # Run full migration
            /app/entrypoint.sh migrate_database.sh production_db 18.0
        env:
        - name: DB_NAME
          value: "production_db"
        - name: PGHOST
          value: "postgres-14"
        - name: PGUSER
          value: "odoo"
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: odoo-db
              key: password
      restartPolicy: Never
```

---

## 📝 **Step 6: Post-Migration Checklist**

### 6.1 Verify Migration Success

```bash
# Check database version
psql -d your_database -c "SELECT latest_version FROM ir_module_module WHERE name='base'" -t

# Verify all modules are installed and up-to-date
psql -d your_database -c "SELECT name, state, latest_version FROM ir_module_module WHERE state='installed' AND latest_version IS NOT NULL" -t

# Check for migration errors in logs
grep -i "error\|fail\|migration" /data/odoo/shared/migration_to_*.log
```

### 6.2 Test Critical Functionality

```bash
# Start Odoo with the migrated database
odoo -d your_database --http-port=8069

# Run automated tests (if available)
python -m pytest /addons/your_module/tests/
```

### 6.3 Backup Migrated Database

```bash
# Create a backup of the migrated database
pg_dump -Fc -d your_database -f /backups/your_database_migrated_to_18.0.dump

# Or using Odoo
odoo -d your_database -c /etc/odoo/backup.conf --db_name=your_database --backup-format=zip
```

---

## 🔧 **Step 7: Handling Common Issues**

### Issue 1: Missing Migration Scripts

**Symptom:** `Module X has no migration script from 14.0 to 15.0`

**Solution:**
```bash
# Find similar modules with migration scripts
find /opt/odoo-migration/14.0/openupgrade_scripts/scripts -name "*.py" | head -20

# Create a minimal migration script
cat > /opt/odoo-migration/14.0/openupgrade_scripts/scripts/your_module.py << 'EOF'
from openupgradelib import openupgrade

@openupgrade.migrate()
def migrate(cr, version):
    """Minimal migration for your_module"""
    # Add any necessary conversions here
    pass
EOF
```

### Issue 2: Database Incompatibility

**Symptom:** `Database is incompatible with current version`

**Solution:**
```bash
# Check what's incompatible
python -c "from odoo import service; print(service.db.list_db_incompatible(('your_db',)))"

# Check installed modules vs available modules
psql -d your_db -c "SELECT name FROM ir_module_module WHERE state='installed'" -t
```

### Issue 3: Module Loading Errors

**Symptom:** `Module not found` or `ImportError`

**Solution:**
```bash
# Verify the module path
python -c "from odoo import modules; print(modules.get_module_path('your_module'))"

# Check addons path
odoo --addons-path=/path/to/addons --without-demo=all --stop-after-init -d your_db -i your_module
```

### Issue 4: Field/Column Conflicts

**Symptom:** `column X does not exist` or `duplicate column`

**Solution:**
```python
# In your migration script
from openupgradelib import openupgrade

@openupgrade.migrate()
def migrate(cr, version):
    # Check if column exists before renaming
    if openupgrade.column_exists(cr, 'your_table', 'old_column'):
        # Rename column
        openupgrade.rename_columns(cr, {'your_table': [('old_column', 'new_column')]})
    
    # Or create missing column
    if not openupgrade.column_exists(cr, 'your_table', 'new_column'):
        openupgrade.add_fields(cr, [
            ('your_table', 'your_module', 'new_column', 'varchar')
        ])
```

### Issue 5: XML ID Conflicts

**Symptom:** `XML ID already exists`

**Solution:**
```python
# In your migration script
from openupgradelib import openupgrade

@openupgrade.migrate()
def migrate(cr, version):
    # Rename XML IDs
    openupgrade.update_xmlids(cr, {
        'old_module.old_id': 'new_module.new_id'
    })
    
    # Or merge records
    openupgrade.merge_records(cr, 'your_model', [old_id1, old_id2], new_id)
```

---

## 📊 **Step 8: Module Coverage Analysis**

### 8.1 Check Official Coverage

Visit: [https://oca.github.io/OpenUpgrade/status.html](https://oca.github.io/OpenUpgrade/status.html)

For **14.0 → 15.0**: [Module Coverage 14.0→15.0](https://oca.github.io/OpenUpgrade/coverage_analysis/modules140-150.html)

For **15.0 → 16.0**: [Module Coverage 15.0→16.0](https://oca.github.io/OpenUpgrade/coverage_analysis/modules150-160.html)

For **16.0 → 17.0**: [Module Coverage 16.0→17.0](https://oca.github.io/OpenUpgrade/coverage_analysis/modules160-170.html)

For **17.0 → 18.0**: [Module Coverage 17.0→18.0](https://oca.github.io/OpenUpgrade/coverage_analysis/modules170-180.html)

### 8.2 Generate Coverage Report

```bash
#!/bin/bash
# Generate coverage report for your module list

MODULES_FILE="your_modules.txt"  # One module per line
COVERAGE_REPORT="migration_coverage_report.md"

echo "# Migration Coverage Report" > "$COVERAGE_REPORT"
echo "Generated: $(date)" >> "$COVERAGE_REPORT"
echo "" >> "$COVERAGE_REPORT"

# Check each version migration
for version in 14.0 15.0 16.0 17.0; do
    next_version=$(echo "$version + 1.0" | bc)
    echo "## ${version} → ${next_version}" >> "$COVERAGE_REPORT"
    echo "" >> "$COVERAGE_REPORT"
    
    while IFS= read -r module; do
        scripts_path="/opt/odoo-migration/${version}/openupgrade_scripts/scripts"
        if [ -f "${scripts_path}/${module}.py" ]; then
            echo "✅ $module" >> "$COVERAGE_REPORT"
        else
            echo "❌ $module" >> "$COVERAGE_REPORT"
        fi
    done < "$MODULES_FILE"
    
    echo "" >> "$COVERAGE_REPORT"
done

echo "Report generated: $COVERAGE_REPORT"
```

---

## 🔄 **Step 9: Rollback Procedure**

### 9.1 Database Rollback

```bash
#!/bin/bash
# Rollback migration if issues are found

DB_NAME="$1"
BACKUP_FILE="$2"

# Stop Odoo services using the migrated database
# (Add your specific stop commands here)

echo "Rolling back database $DB_NAME from backup $BACKUP_FILE..."

# Drop current database
dropdb -U odoo "$DB_NAME" || true

# Restore from backup
createdb -U odoo "$DB_NAME" -T template0
pg_restore -U odoo -d "$DB_NAME" "$BACKUP_FILE"

# Or using pg_dump format
pg_restore -U odoo -d "$DB_NAME" "$BACKUP_FILE"

echo "✅ Database rolled back to $BACKUP_FILE"
```

### 9.2 Checkpoint System

```bash
#!/bin/bash
# Create checkpoints during migration

DB_NAME="$1"
CHECKPOINT_DIR="/backups/checkpoints"

mkdir -p "$CHECKPOINT_DIR"

# Create checkpoint before migration
pg_dump -Fc -d "$DB_NAME" -f "${CHECKPOINT_DIR}/${DB_NAME}_pre_migration.dump"

# Create checkpoint after each version
for version in 15.0 16.0 17.0 18.0; do
    pg_dump -Fc -d "$DB_NAME" -f "${CHECKPOINT_DIR}/${DB_NAME}_after_${version}.dump"
done
```

---

## 📚 **Step 10: Additional Resources**

### 10.1 OpenUpgrade Development

- [Migration Script Development Guide](https://oca.github.io/OpenUpgrade/080_migration_script_development.html)
- [Contribute New Scripts](https://oca.github.io/OpenUpgrade/090_contribute.html)
- [GitHub Issues](https://github.com/OCA/OpenUpgrade/issues)

### 10.2 Your Infrastructure References

- **docker-vps-prod-v14/odoo-k8s-readme.md** - Kubernetes setup
- **docker-vps-prod-v14/odoo18-AK-template_README.md** - Odoo 18 deployment
- **docker-vps-prod-v14/odoo18-fnfe-front/start-entrypoint.d/004_open_upgrade** - Production migration trigger

### 10.3 OCA Community Resources

- [OCA Migration Mailing List](https://odoo-community.org/groups/contributors-15)
- [OpenUpgrade Wiki](https://github.com/OCA/OpenUpgrade/wiki)
- [OCA Discord](https://discord.gg/odoo) - #migration channel

---

## ✅ **Quick Reference Commands**

| Task | Command |
|------|---------|
| **Check OpenUpgrade version** | `git -C /opt/odoo-migration/14.0 log --oneline -1` |
| **List available migration scripts** | `find /opt/odoo-migration/14.0/openupgrade_scripts/scripts -name "*.py" \| wc -l` |
| **Check module coverage** | `curl -s https://oca.github.io/OpenUpgrade/status.html \| grep -i your_module` |
| **Run single migration** | `odoo --upgrade-path=/path/to/scripts --load=base,web,openupgrade_framework --stop-after-init -d db_name` |
| **Check database version** | `psql -d db_name -c "SELECT latest_version FROM ir_module_module WHERE name='base'" -t` |
| **Backup database** | `pg_dump -Fc -d db_name -f backup.dump` |
| **Restore database** | `pg_restore -d db_name -f backup.dump` |

---

## 🎯 **Summary: Migration Checklist**

- [ ] **Identify** all installed modules in source database
- [ ] **Check** coverage for each module at each migration step
- [ ] **Create** custom migration scripts for missing modules
- [ ] **Test** each migration step individually (14→15, 15→16, 16→17, 17→18)
- [ ] **Backup** database before each migration step
- [ ] **Verify** data integrity after each migration
- [ ] **Deploy** to production with rollback plan
- [ ] **Monitor** production database after migration

---

## 💬 **User Interaction Guide**

**When chatting with users about migration, ALWAYS ask:**

1. **"Which is your list of modules you need to migrate?"**
   - This helps identify coverage gaps
   - Allows generation of custom migration scripts
   - Estimates migration complexity

2. **"How can I help you on the script generation?"**
   - Offer to create missing migration scripts
   - Provide templates for common patterns
   - Review existing custom scripts

3. **Additional helpful questions:**
   - "Do you have any custom modules?"
   - "Are you using any third-party modules?"
   - "What is your database size?"
   - "Do you have a test environment for migration?"
   - "What is your target deployment date?"

---

## 📞 **Support & Troubleshooting**

### Getting Help

1. **Check logs:** `tail -f /data/odoo/shared/migration_to_*.log`
2. **Review OpenUpgrade issues:** [GitHub Issues](https://github.com/OCA/OpenUpgrade/issues)
3. **Ask in OCA community:** [OCA Discord #migration](https://discord.gg/odoo)
4. **Consult documentation:** [OpenUpgrade Docs](https://oca.github.io/OpenUpgrade/)

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `Module X not found` | Missing in addons path | Check `--addons-path` parameter |
| `No migration script` | Module not in OpenUpgrade | Create custom script or request from OCA |
| `Column not found` | Schema changed | Use `openupgrade.rename_columns()` or add column |
| `XML ID conflict` | Duplicate external IDs | Use `openupgrade.update_xmlids()` |
| `Database incompatible` | Version mismatch | Run migration for previous version first |
| `Connection refused` | PostgreSQL not running | Check PostgreSQL service |
| `Permission denied` | Database user permissions | Grant proper permissions to user |

---

*This guide integrates OpenUpgrade best practices with your existing infrastructure from `docker-vps-prod-v14/`.*
