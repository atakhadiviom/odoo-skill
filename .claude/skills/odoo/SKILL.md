# Odoo 19.0 Development Skill

A comprehensive Odoo 19.0 development reference for Claude Code, covering module development, debugging, API patterns, and best practices.

## Overview

This skill provides Odoo 19.0 specific development guidance including:
- OWL 2.0 frontend framework patterns
- Python 3.11+ compatibility
- PostgreSQL 15+ considerations
- New field widgets and components
- Enhanced API patterns
- Testing and debugging strategies

## Odoo 19.0 Quick Reference

### Version Compatibility

| Odoo Version | Python | PostgreSQL | LTS | Status |
|--------------|--------|------------|-----|--------|
| 14.0 | 3.8 | 12 | No | Maintenance |
| 15.0 | 3.9 | 13 | No | Maintenance |
| 16.0 | 3.10 | 14 | No | Maintenance |
| 17.0 | 3.10 | 14 | Yes | LTS until 2034-05 |
| 18.0 | 3.11 | 15 | No | Stable |
| **19.0** | **3.11+** | **15+** | **Yes** | **Latest LTS** |

### Odoo 19.0 Key Features

1. **OWL 2.0 Framework** - Complete rewrite of frontend components
2. **AI Integration** - New `ai_text_assistant` widget for AI-powered text editing
3. **Enhanced Mobile Support** - Improved responsive forms and views
4. **Performance Improvements** - Lazy loading and optimized rendering
5. **New Field Widgets** - `rich_text_content`, enhanced kanban, mobile-optimized widgets

## Module Development

### Module Structure

```
module_name/
├── __init__.py
├── __manifest__.py
├── models/
│   ├── __init__.py
│   └── main_model.py
├── views/
│   └── main_model_views.xml
├── security/
│   ├── ir.model.access.csv
│   └── security_rules.xml
├── static/
│   ├── src/
│   │   └── components/
│   │       └── my_component/
│   │           ├── my_component.js
│   │           ├── my_component.xml
│   │           └── my_component.scss
│   └── description/
│       ├── icon.png
│       └── index.html
└── i18n/
    └── module_name.pot
```

### Manifest Template (__manifest__.py)

```python
# -*- coding: utf-8 -*-
{
    'name': 'My Odoo Module',
    'version': '19.0.1.0.0',
    'category': 'Tools',
    'summary': 'Brief description',
    'description': """
        Long description
    """,
    'author': 'Your Company',
    'website': 'https://www.yourcompany.com',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'mail',
    ],
    'data': [
        'security/security_rules.xml',
        'security/ir.model.access.csv',
        'views/main_model_views.xml',
        'views/menus.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'module_name/static/src/components/**/*.js',
            'module_name/static/src/**/*.xml',
            'module_name/static/src/**/*.scss',
        ],
        'web.assets_frontend': [
            'module_name/static/src/components/**/*.js',
        ],
    },
    'demo': [
        'demo/demo_data.xml',
    ],
    'installable': True,
    'application': True,
    'auto_install': False,
    'post_init_hook': 'post_init_hook',
}
```

## Model Development

### Standard Model Pattern

