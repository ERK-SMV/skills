---
name: odoo-oca-developer
description: Develop and migrate Odoo modules (14.0-19.0) per OCA rules. Includes Kubernetes integration for Odoo deployment and management.
---

## Table of Contents

1. [Scope](#scope)
2. [Core Capabilities](#core-capabilities)
3. [Workflow Decision Tree](#workflow-decision-tree)
4. [Resources](#resources)
5. [Best Practices](#best-practices)
6. [Common Patterns](#common-patterns)
7. [Troubleshooting](#troubleshooting)
8. [Quick Reference](#quick-reference)
9. [Kubernetes RBAC and Security Best Practices](#kubernetes-rbac-and-security-best-practices)
10. [Kubernetes Integration for Odoo Development](#kubernetes-integration-for-odoo-development)
11. [Akretion Docker Compose Infrastructure](#akretion-docker-compose-infrastructure)
12. [Usage Examples](#usage-examples)
13. [Triggers](#triggers)

## Scope

Expert guidance for developing, migrating, and maintaining Odoo modules (versions 14.0-19.0) following OCA conventions. Use when working with Odoo modules to create new modules from OCA template, migrate modules between versions using OpenUpgrade, extend core Odoo modules, ensure OCA compliance, and structure module files correctly. Includes OCA coding standards, module structure templates, OpenUpgrade migration patterns, validation tools, and Kubernetes integration for deployment and management.

## Core Capabilities

### 1. Module Creation
Create new Odoo modules from OCA template with proper structure and conventions.

**Quick Start:**
```bash
python scripts/init_oca_module.py my_module_name --path /path/to/addons --version 17.0
```

**What this provides:**
- Complete OCA-compliant directory structure
- Pre-configured `__manifest__.py` with required keys
- README structure following OCA guidelines
- Proper `__init__.py` imports
- Example model, view, and security files

**Module naming conventions:**
- Use singular form: `sale_order_import` (not `sale_orders_import`)
- For base modules: prefix with `base_` (e.g., `base_location_nuts`)
- For localization: prefix with `l10n_CC_` (e.g., `l10n_es_pos`)
- For extensions: prefix with parent module (e.g., `mail_forward`)
- For combinations: Odoo module first (e.g., `crm_partner_firstname`)

### 2. Module Structure

Follow OCA conventions strictly. Reference [oca_conventions.md](references/oca_conventions.md) for detailed guidelines.

**Essential structure:**
```
module_name/
├── __init__.py
├── __manifest__.py
├── models/
│   ├── __init__.py
│   └── <model_name>.py
├── views/
│   └── <model_name>_views.xml
├── security/
│   ├── ir.model.access.csv
│   └── <model_name>_security.xml
├── data/
│   └── <model_name>_data.xml
├── readme/
│   ├── DESCRIPTION.rst
│   ├── USAGE.rst
│   └── CONTRIBUTORS.rst
└── tests/
    ├── __init__.py
    └── test_<feature>.py
```

**Key principles:**
- One file per model: `models/sale_order.py`
- Views match model names: `views/sale_order_views.xml`
- Demo data has `_demo` suffix: `demo/sale_order_demo.xml`
- Migrations in versioned folders: `migrations/17.0.1.0.0/`

### 3. OCA Conventions Compliance

**__manifest__.py essentials:**
```python
{
    'name': 'Module Name',
    'version': '17.0.1.0.0',  # {odoo}.x.y.z format
    'category': 'Sales',
    'license': 'AGPL-3',  # or LGPL-3
    'author': 'Your Company, Odoo Community Association (OCA)',
    'website': 'https://github.com/OCA/<repository>',
    'depends': ['base', 'sale'],
    'data': [
        'security/ir.model.access.csv',
        'views/model_name_views.xml',
    ],
    'installable': True,
}
```

**Python code structure:**
```python
from odoo import api, fields, models, _
from odoo.exceptions import UserError

class SaleOrder(models.Model):
    _inherit = 'sale.order'
    
    # Fields
    custom_field = fields.Char(string="Custom Field")
    
    # Compute methods
    @api.depends('order_line')
    def _compute_total(self):
        for order in self:
            order.total = sum(order.order_line.mapped('price_total'))
    
    # Business methods
    def action_custom(self):
        self.ensure_one()
        # Implementation
```

**XML naming conventions:**
- Views: `<model_name>_view_<type>` (e.g., `sale_order_view_form`)
- Actions: `<model_name>_action` (e.g., `sale_order_action`)
- Menus: `<model_name>_menu`
- Groups: `<model_name>_group_<name>`
- Demo: suffix with `_demo`

### 4. Module Migration with OpenUpgrade

Migrate modules between Odoo versions following OpenUpgrade patterns. See [openupgrade_migration.md](references/openupgrade_migration.md) for complete guide.

**Migration structure:**
```
module_name/
└── migrations/
    └── 17.0.1.0.0/
        ├── pre-migration.py
        ├── post-migration.py
        └── noupdate_changes.xml
```

**Pre-migration example:**
```python
from openupgradelib import openupgrade

@openupgrade.migrate()
def migrate(env, version):
    # Rename fields before module loads
    openupgrade.rename_fields(env, [
        ('sale.order', 'sale_order', 'old_field', 'new_field'),
    ])
    
    # Rename models
    openupgrade.rename_models(env.cr, [
        ('old.model', 'new.model'),
    ])
```

**Post-migration example:**
```python
from openupgradelib import openupgrade

@openupgrade.migrate()
def migrate(env, version):
    # Map old values to new
    openupgrade.map_values(
        env.cr,
        openupgrade.get_legacy_name('state'),
        'state',
        [('draft', 'pending'), ('confirm', 'confirmed')],
        table='sale_order',
    )
    
    # Recompute fields
    env['sale.order'].search([])._compute_total()
```

**Common migration tasks:**
- Rename fields: `openupgrade.rename_fields()`
- Rename models: `openupgrade.rename_models()`
- Rename tables: `openupgrade.rename_tables()`
- Map values: `openupgrade.map_values()`
- Delete obsolete data: `openupgrade.delete_records_safely_by_xml_id()`

### 5. Module Extension

Extend core Odoo modules following OCA patterns.

**Inherit existing model:**
```python
from odoo import fields, models

class ResPartner(models.Model):
    _inherit = 'res.partner'
    
    custom_field = fields.Char(string="Custom Info")
```

**Extend existing view:**
```xml
<record id="res_partner_view_form" model="ir.ui.view">
    <field name="model">res.partner</field>
    <field name="inherit_id" ref="base.view_partner_form"/>
    <field name="arch" type="xml">
        <xpath expr="//field[@name='email']" position="after">
            <field name="custom_field"/>
        </xpath>
    </field>
</record>
```

**Module dependencies:**
- Always declare dependencies in `__manifest__.py`
- Use `depends` key for Odoo core/OCA modules
- Use `external_dependencies` for Python packages
- Document installation requirements in README

### 6. Validation and Quality

**Validate module structure:**
```bash
python scripts/validate_module.py /path/to/module
```

**What is checked:**
- Required files presence (`__init__.py`, `__manifest__.py`)
- Manifest completeness (required keys)
- OCA author attribution
- License compliance (AGPL-3 or LGPL-3)
- Version format (x.y.z.w.v)
- File naming conventions
- Directory structure

**Code quality tools:**
```bash
# Install pre-commit for OCA checks
pip install pre-commit
pre-commit install

# Run checks
pre-commit run --all-files

# Run specific checks
flake8 module_name/
pylint --load-plugins=pylint_odoo module_name/
```

### 7. Testing

Write and run tests following Odoo's own testing framework, and lint/CI following OCA conventions. See [testing_and_qa.md](references/testing_and_qa.md) for the full guide (test tags, `HttpCase`/tour testing, `assertQueryCount`, `ERK-SMV/module_git-mgmt` repo scaffolding, `pre-commit`/pylint-odoo config, `oca_dependencies.txt`).

**Layout:**
```
your_module/
└── tests/
    ├── __init__.py      # must import every test_*.py or it won't run
    ├── test_foo.py
    └── test_bar.py
```

**Minimal unit test:**
```python
from odoo.tests import TransactionCase, tagged

@tagged('post_install', '-at_install')
class TestModelA(TransactionCase):
    def test_some_action(self):
        record = self.env['model.a'].create({'field': 'value'})
        record.some_action()
        self.assertEqual(record.field, 'expected')
```

**Run:**
```bash
odoo-bin --test-tags /your_module          # only this module's tests
odoo-bin --test-tags '/your_module,-slow'  # excluding slow-tagged tests
```

**Lint before pushing (OCA repos):**
```bash
pre-commit run -a
```

## Workflow Decision Tree

**"I need to create a new Odoo module"**
→ Use `scripts/init_oca_module.py` to generate OCA-compliant structure
→ Edit `__manifest__.py` with module details
→ Create models in `models/` directory
→ Create views in `views/` directory
→ Add security rules in `security/`
→ Update `readme/` documentation
→ Run validation: `scripts/validate_module.py`

**"I need to migrate a module to a new Odoo version"**
→ Check OpenUpgrade for breaking changes
→ Create migration folder: `migrations/<new_version>/`
→ Write pre-migration script for schema changes
→ Write post-migration script for data transformation
→ Test on copy of production database
→ Reference [openupgrade_migration.md](references/openupgrade_migration.md)

**"I need to extend a core Odoo module"**
→ Create new module with core module in `depends`
→ Use `_inherit` to extend models
→ Use `inherit_id` to extend views
→ Follow OCA naming: `<core_module>_<feature>`
→ Keep changes minimal and focused

**"I'm not sure if my module follows OCA conventions"**
→ Run `scripts/validate_module.py`
→ Check [oca_conventions.md](references/oca_conventions.md)
→ Review __manifest__.py for required keys
→ Verify file naming and structure
→ Ensure OCA author attribution

**"I need to write or run tests for my module"**
→ Reference [testing_and_qa.md](references/testing_and_qa.md)
→ `TransactionCase` for model logic, `HttpCase` + `@tagged('-at_install', 'post_install')` for controllers/tours
→ `tests/__init__.py` must import every `test_*.py`
→ Run selectively with `odoo-bin --test-tags /your_module`
→ Lint with `pre-commit run -a` before pushing (scaffolded by `ERK-SMV/module_git-mgmt`)

**"I need to build a git tag management app"**
→ Reference [version_control_platform.md](references/version_control_platform.md) — `OCA/version-control-platform` (18.0) is the closest existing architecture
→ Mirror its `vcp.branch` / `vcp.repository.branch` split for `vcp.tag` / `vcp.repository.tag` (platform-scoped tag name + per-repo join row)
→ Reuse its kind-dispatch pattern (`getattr(self, f"_download_code_{code_kind}")`) instead of if/elif per host
→ Reuse its GitPython clone/fetch code as the template, but note tag fetch needs an explicit `refs/tags/<name>` refspec (branch-style `remote.fetch(name)` isn't proven for tags — verify)
→ Reuse the `scheduled_*_update` + `_cron_update_*(limit)` batching pattern for tag sync, not a bespoke job queue

**"I need to check whether a running DB was actually restored from a given dump"** (`odoo_restauration_check`)
→ Reference [db_restore_verification.md](references/db_restore_verification.md) — read-only, no superuser, no CREATEDB needed
→ Confirm the DB name Odoo actually connects to (`grep db_name odoo.cfg` / `env | grep PG`), then check *that* DB
→ Compare the dump's `pg_restore -l` `Archive created at` against the live data horizon (`max(create_date)` on `mail_message` / `ir_attachment`)
→ Check `~/.bash_history` for `pg_restore|createdb|dropdb` — the last restore often names a *different* `.dump` than you expect
→ Prove it row-for-row: load the dump's table into a TEMP table in the live connection and compare `md5(string_agg(md5(row::text), '' ORDER BY id))`
→ Or just run [`scripts/verify_db_restore.sh`](scripts/verify_db_restore.sh) `DUMP_FILE [TABLE]` → prints `VERDICT: MATCH` / `MISMATCH`
→ Ignore `database.uuid` / `web.base.url` (copied from source on every restore) and `pg_stat_file` (superuser-only)

## Resources

### scripts/
- **init_oca_module.py**: Create new Odoo module with OCA-compliant structure
- **validate_module.py**: Validate module against OCA conventions
- **list_k8s_pods.py**: List and manage Kubernetes pods for Odoo development
- **check_k8s_permissions.py**: Check RBAC permissions and suggest workarounds
- **verify_db_restore.sh**: Confirm a live Postgres DB is the restore of a given `.dump` (`odoo_restauration_check`) — dump header vs. live data horizon, row count, and a row-for-row TEMP-table content hash; prints `VERDICT: MATCH` / `MISMATCH`. Read-only, no superuser.

### references/
- **oca_conventions.md**: Complete OCA coding standards and module structure guidelines
- **openupgrade_migration.md**: OpenUpgrade migration patterns and best practices
- **testing_and_qa.md**: Odoo test framework (tags, `HttpCase`/tours, `assertQueryCount`), plus OCA-style QA tooling (`ERK-SMV/module_git-mgmt` copier template, pre-commit/pylint-odoo config, `maintainer-quality-tools` conventions)
- **version_control_platform.md**: `OCA/version-control-platform` (18.0) architecture — host/platform/repository/branch data model, kind-dispatch extensibility pattern, GitPython clone/fetch integration, rule engine, cron-sync pattern; includes a gap analysis for extending it to git tags (no `vcp.tag` model exists upstream)
- **db_restore_verification.md**: `odoo_restauration_check` — prove a running Odoo DB is the restore of a specific `pg_dump` file. Evidence stack (container `db_name` → dump `Archive created at` → live data horizon → row count → row-for-row content hash via a TEMP table), how to do it with no superuser / no CREATEDB against a `pg_hba`-locked app role, and which signals (`database.uuid`, `pg_stat_file`, "container started OK") are red herrings

### assets/
- **module_template/**: Official OCA module template with complete directory structure

## Kubernetes RBAC and Security Best Practices

### Understanding RBAC Limitations

The Kubernetes service account has **read-only permissions** by design, following security best practices. This affects what kubectl commands are available.

### ✅ Allowed Operations (Read-Only Access)

These commands work with current permissions:

```bash
# List and inspect resources
kubectl get pods -n <namespace>
kubectl describe pods -n <namespace>
kubectl get deployments -n <namespace>
kubectl get services -n <namespace>

# Access logs (read-only)
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --tail=50
kubectl logs <pod-name> -n <namespace> --since=1h

# View events and configuration
kubectl get events -n <namespace>
kubectl describe configmap <name> -n <namespace>
kubectl get endpoints -n <namespace>

# Check permissions
kubectl auth can-i get pods -n <namespace>
kubectl auth can-i list pods -n <namespace>
```

### ❌ Restricted Operations (Requires Elevated Permissions)

These commands are blocked by RBAC:

```bash
# Execute commands inside containers (FORBIDDEN)
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash
kubectl exec <pod-name> -n <namespace> -- odoo --version

# Modify cluster state (FORBIDDEN)
kubectl delete pod <pod-name> -n <namespace>
kubectl apply -f deployment.yaml -n <namespace>
kubectl rollout restart deployment <name> -n <namespace>

# Port forwarding (MAY BE RESTRICTED)
kubectl port-forward <pod-name> 8069:8069 -n <namespace>
```

### Working Within RBAC Limitations

#### Alternative Methods for Common Tasks

**1. Determine Odoo Version Without Exec:**
```bash
# Check from container image
kubectl describe pod <odoo-pod> -n <namespace> | grep "Image:"

# Check from deployment configuration
kubectl describe deployment <odoo-deployment> -n <namespace> | grep "Image:"
```

**2. Debugging Without Shell Access:**
```bash
# Use comprehensive logging
kubectl logs <pod-name> -n <namespace> --tail=100
kubectl logs <pod-name> -n <namespace> --since=1h
kubectl logs <pod-name> -n <namespace> -c <container-name>

# Check events for errors
kubectl get events -n <namespace> --sort-by='.metadata.creationTimestamp'

# Examine pod specifications
kubectl describe pod <pod-name> -n <namespace>
```

**3. Access Database Information:**
```bash
# Get PostgreSQL version from image
kubectl describe pod <postgres-pod> -n <namespace> | grep "Image:"

# Check database configuration
kubectl describe configmap <postgres-config> -n <namespace>
```

### RBAC Best Practices

1. **Principle of Least Privilege**: Service accounts should have minimum required permissions
2. **Read-Only for Monitoring**: Sufficient for most debugging and monitoring tasks
3. **Separation of Concerns**: Different roles for development, operations, and administration
4. **Audit Trail**: All access is logged and auditable
5. **Temporary Elevation**: Request limited-time elevated access when truly needed

### Checking Your Permissions

```bash
# Check if you can perform specific actions
kubectl auth can-i get pods -n <namespace>
kubectl auth can-i create pods/exec -n <namespace>
kubectl auth can-i delete pods -n <namespace>

# Check subresource permissions
kubectl auth can-i get pods --subresource=log -n <namespace>
kubectl auth can-i get pods --subresource=exec -n <namespace>
```

### When You Need Elevated Permissions

If you legitimately need exec access for troubleshooting:

1. **Request Temporary Access**: Limited-time elevation with audit logging
2. **Specific Scope**: Request access to specific pods/namespaces only
3. **Follow Procedures**: Use your organization's security approval workflow
4. **Document Reason**: Provide justification for the access needed

Example limited RoleBinding:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: limited-debug-access
  namespace: fnfe-test
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]  # Only for specific pods
  resourceNames: ["odoo-14-fnfe-*"]
```

### Security Benefits of Current Configuration

✅ **Prevents Container Breakout**: No exec access means no escape from container
✅ **No Accidental Modifications**: Read-only prevents configuration errors
✅ **Audit Compliance**: Meets security best practices and compliance requirements
✅ **Least Privilege**: Service account has only necessary permissions
✅ **Defense in Depth**: Multiple layers of security protection

### Working Effectively Within Constraints

The current RBAC configuration allows for comprehensive monitoring and debugging:

```bash
# Comprehensive pod inspection
kubectl get pods -n fnfe-test -o wide
kubectl describe pod <pod-name> -n fnfe-test

# Log analysis
kubectl logs <pod-name> -n fnfe-test --tail=100
kubectl logs <pod-name> -n fnfe-test --since=1h | grep ERROR

# Resource monitoring
kubectl top pods -n fnfe-test
kubectl get events -n fnfe-test --sort-by='.lastTimestamp'

# Configuration review
kubectl get configmaps -n fnfe-test
kubectl describe configmap <name> -n fnfe-test
```

## Integration with Odoo Development Workflow

### Secure Development Practices

1. **Use Read-Only Access for Monitoring**: Sufficient for most debugging needs
2. **Request Temporary Access for Deployment**: Only when actually deploying changes
3. **Automate Deployments**: Use CI/CD pipelines instead of manual kubectl apply
4. **Log Analysis**: Use comprehensive logging instead of shell access
5. **Configuration as Code**: Store all configurations in Git, not applied manually

### CI/CD Integration

```bash
# View deployment status (read-only)
kubectl get deployments -n fnfe-test
kubectl describe deployment <name> -n fnfe-test

# Check rollout status
kubectl rollout status deployment <name> -n fnfe-test

# View resource usage
kubectl top pods -n fnfe-test
```

## Troubleshooting Within RBAC Limits

### Common Issues and Solutions

**Issue: "Cannot exec into pod"**
- **Solution**: Use logs and describe commands instead
- **Alternative**: Request temporary exec access with justification

**Issue: "Cannot delete/restart pod"**
- **Solution**: Identify issue through logs, request operations team assistance
- **Alternative**: Use kubectl scale to trigger restart (if permitted)

**Issue: "Cannot port-forward"**
- **Solution**: Use service endpoints or ingress instead
- **Alternative**: Request temporary port-forward access

### Effective Debugging Without Exec

```bash
# Step 1: Check pod status
kubectl get pods -n fnfe-test

# Step 2: Examine pod details
kubectl describe pod <pod-name> -n fnfe-test

# Step 3: Review recent logs
kubectl logs <pod-name> -n fnfe-test --tail=50

# Step 4: Check for errors in events
kubectl get events -n fnfe-test --sort-by='.lastTimestamp' | grep Error

# Step 5: Review configuration
kubectl describe configmap <config-name> -n fnfe-test
kubectl describe secret <secret-name> -n fnfe-test

# Step 6: Check resource usage
kubectl top pod <pod-name> -n fnfe-test
```

## Summary

The current RBAC configuration represents **security best practices** and provides sufficient access for comprehensive monitoring and debugging. The restrictions on exec and modification commands prevent potential security risks while still allowing full visibility into the Kubernetes environment.

**Key Takeaway**: Work within the read-only constraints for monitoring, and use proper approval channels when elevated access is truly needed for specific troubleshooting tasks.

### Common Kubernetes Operations for Odoo

**Check pod status:**
```bash
kubectl get pods -n <namespace> -o wide
```

**Restart a pod:**
```bash
kubectl rollout restart deployment/<deployment-name> -n <namespace>
```

**Access Odoo pod shell:**
```bash
kubectl exec -it <odoo-pod-name> -n <namespace> -- /bin/bash
```

**Port forwarding for local access:**
```bash
kubectl port-forward <odoo-pod-name> 8069:8069 -n <namespace>
```

### Kubernetes Troubleshooting

**Check pod events:**
```bash
kubectl get events -n <namespace> --sort-by='.metadata.creationTimestamp'
```

**Check resource usage:**
```bash
kubectl top pods -n <namespace>
```

**Check service endpoints:**
```bash
kubectl get endpoints -n <namespace>
```

### Best Practices

1. **Namespace isolation**: Use separate namespaces for different environments (dev, test, prod)
2. **Resource limits**: Set appropriate CPU/memory limits for Odoo pods
3. **Persistent volumes**: Use PVCs for Odoo data and filestore
4. **Health checks**: Configure proper liveness and readiness probes
5. **Logging**: Ensure proper log collection and rotation

### Integration with Odoo Development Workflow

1. **Development**: Use port-forwarding to access Odoo running in Kubernetes
2. **Testing**: Deploy test instances in separate namespaces
3. **Staging**: Use staging namespace for final testing
4. **Production**: Deploy to production namespace with proper resource allocation

**Example workflow:**
```bash
# Develop locally with port forwarding
kubectl port-forward odoo-pod 8069:8069 -n dev &

# Test in staging environment
kubectl apply -f odoo-staging-deployment.yaml -n staging

# Deploy to production
kubectl apply -f odoo-production-deployment.yaml -n production
```

### Code Quality
- Follow PEP8 for Python code
- Use 4-space indentation in XML
- No SQL injection vulnerabilities
- Never bypass ORM without justification
- Never commit transactions manually
- Use `_logger.debug()` for import errors
- Handle external dependencies properly

### Git Commits
Format: `[TAG] module_name: short summary`

Common tags:
- `[ADD]` - New feature/module
- `[FIX]` - Bug fix
- `[REF]` - Refactoring
- `[IMP]` - Improvement
- `[MIG]` - Migration
- `[REM]` - Removal

### Migration Strategy
1. Study OpenUpgrade analysis for target version
2. Check for breaking changes in core modules
3. Test on database copy first
4. Write pre-migration for schema changes
5. Write post-migration for data transformation
6. Document breaking changes in README
7. Update version following semantic versioning

## Common Patterns

### Pattern: Add computed field with dependencies
```python
total = fields.Float(compute='_compute_total', store=True)

@api.depends('line_ids.amount')
def _compute_total(self):
    for record in self:
        record.total = sum(record.line_ids.mapped('amount'))
```

### Pattern: Extend view safely
```xml
<xpath expr="//field[@name='partner_id']" position="after">
    <field name="custom_field"/>
</xpath>
```

### Pattern: Add security group
```xml
<record id="group_custom" model="res.groups">
    <field name="name">Custom Access</field>
    <field name="category_id" ref="base.module_category_sales"/>
</record>
```

### Pattern: Migration with value mapping
```python
openupgrade.map_values(
    env.cr,
    openupgrade.get_legacy_name('old_field'),
    'new_field',
    [('old_value', 'new_value')],
    table='model_table',
)
```

## Troubleshooting

**Module not appearing in Apps**
- Check `'installable': True` in __manifest__.py
- Verify __init__.py imports
- Run: `odoo-bin -u module_name -d database`

**Import errors**
- Add try-except for external dependencies
- Document installation in readme/INSTALL.rst
- Add to requirements.txt for Python packages

**Migration fails**
- Check pre-migration runs before module load
- Verify table/column names with `\d table` in psql
- Use `openupgrade.logged_query()` for debugging
- Test on copy database first

**Tests failing**
- Use `tagged('post_install', '-at_install')`
- Test with minimal user permissions using `@users()`
- Avoid dynamic dates, use `freezegun`
- Mock external services

## Quick Reference

**Create module:**
```bash
python scripts/init_oca_module.py my_module --version 17.0
```

**Validate module:**
```bash
python scripts/validate_module.py path/to/module
```

**Check conventions:**
See [oca_conventions.md](references/oca_conventions.md)

**Migration guide:**
See [openupgrade_migration.md](references/openupgrade_migration.md)

**Module template:**
Copy from [assets/module_template/](assets/module_template/)

**Testing & QA guide:**
See [testing_and_qa.md](references/testing_and_qa.md)

**Git tag / version control platform architecture:**
See [version_control_platform.md](references/version_control_platform.md)

**Check a DB was restored from a given dump (`odoo_restauration_check`):**
```bash
# from inside the odoo container / host, with PG* env set (same as `psql` no-args)
scripts/verify_db_restore.sh ~/backup_prod_YYYYMMDD_HHMM.dump            # defaults to mail_message
scripts/verify_db_restore.sh ~/backup_prod_YYYYMMDD_HHMM.dump res_partner id
```
See [db_restore_verification.md](references/db_restore_verification.md)

**List Kubernetes pods:**
```bash
# List all pods in namespace
python scripts/list_k8s_pods.py -n fnfe-test

# Get details for specific pod
python scripts/list_k8s_pods.py -n fnfe-test -p odoo-pod-name

# Get logs from specific pod
python scripts/list_k8s_pods.py -n fnfe-test -p odoo-pod-name -l 50
```

**Check Kubernetes RBAC Permissions:**
```bash
# Check if you can perform an action
kubectl auth can-i get pods -n fnfe-test
kubectl auth can-i create pods/exec -n fnfe-test
kubectl auth can-i delete pods -n fnfe-test

# Check subresource permissions
kubectl auth can-i get pods --subresource=log -n fnfe-test
kubectl auth can-i get pods --subresource=exec -n fnfe-test
```

## Usage Examples

### Kubernetes Integration Examples

**List all pods in fnfe-test namespace:**
```bash
python3 /root/.hermes/skills/odoo/odoo-oca-developer/scripts/list_k8s_pods.py -n fnfe-test
```

**Get details for Odoo pod:**
```bash
python3 /root/.hermes/skills/odoo/odoo-oca-developer/scripts/list_k8s_pods.py -n fnfe-test -p odoo-14-fnfe-5bd6f686b8-dfmxn
```

**Get last 100 lines of logs from Odoo pod:**
```bash
python3 /root/.hermes/skills/odoo/odoo-oca-developer/scripts/list_k8s_pods.py -n fnfe-test -p odoo-14-fnfe-5bd6f686b8-dfmxn -l 100
```

**Check Kubernetes RBAC permissions:**
```bash
# Check all common permissions
python3 /root/.hermes/skills/odoo/odoo-oca-developer/scripts/check_k8s_permissions.py -n fnfe-test

# Check specific permissions
python3 /root/.hermes/skills/odoo/odoo-oca-developer/scripts/check_k8s_permissions.py -n fnfe-test \
  -c get/pods -c create/pods/exec -c delete/pods

# Get permission report with workarounds
python3 /root/.hermes/skills/odoo/odoo-oca-developer/scripts/check_k8s_permissions.py -n fnfe-test --suggest
```

**Akretion Docker Compose Commands:**
```bash
# Create new project
copier copy https://github.com/akretion/docky-odoo-template-shared my-project

# Update project
copier update

# Manage modules
cd odoo && ak clone && ak build

# Start services
docky run

# Execute in container
docky exec odoo /bin/bash
```

**Work within RBAC limitations:**
```bash
# Instead of: kubectl exec (FORBIDDEN)
# Use: Check version from image
kubectl describe pod odoo-14-fnfe-5bd6f686b8-dfmxn -n fnfe-test | grep "Image:"

# Instead of: kubectl delete pod (FORBIDDEN)
# Use: Identify issues through logs
kubectl logs odoo-14-fnfe-5bd6f686b8-dfmxn -n fnfe-test --tail=100 | grep ERROR
```

## Akretion Docker Compose Examples

### Create Development Project

```bash
# Create project for Odoo 18.0
mkdir my-project && cd my-project
copier copy -d project_name=my-project -d branch_name=18.0 \
  https://github.com/akretion/docky-odoo-template-shared .

# Add personal config
copier copy https://github.com/akretion/docky-odoo-template-personal .

# Setup and run
cd odoo && ak clone && ak build
cd .. && docky run
```

### Add Custom Module

```bash
# Edit spec.yaml
nano odoo/spec.yaml

# Add your module
my-custom-modules:
    modules:
        - my_awesome_module
    src: https://github.com/myorg/my-modules 18.0

# Update and rebuild
ak update
ak build

# Restart services
docky build
docky run
```

### Update Existing Project

```bash
# Pull latest template changes
copier update

# Update modules
cd odoo
ak update
ak build

# Rebuild containers
cd ..
docky build
docky run
```

### Database Operations

```bash
# Backup database
bin/backup/get_db.sh

# Restore database
bin/backup/load_db.sh

# Get database dump for analysis
bin/get_db.py > db_dump.sql
```

## Triggers

This skill is automatically invoked when you ask about:

### Odoo Development
- Odoo module development
- OCA conventions and compliance
- OpenUpgrade migrations
- Odoo module structure
- Odoo module creation
- Odoo module extension
- Odoo module validation
- Odoo testing patterns
- Odoo troubleshooting
- Odoo tests, tagged(), TransactionCase, HttpCase, test tours, start_tour, browser_js
- assertQueryCount, performance testing, test-tags selection
- OCA pre-commit config, pylint-odoo, flake8 config for Odoo
- maintainer-quality-tools, oca_dependencies.txt, Travis/GHA CI for OCA repos
- ERK-SMV module_git-mgmt, copier template for OCA addon repos
- git tag management, git tags in Odoo, version control platform
- OCA version-control-platform, vcp_git, vcp_github, vcp_management, vcp_odoo
- GitPython, git clone/fetch from Odoo, GitHub API sync into Odoo (github3.py)
- kind-dispatch pattern, host/platform/repository/branch data model
- odoo_restauration_check, verify DB restored from dump, check which dump Postgres is using
- pg_restore verification, dump vs live row count / content hash, TEMP table hash compare
- Odoo data horizon check (max create_date), pg_hba app-role restriction, no-superuser DB checks
- "did the restore work", stale dump loaded, docky run wrong database

### Kubernetes Integration
- Kubernetes pods for Odoo
- Odoo deployment on Kubernetes
- Kubernetes troubleshooting for Odoo
- Odoo pod management
- Kubernetes namespace for Odoo
- Odoo container orchestration
- Kubernetes port forwarding for Odoo
- Odoo pod logs and debugging
- Kubernetes RBAC limitations
- Kubernetes permissions and access
- kubectl auth can-i usage
- Working with read-only Kubernetes access
- Secure Kubernetes practices for Odoo

### Akretion Docker Infrastructure
- Akretion Docker Compose setup
- Docky Odoo configuration
- Copier templates for Odoo
- AK tool usage and module management
- Odoo Docker development environment
- docky-odoo-template-shared
- docky-odoo-template-personal
- oca-addons-repo-template
- Akretion project templates
- Odoo local development setup
- git-aggregator for Odoo modules
- Docker Compose for Odoo
- Odoo development with Docky
- Akretion Docker workflow

