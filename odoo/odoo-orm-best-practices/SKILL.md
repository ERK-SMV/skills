---
name: odoo-orm-best-practices
description: Odoo ORM best practices for imports and data operations.
tags:
  - odoo
  - orm
  - oca
  - import
  - best-practices
---

# Odoo ORM Best Practices

## 🎯 Overview

**Odoo ORM Best Practices** provides comprehensive guidance for using Odoo's ORM effectively, with a focus on import operations, performance optimization, and OCA compliance. This skill covers patterns, anti-patterns, and real-world examples for Odoo development.

## 📋 Scope

Use this skill when:
- Developing Odoo modules that involve data imports
- Optimizing Odoo ORM usage
- Migrating from raw SQL to ORM
- Following OCA conventions for data operations
- Implementing batch processing for large datasets
- Handling complex relationships in Odoo

## 🔧 Core Capabilities

### 1. ORM vs SQL Comparison

**Why Use ORM:**
- ✅ Automatic transaction management
- ✅ Built-in validation
- ✅ SQL injection prevention
- ✅ Relationship integrity
- ✅ OCA compliance
- ✅ Audit logging
- ✅ Security checks
- ✅ Easier maintenance

**Basic Example:**
```python
# ❌ Avoid Raw SQL
env.cr.execute("""
    INSERT INTO account_journal (name, code, type, company_id)
    VALUES (%s, %s, %s, %s)
""", (name, code, journal_type, company_id))

# ✅ Use ORM
env['account.journal'].create({
    'name': name,
    'code': code,
    'type': journal_type,
    'company_id': company_id
})
```

### 2. Account Journal Import Patterns

**Complete Import Wizard:**
```python
from odoo import api, fields, models, _
from odoo.exceptions import UserError, ValidationError
import logging
import csv
from io import StringIO

_logger = logging.getLogger(__name__)

class AccountJournalImport(models.TransientModel):
    _name = 'account.journal.import'
    _description = 'Account Journal Import Wizard'

    # Wizard fields
    import_file = fields.Binary(string='Import File', required=True)
    delimiter = fields.Selection([
        (',', 'Comma'),
        (';', 'Semicolon'),
        ('\t', 'Tab')
    ], default=',', required=True)

    def _prepare_journal_data(self, row):
        """Prepare journal data from CSV row"""
        return {
            'name': row.get('name', '').strip(),
            'code': row.get('code', '').strip(),
            'type': row.get('type', 'general').strip(),
            'company_id': self.env.company.id,
            'currency_id': self._get_currency_id(row.get('currency')),
            'default_account_id': self._get_account_id(row.get('default_account')),
            'active': row.get('active', 'True').lower() == 'true',
        }

    def _get_currency_id(self, currency_code):
        """Get currency ID safely"""
        if not currency_code:
            return self.env.company.currency_id.id
        currency = self.env['res.currency'].search([('name', '=', currency_code.upper())], limit=1)
        return currency.id if currency else self.env.company.currency_id.id

    def _get_account_id(self, account_code):
        """Get account ID safely"""
        if not account_code:
            return False
        account = self.env['account.account'].search([('code', '=', account_code)], limit=1)
        return account.id if account else False

    def _validate_data(self, journals_data):
        """Validate import data"""
        errors = []
        for idx, data in enumerate(journals_data, 1):
            if not data.get('name'):
                errors.append(_("Row %d: Name is required") % idx)
            if not data.get('code'):
                errors.append(_("Row %d: Code is required") % idx)
            if data.get('type') not in ['general', 'bank', 'cash', 'sale', 'purchase']:
                errors.append(_("Row %d: Invalid type") % idx)
        
        if errors:
            raise ValidationError("\n".join(errors))
        return True

    def _process_import(self):
        """Main import processing"""
        try:
            # Read CSV
            file_content = self.import_file.decode('utf-8')
            csv_reader = csv.DictReader(StringIO(file_content), delimiter=self.delimiter)
            rows = list(csv_reader)

            if not rows:
                raise UserError(_("No data in import file"))

            # Prepare and validate data
            journals_data = [self._prepare_journal_data(row) for row in rows]
            self._validate_data(journals_data)

            # Create in batches
            batch_size = 50
            for i in range(0, len(journals_data), batch_size):
                batch = journals_data[i:i + batch_size]
                self.env['account.journal'].create(batch)

            return {
                'type': 'ir.actions.client',
                'tag': 'reload',
                'params': {
                    'title': _('Import Successful'),
                    'message': _('%d journals imported successfully') % len(journals_data),
                    'sticky': False
                }
            }

        except Exception as e:
            _logger.error("Import failed: %s", str(e))
            return {
                'type': 'ir.actions.client',
                'tag': 'display_notification',
                'params': {
                    'title': _('Import Failed'),
                    'message': str(e),
                    'sticky': True
                }
            }

    def action_import(self):
        """Button action"""
        return self._process_import()
```

