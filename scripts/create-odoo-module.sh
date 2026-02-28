#!/usr/bin/env bash
# Odoo Module Scaffolding Script
# Creates a new Odoo module with proper structure for Odoo 19.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ODOO_VERSION="19.0"
AUTHOR="Your Company"
LICENSE="LGPL-3"
CATEGORY="Tools"
PYTHON_VERSION="3.11"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to prompt for input
prompt_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    if [ -n "$default" ]; then
        prompt="$prompt [$default]"
    fi

    read -p "$prompt: " input
    if [ -z "$input" ] && [ -n "$default" ]; then
        input="$default"
    fi
    eval "$var_name='$input'"
}

# Function to validate module name
validate_module_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z][a-z0-9_]*$ ]]; then
        print_error "Module name must start with a lowercase letter and contain only lowercase letters, numbers, and underscores"
        return 1
    fi
    return 0
}

# Function to create directory structure
create_directories() {
    local module_path="$1"
    print_info "Creating directory structure..."

    mkdir -p "$module_path"/{models,views,security,data,demo,static/{description,src/components},i18n,controllers,report,wizard,tests}
    print_success "Directories created"
}

# Function to create __manifest__.py
create_manifest() {
    local module_path="$1"
    local module_name="$2"
    local description="$3"
    local depends="$4"

    print_info "Creating __manifest__.py..."

    cat > "$module_path/__manifest__.py" << EOF
# -*- coding: utf-8 -*-
{
    'name': '$description',
    'version': '$ODOO_VERSION.1.0.0',
    'category': '$CATEGORY',
    'summary': 'Brief summary of $module_name',
    'description': """
        $description
        =====================
        Long description of your module functionality.
    """,
    'author': '$AUTHOR',
    'website': 'https://www.yourcompany.com',
    'license': '$LICENSE',
    'depends': [
        'base',
$depends
    ],
    'data': [
        'security/security_rules.xml',
        'security/ir.model.access.csv',
        'views/${module_name}_views.xml',
        'views/menus.xml',
    ],
    'assets': {
        'web.assets_backend': [
            '${module_name}/static/src/components/**/*',
            '${module_name}/static/src/xml/**/*.xml',
            '${module_name}/static/src/scss/**/*.scss',
        ],
    },
    'demo': [
        'demo/demo_data.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
    'post_init_hook': 'post_init_hook',
}
EOF
    print_success "__manifest__.py created"
}

# Function to create __init__.py files
create_init_files() {
    local module_path="$1"
    local module_name="$2"

    print_info "Creating Python initialization files..."

    # Main __init__.py
    cat > "$module_path/__init__.py" << EOF
# -*- coding: utf-8 -*-

from . import models
from . import controllers

def post_init_hook(env):
    """Post-installation hook"""
    pass
EOF

    # models/__init__.py
    cat > "$module_path/models/__init__.py" << EOF
# -*- coding: utf-8 -*-

from . import ${module_name}
EOF

    # controllers/__init__.py
    cat > "$module_path/controllers/__init__.py" << EOF
# -*- coding: utf-8 -*-

from . import main
EOF

    # tests/__init__.py
    cat > "$module_path/tests/__init__.py" << EOF
# -*- coding: utf-8 -*-

from . import test_models
EOF

    # wizard/__init__.py
    cat > "$module_path/wizard/__init__.py" << EOF
# -*- coding: utf-8 -*-
EOF

    print_success "Python initialization files created"
}

# Function to create base model
create_base_model() {
    local module_path="$1"
    local module_name="$2"

    print_info "Creating base model..."

    # Convert module_name to class name (e.g., my_module -> MyModule)
    local class_name=$(echo "$module_name" | sed -r 's/(^|_)([a-z])/\u\2/g')

    cat > "$module_path/models/${module_name}.py" << EOF
# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from odoo.exceptions import ValidationError


class ${class_name}(models.Model):
    _name = '${module_name}.${module_name}'
    _description = 'Base ${class_name} Model'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'name desc'

    name = fields.Char(
        string='Name',
        required=True,
        tracking=True,
    )

    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('done', 'Done'),
        ('cancelled', 'Cancelled'),
    ], string='Status', default='draft', tracking=True)

    company_id = fields.Many2one(
        'res.company',
        string='Company',
        required=True,
        default=lambda self: self.env.company,
    )

    active = fields.Boolean(
        string='Active',
        default=True,
    )

    # Constraints
    _sql_constraints = [
        ('name_unique', 'UNIQUE(name)', 'Name must be unique!'),
    ]

    @api.constrains('name')
    def _check_name(self):
        for record in self:
            if not record.name:
                raise ValidationError(_('Name is required.'))

    def action_confirm(self):
        """Confirm the record"""
        self.write({'state': 'confirmed'})
        return True

    def action_done(self):
        """Mark as done"""
        self.write({'state': 'done'})
        return True

    def action_cancel(self):
        """Cancel the record"""
        self.write({'state': 'cancelled'})
        return True

    def action_draft(self):
        """Reset to draft"""
        self.write({'state': 'draft'})
        return True