```python
from odoo import models, fields, api, _
from odoo.exceptions import ValidationError, UserError

class MainModel(models.Model):
    _name = 'module_name.main_model'
    _description = 'Main Model Description'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'name desc'

    # Basic Fields
    name = fields.Char(
        string='Reference',
        required=True,
        copy=False,
        readonly=True,
        index=True,
        default=lambda self: self._get_default_name()
    )

    # Selection Field
    state = fields.Selection([
        ('draft', 'Draft'),
        'confirmed', 'Confirmed'),
        ('done', 'Done'),
        ('cancelled', 'Cancelled'),
    ], string='Status', default='draft', tracking=True)

    # Relations
    partner_id = fields.Many2one(
        'res.partner',
        string='Partner',
        required=True,
        tracking=True,
        ondelete='restrict',
    )

    line_ids = fields.One2many(
        'module_name.line_model',
        'main_id',
        string='Lines',
    )

    tag_ids = fields.Many2many(
        'module_name.tag',
        'module_name_main_tag_rel',
        'main_id', 'tag_id',
        string='Tags',
    )

    # Computed Fields
    total_amount = fields.Monetary(
        string='Total Amount',
        compute='_compute_total_amount',
        store=True,
        currency_field='currency_id',
    )

    currency_id = fields.Many2one(
        'res.currency',
        string='Currency',
        required=True,
        default=lambda self: self.env.company.currency_id,
    )

    company_id = fields.Many2one(
        'res.company',
        string='Company',
        required=True,
        default=lambda self: self.env.company,
        index=True,
    )

    # Constraints
    _sql_constraints = [
        ('name_unique', 'UNIQUE(name)', 'Reference must be unique!'),
    ]

    @api.depends('line_ids.amount')
    def _compute_total_amount(self):
        for record in self:
            record.total_amount = sum(record.line_ids.mapped('amount'))

    @api.constrains('partner_id', 'company_id')
    def _check_partner_company(self):
        for record in self:
            if record.partner_id.company_id and record.partner_id.company_id != record.company_id:
                raise ValidationError(_('Partner must belong to the same company.'))

    @api.onchange('partner_id')
    def _onchange_partner_id(self):
        if self.partner_id:
            self.currency_id = self.partner_id.property_purchase_currency_id or self.env.company.currency_id

    # CRUD Methods
    @api.model
    def create(self, vals):
        if vals.get('name', _('New')) == _('New'):
            vals['name'] = self.env['ir.sequence'].next_by_code(self._name) or _('New')
        return super().create(vals)

    def write(self, vals):
        # Custom write logic
        return super().write(vals)

    def unlink(self):
        for record in self:
            if record.state != 'cancelled':
                raise UserError(_('Only cancelled records can be deleted.'))
        return super().unlink()

    # Action Methods
    def action_confirm(self):
        self.write({'state': 'confirmed'})
        return True

    def action_done(self):
        self.write({'state': 'done'})
        return True

    def action_cancel(self):
        self.write({'state': 'cancelled'})
        return True

    def action_draft(self):
        self.write({'state': 'draft'})
        return True

    @api.model
    def _get_default_name(self):
        return _('New')
```

## OWL 2.0 Frontend Development

### Component Structure (Odoo 19.0)

```javascript
/** @odoo-module **/
import { Component, useState, onMounted, onWillStart } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";
import { _t } from "@web/core/l10n/translation";
import { registry } from "@web/core/registry";

export class MyComponent extends Component {
    static template = "module_name.MyComponent";
    static props = {
        record: { type: Object, optional: true },
        readonly: { type: Boolean, optional: true },
    };

    setup() {
        // Services
        this.orm = useService("orm");
        this.dialog = useService("dialog");
        this.notification = useService("notification");
        this.rpc = useService("rpc");
        this.action = useService("action");

        // State
        this.state = useState({
            data: [],
            isLoading: false,
            selectedId: null,
        });

        // Lifecycle hooks
        onWillStart(this.onWillStart);
        onMounted(this.onMounted);
    }

    async onWillStart() {
        // Load initial data
        await this.loadData();
    }

    onMounted() {
        // Post-mount logic
        console.log('Component mounted');
    }

    async loadData() {
        this.state.isLoading = true;
        try {
            this.state.data = await this.orm.searchRead(
                this.props.record.resModel,
                [['id', '=', this.props.record.resId]],
                ['name', 'state', 'date']
            );
        } catch (error) {
            this.notification.add(_t('Error loading data'), { type: 'danger' });
        } finally {
            this.state.isLoading = false;
        }
    }

    onRowClick(ev) {
        const rowId = ev.currentTarget.dataset.id;
        this.state.selectedId = parseInt(rowId);
    }

    async onActionClick() {
        await this.orm.write(
            this.props.record.resModel,
            [this.props.record.resId],
            { state: 'confirmed' }
        );
        this.notification.add(_t('Record confirmed'), { type: 'success' });
    }

    get displayData() {
        return this.state.data.filter(item => item.state !== 'cancelled');
    }
}

// Register component
registry.category("actions").add("module_name.my_component", MyComponent);
```

### Component XML Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<odoo>
    <template id="MyComponent" xml:space="preserve">
        <div class="o_my_component">
            <div class="o_component_header">
                <h4><t t-esc="props.record.data.name"/></h4>
            </div>
            <div class="o_component_body">
                <div t-if="state.isLoading" class="text-center">
                    <i class="fa fa-spinner fa-spin"/>
                </div>
                <div t-else="">
                    <button
                        class="btn btn-primary"
                        t-on-click="onActionClick"
                        t-att-disabled="props.readonly">
                        <i class="fa fa-check"/> <t t-esc="_t('Confirm')"/>
                    </button>
                </div>
            </div>
        </div>
    </template>