### 3. Common ORM Anti-Patterns

**❌ Manual SQL Operations:**
```python
# ❌ Avoid this
env.cr.execute("UPDATE account_journal SET name=%s WHERE id=%s", (name, journal_id))

# ✅ Use ORM
env['account.journal'].browse(journal_id).write({'name': name})
```

**❌ Ignoring Validation:**
```python
# ❌ Missing required fields
env['account.journal'].create({'name': name})  # Will fail

# ✅ Proper validation
data = {
    'name': name,
    'code': code,  # Required
    'type': 'general',  # Required
    'company_id': env.company.id  # Required
}
try:
    journal = env['account.journal'].create(data)
except ValidationError as e:
    raise UserError(_("Invalid data: %s") % str(e))
```

**❌ Manual Transaction Management:**
```python
# ❌ Dangerous
env.cr.autocommit(True)

# ✅ Automatic transaction handling
try:
    journal = env['account.journal'].create(data)
    # Success - committed automatically
except Exception:
    # Failure - rolled back automatically
    raise
```

### 4. Performance Optimization

**Batch Operations:**
```python
# ✅ Process in batches for large imports
batch_size = 100
records = []
for i in range(1000):
    records.append({
        'name': f'Journal {i}',
        'code': f'J{i:04d}',
        'type': 'general'
    })

# Create in batches
for i in range(0, len(records), batch_size):
    batch = records[i:i + batch_size]
    env['account.journal'].create(batch)
```

**Efficient Searches:**
```python
# ✅ Use efficient search domains
journals = env['account.journal'].search([
    ('company_id', '=', env.company.id),
    ('type', 'in', ['bank', 'cash']),
    ('active', '=', True)
])
```

**Pre-fetch Related Data:**
```python
# ✅ Pre-fetch related records
journals = env['account.journal'].search([])
journals.read(['name', 'currency_id', 'default_account_id'])
```

### 5. Error Handling

**Comprehensive Error Handling:**
```python
def safe_import_journal(self, data):
    """Import journal with comprehensive error handling"""
    try:
        # Validate required fields
        required_fields = ['name', 'code', 'type']
        for field in required_fields:
            if not data.get(field):
                raise ValidationError(_("Missing required field: %s") % field)

        # Check for duplicates
        existing = env['account.journal'].search([
            ('code', '=', data['code']),
            ('company_id', '=', data.get('company_id', env.company.id))
        ])
        if existing:
            raise ValidationError(_("Journal with code %s already exists") % data['code'])

        # Create journal
        journal = env['account.journal'].create(data)
        _logger.info("Created journal: %s (ID: %d)", journal.name, journal.id)
        return journal

    except ValidationError as e:
        _logger.error("Validation error creating journal: %s", str(e))
        raise UserError(_("Invalid journal data: %s") % str(e))
    except Exception as e:
        _logger.error("Unexpected error creating journal: %s", str(e))
        raise UserError(_("Failed to create journal: %s") % str(e))
```

### 6. Relationship Management

**Safe Relationship Lookup:**
```python
def get_related_record(self, model, field, value):
    """Get related record ID with proper error handling"""
    if not value:
        return False
    
    record = self.env[model].search([(field, '=', value)], limit=1)
    if not record:
        _logger.warning("No %s found with %s=%s", model, field, value)
        return False
    
    return record.id

# Usage:
currency_id = self.get_related_record('res.currency', 'name', 'EUR')
account_id = self.get_related_record('account.account', 'code', '123456')
```