EOF
    print_success "Base model created"
}

# Function to create main controller
create_controller() {
    local module_path="$1"
    local module_name="$2"

    print_info "Creating main controller..."

    cat > "$module_path/controllers/main.py" << EOF
# -*- coding: utf-8 -*-

from odoo import http
from odoo.http import request


class MainController(http.Controller):

    @http.route(['/${module_name}'], type='http', auth='public', website=True)
    def index(self, **kwargs):
        """Main route for ${module_name}"""
        return request.render('${module_name}.index_template', {
            'name': '${module_name}',
        })
EOF
    print_success "Main controller created"
}

# Function to create views
create_views() {
    local module_path="$1"
    local module_name="$2"

    print_info "Creating views..."

    # Main views XML
    cat > "$module_path/views/${module_name}_views.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <data>
        <!-- Tree View -->
        <record id="view_${module_name}_tree" model="ir.ui.view">
            <field name="name">${module_name}.tree</field>
            <field name="model">${module_name}.${module_name}</field>
            <field name="arch" type="xml">
                <tree string="${module_name}">
                    <field name="name"/>
                    <field name="state"/>
                    <field name="company_id" groups="base.group_multi_company"/>
                </tree>
            </field>
        </record>

        <!-- Form View -->
        <record id="view_${module_name}_form" model="ir.ui.view">
            <field name="name">${module_name}.form</field>
            <field name="model">${module_name}.${module_name}</field>
            <field name="arch" type="xml">
                <form string="${module_name}">
                    <header>
                        <button name="action_confirm" type="object" string="Confirm" class="btn-primary" invisible="state != 'draft'"/>
                        <button name="action_done" type="object" string="Done" class="btn-primary" invisible="state != 'confirmed'"/>
                        <button name="action_cancel" type="object" string="Cancel" invisible="state in ['done', 'cancelled']"/>
                        <button name="action_draft" type="object" string="Reset to Draft" invisible="state != 'cancelled'"/>
                        <field name="state" widget="statusbar" statusbar_visible="draft,confirmed,done"/>
                    </header>
                    <sheet>
                        <div class="oe_title">
                            <label for="name" string="Name"/>
                            <field name="name" class="oe_inline"/>
                        </div>
                        <group>
                            <group>
                                <field name="company_id" groups="base.group_multi_company"/>
                            </group>
                            <group>
                                <field name="active"/>
                            </group>
                        </group>
                    </sheet>
                    <div class="oe_chatter">
                        <field name="message_follower_ids"/>
                        <field name="message_ids"/>
                        <field name="activity_ids"/>
                    </div>
                </form>
            </field>
        </record>

        <!-- Search View -->
        <record id="view_${module_name}_search" model="ir.ui.view">
            <field name="name">${module_name}.search</field>
            <field name="model">${module_name}.${module_name}</field>
            <field name="arch" type="xml">
                <search string="${module_name}">
                    <field name="name"/>
                    <filter name="draft" string="Draft" domain="[('state','=','draft')]"/>
                    <filter name="confirmed" string="Confirmed" domain="[('state','=','confirmed')]"/>
                    <filter name="done" string="Done" domain="[('state','=','done')]"/>
                    <separator/>
                    <filter name="active" string="Archived" domain="[('active','=',False)]"/>
                </search>
            </field>
        </record>

        <!-- Action -->
        <record id="action_${module_name}" model="ir.actions.act_window">
            <field name="name">${module_name}</field>
            <field name="res_model">${module_name}.${module_name}</field>
            <field name="view_mode">tree,form</field>
            <field name="help" type="html">
                <p class="o_view_nocontent_smiling_face">
                    Create your first ${module_name} record!
                </p>
            </field>
        </record>
    </data>
</odoo>
EOF

    # Menus XML
    cat > "$module_path/views/menus.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <data>
        <!-- Root Menu -->
        <menuitem id="menu_${module_name}_root" name="${module_name}" sequence="10"/>

        <!-- Sub Menu -->
        <menuitem id="menu_${module_name}" name="${module_name}" parent="menu_${module_name}_root"
                  action="action_${module_name}" sequence="1"/>
    </data>
</odoo>
EOF

    print_success "Views created"
}

