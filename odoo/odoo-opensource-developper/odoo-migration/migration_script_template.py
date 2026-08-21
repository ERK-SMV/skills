#!/usr/bin/env python3
"""
OpenUpgrade Migration Script Template

This template provides a starting point for creating custom migration scripts
for modules that are not covered by the official OpenUpgrade scripts.

Usage:
1. Copy this file to: /opt/odoo-migration/{VERSION}/openupgrade_scripts/scripts/{module_name}.py
2. Replace placeholders with actual values
3. Add your migration logic
4. Test thoroughly

References:
- https://oca.github.io/OpenUpgrade/080_migration_script_development.html
- https://github.com/OCA/openupgradelib
"""

from openupgradelib import openupgrade


# ============================================================================
# MIGRATION METADATA
# ============================================================================

@openupgrade.migrate(use_typing=True)
def migrate(env, version):
    """
    Migration script for {module_name} from {from_version} to {to_version}.
    
    This script handles:
    - Field renames and type changes
    - Model renames
    - XML ID updates
    - Data conversions
    - Module dependency updates
    
    Note: OpenUpgrade runs this script during the migration process.
    The database is in a transitional state - some models may not be fully loaded.
    """
    
    # ========================================================================
    # 1. PRE-MIGRATION CHECKS
    # ========================================================================
    
    # Check if this migration has already been run
    if openupgrade.is_module_installed(env.cr, 'your_module'):
        # Module is being migrated, continue with migration
        pass
    
    # ========================================================================
    # 2. FIELD RENAMES
    # ========================================================================
    
    # Example: Rename a field from 'old_name' to 'new_name'
    # if openupgrade.column_exists(env.cr, 'your_table', 'old_name'):
    #     openupgrade.rename_columns(
    #         env.cr, 
    #         {'your_table': [('old_name', 'new_name')]}
    #     )
    
    # Multiple field renames in the same table
    # if openupgrade.column_exists(env.cr, 'your_table', 'old_field_1'):
    #     openupgrade.rename_columns(
    #         env.cr,
    #         {'your_table': [
    #             ('old_field_1', 'new_field_1'),
    #             ('old_field_2', 'new_field_2'),
    #         ]}
    #     )
    
    # ========================================================================
    # 3. FIELD TYPE CHANGES
    # ========================================================================
    
    # Example: Convert varchar to text
    # openupgrade.convert_field(
    #     env.cr, 'your.model', 'field_name', 'text'
    # )
    
    # Example: Convert integer to float
    # openupgrade.convert_field(
    #     env.cr, 'your.model', 'field_name', 'float'
    # )
    
    # Example: Convert selection field
    # openupgrade.convert_field(
    #     env.cr, 
    #     'your.model', 
    #     'field_name',
    #     'selection',
    #     [('old_value_1', 'New Label 1'), ('old_value_2', 'New Label 2')]
    # )
    
    # ========================================================================
    # 4. MODEL RENAMES
    # ========================================================================
    
    # Example: Rename a model
    # if openupgrade.table_exists(env.cr, 'old_model_name'):
    #     openupgrade.rename_models(
    #         env.cr, [('old_model_name', 'new_model_name')]
    #     )
    
    # ========================================================================
    # 5. XML ID UPDATES
    # ========================================================================
    
    # Example: Update XML IDs
    # openupgrade.update_xmlids(
    #     env.cr,
    #     {
    #         'old_module.old_id': 'new_module.new_id',
    #         'old_module.another_old_id': 'new_module.another_new_id',
    #     }
    # )
    
    # Example: Rename XML IDs with pattern
    # openupgrade.rename_xmlids(
    #     env.cr,
    #     {
    #         'old_prefix_%': 'new_prefix_%',
    #     }
    # )
    
    # ========================================================================
    # 6. DATA CONVERSIONS
    # ========================================================================
    
    # Example: Simple SQL update
    # env.cr.execute("""
    #     UPDATE your_table
    #     SET new_field = old_field
    #     WHERE old_field IS NOT NULL
    # """)
    
    # Example: Complex data transformation
    # env.cr.execute("""
    #     UPDATE product_template
    #     SET list_price = list_price * 1.19
    #     WHERE list_price > 0
    # """)
    
    # Example: JSON field update
    # env.cr.execute("""
    #     UPDATE your_model
    #     SET json_field = json_field || '{"new_key": "new_value"}'
    #     WHERE json_field IS NOT NULL
    # """)
    
    # ========================================================================
    # 7. RECORD MERGES
    # ========================================================================
    
    # Example: Merge duplicate records
    # openupgrade.merge_records(
    #     env.cr,
    #     'your.model',
    #     [old_id_1, old_id_2, old_id_3],
    #     new_id
    # )
    
    # ========================================================================
    # 8. VALUE CONVERSIONS
    # ========================================================================
    
    # Example: Convert string to integer
    # openupgrade.convert_field_value(
    #     env.cr,
    #     'your.model',
    #     'field_name',
    #     lambda r: int(r.get('field_name', 0) or 0)
    # )
    
    # ========================================================================
    # 9. ADD MISSING COLUMNS
    # ========================================================================
    
    # Example: Add a new required field
    # if not openupgrade.column_exists(env.cr, 'your_table', 'new_required_field'):
    #     openupgrade.add_fields(
    #         env.cr,
    #         [
    #             ('your_table', 'your_module', 'new_required_field', 'varchar'),
    #             ('your_table', 'your_module', 'another_field', 'integer'),
    #         ]
    #     )
    
    # ========================================================================
    # 10. NOTIFICATIONS
    # ========================================================================
    
    # Example: Log a warning for manual review
    # openupgrade.logged_query(
    #     env.cr,
    #     """
    #     SELECT id, name
    #     FROM your_model
    #     WHERE deprecated_field IS NOT NULL
    #     """,
    #     'Your deprecation warning message here'
    # )
    
    # ========================================================================
    # 11. MODULE DEPENDENCY UPDATES
    # ========================================================================
    
    # Example: Update module dependencies
    # This is typically handled in __manifest__.py, not in migration scripts
    # But you can log warnings if dependencies are missing
    # missing_deps = openupgrade.get_missing_dependencies(
    #     env.cr, 'your_module', ['dep1', 'dep2']
    # )
    # if missing_deps:
    #     openupgrade.logged_query(
    #         env.cr,
    #         "SELECT 1",
    #         f"Missing dependencies for your_module: {missing_deps}"
    #     )
    
    # ========================================================================
    # 12. POST-MIGRATION CLEANUP
    # ========================================================================
    
    # Example: Remove obsolete fields after migration
    # if openupgrade.column_exists(env.cr, 'your_table', 'obsolete_field'):
    #     openupgrade.drop_columns(
    #         env.cr, ['your_table'], ['obsolete_field']
    #     )
    
    # Example: Update module state
    # openupgrade.update_module_states(
    #     env.cr,
    #     [('your_module', 'installed')]
    # )