### 7. Batch Processing

**Large Dataset Processing:**
```python
def process_large_import(self, data_list):
    """Process large import in batches"""
    batch_size = 50
    total_created = 0
    total_failed = 0
    
    for i in range(0, len(data_list), batch_size):
        batch = data_list[i:i + batch_size]
        
        try:
            # Process batch
            created = env['account.journal'].create(batch)
            total_created += len(created)
            
            # Commit after each batch
            self.env.cr.commit()
            
            _logger.info("Processed batch %d-%d: %d created", 
                       i+1, i+len(batch), len(created))
        
        except Exception as e:
            # Rollback on failure
            self.env.cr.rollback()
            total_failed += len(batch)
            _logger.error("Failed to process batch %d-%d: %s", 
                        i+1, i+len(batch), str(e))
    
    return {
        'created': total_created,
        'failed': total_failed
    }
```

## 📚 Resources

### Odoo ORM Documentation
- [Odoo ORM API](https://www.odoo.com/documentation/17.0/developer/reference/backend/orm.html)
- [Odoo Fields Reference](https://www.odoo.com/documentation/17.0/developer/reference/backend/orm.html#fields)
- [Odoo Model Methods](https://www.odoo.com/documentation/17.0/developer/reference/backend/orm.html#model-methods)

### Performance Optimization
- [Odoo Performance Guide](https://www.odoo.com/documentation/17.0/developer/howtos/rdtraining/06_performance.html)
- [Odoo Batch Processing](https://www.odoo.com/documentation/17.0/developer/howtos/rdtraining/06_performance.html#batch-processing)

### OCA Guidelines
- [OCA Contribution Guide](https://github.com/OCA/maintainer-tools/blob/master/CONTRIBUTING.md)
- [OCA Code Review Guidelines](https://github.com/OCA/maintainer-tools/blob/master/CONTRIBUTING.md#code-review)

## 🎯 Best Practices Summary

### Key Takeaways

1. **Always use ORM** instead of raw SQL for Odoo operations
2. **Validate data** before creating/updating records
3. **Handle errors** gracefully with proper user feedback
4. **Process in batches** for large datasets
5. **Use efficient searches** with proper domain filters
6. **Manage relationships** safely with proper lookups
7. **Let ORM handle transactions** - don't manually commit
8. **Follow OCA patterns** for maintainability

### ORM Benefits Recap

| Aspect | ORM Approach | SQL Approach |
|--------|-------------|--------------|
| **Transactions** | Automatic rollback on errors | Manual commit/rollback needed |
| **Validation** | Built-in field validation | Manual validation required |
| **Relationships** | Automatic reference handling | Manual ID lookups |
| **Security** | Automatic SQL injection prevention | Vulnerable to injection |
| **Performance** | Batch operations optimized | Manual batching needed |
| **Maintenance** | Easy to update | Hard to maintain |
| **OCA Compliance** | Follows OCA patterns | Often violates conventions |

## 🛠️ Usage Examples

### Basic Import
```python
# Create single journal
journal = env['account.journal'].create({
    'name': 'Bank Journal',
    'code': 'BNK1',
    'type': 'bank',
    'company_id': env.company.id
})
```

### Batch Import
```python
# Create multiple journals
journals_data = [
    {'name': 'Bank Journal', 'code': 'BNK1', 'type': 'bank'},
    {'name': 'Cash Journal', 'code': 'CASH1', 'type': 'cash'}
]
created_journals = env['account.journal'].create(journals_data)
```

### Search and Update
```python
# Find and update journals
journals = env['account.journal'].search([('type', '=', 'bank')])
journals.write({'update_posted': True})
```

### Relationship Handling
```python
# Create journal with relationships
currency = env['res.currency'].search([('name', '=', 'EUR')], limit=1)
account = env['account.account'].search([('code', '=', '123456')], limit=1)

journal = env['account.journal'].create({
    'name': 'EUR Bank Journal',
    'code': 'EURBNK',
    'type': 'bank',
    'currency_id': currency.id,
    'default_account_id': account.id
})
```

## 🔍 Troubleshooting

### Common Issues

**Issue: ValidationError on create**
- **Cause**: Missing required fields or invalid data
- **Solution**: Check all required fields and validate data before creation

**Issue: AccessError on write**
- **Cause**: Insufficient permissions
- **Solution**: Check security rules and user permissions

**Issue: Transaction rolled back**
- **Cause**: Exception during operation
- **Solution**: Check logs for specific error and handle exceptions properly

**Issue: Slow performance**
- **Cause**: Inefficient searches or large datasets
- **Solution**: Use batch processing and efficient domain filters

## 📝 Workflow Decision Tree

**"I need to import data into Odoo"**
→ Use ORM create() method
→ Validate data before import
→ Process in batches for large datasets
→ Handle errors gracefully
→ Follow OCA patterns

**"My import is slow"**
→ Check batch size (50-100 recommended)
→ Optimize search queries
→ Pre-fetch related data
→ Use efficient domain filters

**"I'm getting validation errors"**
→ Check required fields
→ Validate data types
→ Check field constraints
→ Review OCA conventions

**"Relationships aren't working"**
→ Verify related records exist
→ Use proper search methods
→ Handle missing relationships
→ Check security rules

## 🎓 Learning Resources

### Recommended Reading
- [Odoo Developer Documentation](https://www.odoo.com/documentation/17.0/developer/reference/backend/orm.html)
- [OCA Developer Guidelines](https://github.com/OCA/maintainer-tools/blob/master/CONTRIBUTING.md)
- [Python ORM Patterns](https://www.cosmicpython.com/)

### Video Tutorials
- [Odoo ORM Basics](https://www.youtube.com/watch?v=odoo-orm-basics)
- [Advanced Odoo Patterns](https://www.youtube.com/watch?v=odoo-advanced)

### Community Resources
- [Odoo Community Forum](https://www.odoo.com/forum/help-1)
- [OCA GitHub](https://github.com/OCA)
- [Odoo Stack Overflow](https://stackoverflow.com/questions/tagged/odoo)

## 📋 Quick Reference

### ORM Methods
```python
# Create
record = env['model'].create({'field': 'value'})

# Read
records = env['model'].search([('field', '=', 'value')])
record = env['model'].browse(record_id)

# Update
records.write({'field': 'new_value'})

# Delete
records.unlink()

# Search with domain
records = env['model'].search([
    ('field1', '=', 'value1'),
    ('field2', '!=', 'value2')
])

# Read specific fields
records.read(['field1', 'field2'])

# Mapped - extract field values
values = records.mapped('field_name')

# Filtered - filter recordset
filtered = records.filtered(lambda r: r.field == 'value')

# Sorted - sort recordset
sorted = records.sorted(key=lambda r: r.field, reverse=True)
```

### Common Field Types
```python
# Basic fields
name = fields.Char(string="Name")
active = fields.Boolean(string="Active")
count = fields.Integer(string="Count")
amount = fields.Float(string="Amount")
date = fields.Date(string="Date")
datetime = fields.Datetime(string="Datetime")

# Relational fields
partner_id = fields.Many2one('res.partner', string="Partner")
line_ids = fields.One2many('account.journal.line', 'journal_id', string="Lines")
tag_ids = fields.Many2many('account.tag', string="Tags")

# Computed fields
computed_field = fields.Char(compute='_compute_field', store=True)

# Selection fields
type = fields.Selection([
    ('bank', 'Bank'),
    ('cash', 'Cash'),
    ('general', 'General')
], string="Type")
```

## 🎯 Conclusion

This skill provides comprehensive guidance for using Odoo ORM effectively. By following these best practices, you'll create more maintainable, secure, and performant Odoo modules that follow OCA conventions.

**Remember:** Always prefer ORM over raw SQL, validate data thoroughly, handle errors gracefully, and process large datasets in batches for optimal performance.