# Function to create security files
create_security_files() {
    local module_path="$1"
    local module_name="$2"

    print_info "Creating security files..."

    # Access rights CSV
    cat > "$module_path/security/ir.model.access.csv" << EOF
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_${module_name}_user,access.${module_name}.user,model_${module_name}_${module_name},base.group_user,1,1,1,0
access_${module_name}_manager,access.${module_name}.manager,model_${module_name}_${module_name},base.group_system,1,1,1,1
EOF

    # Security rules XML
    cat > "$module_path/security/security_rules.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <data noupdate="1">
        <!-- Multi-company Rule -->
        <record id="rule_${module_name}_company" model="ir.rule">
            <field name="name">${module_name} Multi-Company</field>
            <field name="model_id" ref="model_${module_name}_${module_name}"/>
            <field name="domain_force">['|',('company_id','=',False),('company_id','in',company_ids)]</field>
        </record>

        <!-- Active Records Rule -->
        <record id="rule_${module_name}_active" model="ir.rule">
            <field name="name">${module_name} Active Records</field>
            <field name="model_id" ref="model_${module_name}_${module_name}"/>
            <field name="domain_force">[('active','=',True)]</field>
            <field name="perm_read" eval="True"/>
            <field name="perm_write" eval="False"/>
            <field name="perm_create" eval="False"/>
            <field name="perm_unlink" eval="False"/>
        </record>
    </data>
</odoo>
EOF

    print_success "Security files created"
}

# Function to create demo data
create_demo_data() {
    local module_path="$1"
    local module_name="$2"

    print_info "Creating demo data..."

    cat > "$module_path/demo/demo_data.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <data noupdate="1">
        <!-- Demo Records -->
        <record id="demo_${module_name}_1" model="${module_name}.${module_name}">
            <field name="name">Demo Record 1</field>
            <field name="state">draft</field>
        </record>
        <record id="demo_${module_name}_2" model="${module_name}.${module_name}">
            <field name="name">Demo Record 2</field>
            <field name="state">confirmed</field>
        </record>
    </data>
</odoo>
EOF

    print_success "Demo data created"
}

# Function to create tests
create_tests() {
    local module_path="$1"
    local module_name="$2"

    print_info "Creating test files..."

    cat > "$module_path/tests/test_models.py" << EOF
# -*- coding: utf-8 -*-

from odoo.tests.common import TransactionCase
from odoo.exceptions import ValidationError


class Test${module_name^}(TransactionCase):

    def setUp(self):
        super().setUp()
        self.Model = self.env['${module_name}.${module_name}']

    def test_create_record(self):
        """Test creating a new record"""
        record = self.Model.create({
            'name': 'Test Record',
        })
        self.assertTrue(record.id)
        self.assertEqual(record.name, 'Test Record')
        self.assertEqual(record.state, 'draft')

    def test_state_transitions(self):
        """Test state transitions"""
        record = self.Model.create({'name': 'Test Record'})

        # Draft to Confirmed
        record.action_confirm()
        self.assertEqual(record.state, 'confirmed')

        # Confirmed to Done
        record.action_done()
        self.assertEqual(record.state, 'done')

        # Cannot transition from done to confirmed
        self.assertFalse(record.action_confirm())

    def test_name_constraint(self):
        """Test name constraint"""
        with self.assertRaises(ValidationError):
            self.Model.create({'name': ''})
EOF

    print_success "Test files created"
}

# Function to create i18n template
create_i18n_template() {
    local module_path="$1"
    local module_name="$2"

    print_info "Creating i18n template..."

    # Create POT file header
    cat > "$module_path/i18n/${module_name}.pot" << EOF
# Translation of Odoo Server.
# This file contains the translation of the following modules:
#	* ${module_name}
#
msgid ""
msgstr ""
"Project-Id-Version: Odoo Server ${ODOO_VERSION}\n"
"Report-Msgid-Bugs-To: \n"
"POT-Creation-Date: $(date -u +%Y-%m-%d\\ %H:%M+0000)\n"
"PO-Revision-Date: $(date -u +%Y-%m-%d\\ %H:%M+0000)\n"
"Last-Translator: \n"
"Language-Team: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"

#. module: ${module_name}
#: model:ir.model.fields,field_description:${module_name}.field_${module_name}_${module_name}_name
msgid "Name"
msgstr ""

#. module: ${module_name}
#: model:ir.model.fields,field_description:${module_name}.field_${module_name}_${module_name}_state
msgid "Status"
msgstr ""
EOF

    print_success "i18n template created"
}