# ============================================================================
# MIGRATION ANALYSIS FUNCTION (Optional)
# ============================================================================

@openupgrade.post_migration()
def post_migration(env, version):
    """
    Post-migration checks and validations.
    
    This function runs after all modules have been migrated.
    Use it for final validations and cleanup.
    """
    # Example: Verify all records have been migrated
    # env.cr.execute("""
    #     SELECT COUNT(*)
    #     FROM your_table
    #     WHERE migration_status != 'completed'
    # """)
    # count = env.cr.fetchone()[0]
    # if count > 0:
    #     openupgrade.logged_query(
    #         env.cr,
    #         "SELECT id, name FROM your_table WHERE migration_status != 'completed'",
    #         f"{count} records still need migration"
    #     )
    
    pass


# ============================================================================
# COMMON HELPER FUNCTIONS
# ============================================================================

def _get_model(env, model_name):
    """Get an Odoo model."""
    try:
        return env[model_name]
    except KeyError:
        return None


def _table_exists(env, table_name):
    """Check if a table exists."""
    return openupgrade.table_exists(env.cr, table_name)


def _column_exists(env, table_name, column_name):
    """Check if a column exists in a table."""
    return openupgrade.column_exists(env.cr, table_name, column_name)


def _safe_execute(env, sql, params=None):
    """Execute SQL safely with error handling."""
    try:
        env.cr.execute(sql, params or ())
        return True
    except Exception as e:
        openupgrade.logged_query(
            env.cr,
            "SELECT 1",
            f"SQL Error: {e}\nSQL: {sql}"
        )
        return False