</odoo>
```

## View Development

### Form View (Odoo 19.0)

```xml
<record id="view_main_model_form" model="ir.ui.view">
    <field name="name">main.model.form</field>
    <field name="model">module_name.main_model</field>
    <field name="arch" type="xml">
        <form string="Main Model" js_class="main_model_form">
            <header>
                <button name="action_confirm" type="object" string="Confirm" class="btn-primary" invisible="state != 'draft'"/>
                <button name="action_done" type="object" string="Done" class="btn-primary" invisible="state != 'confirmed'"/>
                <button name="action_cancel" type="object" string="Cancel" invisible="state in ['done', 'cancelled']"/>
                <field name="state" widget="statusbar" statusbar_visible="draft,confirmed,done"/>
            </header>
            <sheet>
                <div class="oe_title">
                    <label for="name" string="Reference"/>
                    <field name="name" class="oe_inline"/>
                </div>
                <group>
                    <group>
                        <field name="partner_id" widget="many2one_avoid_use"/>
                        <field name="date" widget="date"/>
                    </group>
                    <group>
                        <field name="company_id" groups="base.group_multi_company"/>
                        <field name="total_amount" widget="monetary"/>
                    </group>
                </group>
                <notebook>
                    <page string="Lines" name="lines">
                        <field name="line_ids">
                            <tree editable="bottom">
                                <field name="product_id"/>
                                <field name="quantity"/>
                                <field name="price" widget="monetary"/>
                                <field name="amount" widget="monetary" sum="Total"/>
                            </tree>
                        </field>
                    </page>
                </notebook>
            </sheet>
            <div class="oe_chatter">
                <field name="message_follower_ids"/>
                <field name="message_ids"/>
                <field name="activity_ids"/>
            </div>
        </form>
    </field>
</record>
```

### New Odoo 19.0 Field Widgets

```xml
<!-- AI Text Assistant -->
<field name="ai_content" widget="ai_text_assistant" options="{'max_length': 5000}"/>

<!-- Rich Text Content -->
<field name="rich_content" widget="rich_text_content"/>

<!-- Enhanced Selection -->
<field name="category" widget="selection_badge"/>

<!-- Mobile-Optimized Date -->
<field name="date" widget="date" options="{'mobile': true}"/>

<!-- Enhanced Many2one -->
<field name="partner_id" widget="many2one_avoid_use" options="{'no_create': True, 'no_open': True}"/>
```

## Security

### Access Rights (ir.model.access.csv)

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_main_model_user,access.main.model.user,model_module_name_main_model,base.group_user,1,1,1,0
access_main_model_manager,access.main.model.manager,model_module_name_main_model,group_module_name_manager,1,1,1,1
```

### Record Rules

```xml
<odoo>
    <data noupdate="1">
        <!-- Multi-company rule -->
        <record id="rule_main_model_multi_company" model="ir.rule">
            <field name="name">Main Model Multi-Company</field>
            <field name="model_id" ref="model_module_name_main_model"/>
            <field name="domain_force">['|',('company_id','=',False),('company_id','in',company_ids)]</field>
        </record>

        <!-- User can only see own records -->
        <record id="rule_main_model_own" model="ir.rule">
            <field name="name">Main Model Own Records</field>
            <field name="model_id" ref="model_module_name_main_model"/>
            <field name="domain_force">[('create_uid', '=', user.id)]</field>
            <field name="groups" eval="[(4, ref('base.group_user'))]"/>
        </record>
    </data>
</odoo>
```

## Testing

### Unit Tests