# Function to create static description
create_static_description() {
    local module_path="$1"
    local module_name="$2"

    print_info "Creating static description..."

    # Index HTML
    cat > "$module_path/static/description/index.html" << EOF
<section class="oe_container">
    <div class="oe_row oe_spaced">
        <div class="oe_span12">
            <h2 class="oe_slogan" style="color:#875A7B;">${module_name}</h2>
            <h3 class="oe_slogan">Brief description of your module</h3>
        </div>
    </div>
</section>

<section class="oe_container">
    <div class="oe_row oe_spaced">
        <div class="oe_span12">
            <h3 class="oe_slogan">Key Features</h3>
            <div class="oe_span6">
                <ul class="oe_list">
                    <li>Feature 1</li>
                    <li>Feature 2</li>
                    <li>Feature 3</li>
                </ul>
            </div>
            <div class="oe_span6">
                <ul class="oe_list">
                    <li>Feature 4</li>
                    <li>Feature 5</li>
                    <li>Feature 6</li>
                </ul>
            </div>
        </div>
    </div>
</section>
EOF

    # Create a simple icon placeholder
    print_warning "Remember to add an icon.png file to static/description/"

    print_success "Static description created"
}

# Function to create README
create_readme() {
    local module_path="$1"
    local module_name="$2"
    local description="$3"

    print_info "Creating README.md..."

    cat > "$module_path/README.md" << EOF
# ${module_name}

${description}

## Odoo Version

${ODOO_VERSION}

## Installation

1. Copy the module to your Odoo addons directory
2. Update the Odoo apps list
3. Install the module from the Apps menu

## Configuration

After installation, configure the module via Settings > ${description}

## Usage

1. Go to the ${module_name} menu
2. Create a new record
3. Fill in the required fields
4. Save the record

## Bug Tracker

Bugs are tracked on [GitHub Issues](https://github.com/your/repository/issues).

## Credits

* **Author:** ${AUTHOR}
* **Website:** https://www.yourcompany.com

## License

This module is licensed under ${LICENSE}.
EOF

    print_success "README.md created"
}

# Main execution
main() {
    echo -e "${GREEN}"
    echo "========================================"
    echo "  Odoo Module Scaffolding Script"
    echo "  for Odoo ${ODOO_VERSION}"
    echo "========================================"
    echo -e "${NC}"

    # Get module details
    prompt_input "Module name (lowercase with underscores)" "" module_name
    if ! validate_module_name "$module_name"; then
        exit 1
    fi

    prompt_input "Module description" "" description
    prompt_input "Author" "$AUTHOR" AUTHOR
    prompt_input "License" "$LICENSE" LICENSE
    prompt_input "Category" "$CATEGORY" CATEGORY
    prompt_input "Additional dependencies (comma-separated)" "" depends_input

    # Convert dependencies to format
    depends_formatted=""
    if [ -n "$depends_input" ]; then
        IFS=',' read -ra DEPS <<< "$depends_input"
        for dep in "${DEPS[@]}"; do
            dep=$(echo "$dep" | xargs)
            depends_formatted="$depends_manifest        '$dep',\n"
        done
    fi

    # Get output path
    prompt_input "Output path" "./addons" output_path

    # Create full module path
    module_path="$output_path/$module_name"

    # Check if module already exists
    if [ -d "$module_path" ]; then
        print_warning "Module directory already exists: $module_path"
        prompt_input "Continue and overwrite? (y/N)" "" confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            print_info "Aborted"
            exit 0
        fi
    fi

    print_info "Creating module: $module_name"
    print_info "Description: $description"
    print_info "Path: $module_path"
    echo ""

    # Create the module
    create_directories "$module_path"
    create_manifest "$module_path" "$module_name" "$description" "$depends_formatted"
    create_init_files "$module_path" "$module_name"
    create_base_model "$module_path" "$module_name"
    create_controller "$module_path" "$module_name"
    create_views "$module_path" "$module_name"
    create_security_files "$module_path" "$module_name"
    create_demo_data "$module_path" "$module_name"
    create_tests "$module_path" "$module_name"
    create_i18n_template "$module_path" "$module_name"
    create_static_description "$module_path" "$module_name"
    create_readme "$module_path" "$module_name" "$description"

    echo ""
    print_success "Module created successfully!"
    echo ""
    echo "Module structure:"
    echo "  $module_path/"
    echo ""
    echo "Next steps:"
    echo "  1. Review the generated files"
    echo "  2. Add an icon.png to static/description/"
    echo "  3. Update the manifest with your specific dependencies"
    echo "  4. Implement your custom logic"
    echo "  5. Test the module"
    echo ""
    print_info "To install in Odoo:"
    echo "  1. Copy/Link the module to your Odoo addons directory"
    echo "  2. Update apps list"
    echo "  3. Install from Apps menu"
    echo ""
}

# Run main function
main "$@"