```python
from odoo.tests.common import TransactionCase
from odoo.exceptions import ValidationError

class TestMainModel(TransactionCase):

    def setUp(self):
        super().setUp()
        self.Model = self.env['module_name.main_model']
        self.partner = self.env.ref('base.res_partner_1')

    def test_create_record(self):
        """Test creating a new record"""
        record = self.Model.create({
            'partner_id': self.partner.id,
        })
        self.assertTrue(record.name)
        self.assertEqual(record.state, 'draft')

    def test_state_transitions(self):
        """Test state transitions"""
        record = self.Model.create({'partner_id': self.partner.id})

        # Draft to Confirmed
        record.action_confirm()
        self.assertEqual(record.state, 'confirmed')

        # Confirmed to Done
        record.action_done()
        self.assertEqual(record.state, 'done')

    def test_constraints(self):
        """Test validation constraints"""
        record = self.Model.create({'partner_id': self.partner.id})
        with self.assertRaises(ValidationError):
            record.partner_id = self.env.ref('base.main_partner').copy({
                'company_id': self.env.company.copy().id
            })

    def test_compute_fields(self):
        """Test computed fields"""
        record = self.Model.create({'partner_id': self.partner.id})
        # Create lines
        self.env['module_name.line_model'].create([
            {'main_id': record.id, 'amount': 100},
            {'main_id': record.id, 'amount': 200},
        ])
        self.assertEqual(record.total_amount, 300)
```

## Common Patterns

### onchange Pattern

```python
@api.onchange('partner_id')
def _onchange_partner_id(self):
    """Update fields when partner changes"""
    if self.partner_id:
        self.currency_id = self.partner_id.property_purchase_currency_id
        self.payment_term_id = self.partner_id.property_supplier_payment_term_id
        self.fiscal_position_id = self.env['account.fiscal.position'].with_context(
            force_company=self.company_id.id
        ).get_fiscal_position(self.partner_id.id)
    else:
        self.currency_id = self.env.company.currency_id
        self.payment_term_id = False
        self.fiscal_position_id = False
```

### Computed Multi-Company Default

```python
@api.model
def _get_default_company_id(self):
    """Get default company based on user context"""
    return self.env.company

company_id = fields.Many2one(
    'res.company',
    string='Company',
    default=_get_default_company_id,
)
```

### Smart Button Pattern

```python
# In model
def action_view_lines(self):
    """Action for smart button to view related lines"""
    self.ensure_one()
    action = {
        'name': _('Lines'),
        'type': 'ir.actions.act_window',
        'res_model': 'module_name.line_model',
        'view_mode': 'tree,form',
        'domain': [('main_id', '=', self.id)],
        'context': {'default_main_id': self.id},
    }
    return action

# Count field for smart button
line_count = fields.Integer(
    string='Line Count',
    compute='_compute_line_count',
)

@api.depends('line_ids')
def _compute_line_count(self):
    for record in self:
        record.line_count = len(record.line_ids)
```

## Debugging Tips

### Python Debugging

```python
# Add breakpoint (requires --dev mode)
import pdb; pdb.set_trace()

# Or use ipdb if available
import ipdb; ipdb.set_trace()

# Logging
import logging
_logger = logging.getLogger(__name__)
_logger.info('Debug info: %s', some_value)
```

### JavaScript Debugging

```javascript
// Console log
console.log('Debug:', this.state);

// Debugger breakpoint
debugger;

// Service access in console
const orm = owl.Component.current?.services?.orm;
```

### Common Issues

1. **ImportError**: Check `__init__.py` imports and module dependencies
2. **View not found**: Verify XML file is in `data` section of manifest
3. **Access denied**: Check `ir.model.access.csv` and record rules
4. **Compute not updating**: Verify `@api.depends` includes all dependency fields
5. **OWL component not rendering**: Check template name matches and bundle is loaded

## Odoo 19.0 Migration Notes

### From 18.0 to 19.0

1. **Python 3.11+ Required** - Update CI/CD and development environments
2. **OWL 2.0** - Convert OWL 1.x components to OWL 2.0 syntax
3. **New Widget Names** - Update widget references in views
4. **Asset Bundle Changes** - Use module-based asset loading
5. **API Deprecations** - Replace deprecated ORM methods

### Frontend Migration (OWL 1.x to 2.0)

```javascript
// OWL 1.x (Old)
odoo.define('module.MyComponent', function (require) {
    const Widget = require('web.Widget');
    return Widget.extend({
        // ...
    });
});

// OWL 2.0 (New)
/** @odoo-module **/
import { Component } from "@odoo/owl";
export class MyComponent extends Component {
    static template = "module_name.MyComponent";
    // ...
}
```

## References

- [Odoo Documentation](https://www.odoo.com/documentation/19.0/)
- [Odoo Developer Roadmap](https://www.odoo.com/documentation/19.0/developer.html)
- [OWL Documentation](https://github.com/odoo/owl/tree/master/doc)
