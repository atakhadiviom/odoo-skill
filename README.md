# Odoo Skill for Claude Code

A comprehensive development skill for [Claude Code](https://claude.ai/code) that provides Odoo 19.0 support, including module development, bug fixing workflows, and full development lifecycle capabilities.

## Features

- **13 Slash Commands** for Odoo-specific workflows
- **Odoo 19.0 Support** including OWL 2.0, Python 3.11+, PostgreSQL 15+
- **Module Scaffolding Script** for quick module creation
- **Reference Documentation** built-in as a Claude skill
- **Specification Templates** for requirements, design, and implementation tasks
- **Bug Fix Workflows** with systematic debugging approach

## Version Support

| Odoo Version | Python | PostgreSQL | LTS Status |
|--------------|--------|------------|------------|
| 14.0 - 16.0 | 3.8 - 3.10 | 12 - 14 | Maintenance |
| 17.0 | 3.10 | 14 | LTS until 2034-05 |
| 18.0 | 3.11 | 15 | Stable |
| **19.0** | **3.11+** | **15+** | **LTS (Primary)** |

## Installation

### Option 1: Clone to Your Project

```bash
git clone https://github.com/atakhadiviom/odoo-skill.git
cd odoo-skill

# Copy the .claude and .odoo-dev directories to your project
cp -r .claude /path/to/your/project/
cp -r .odoo-dev /path/to/your/project/
```

### Option 2: Install as Global Skill

```bash
# Clone the repository
git clone https://github.com/atakhadiviom/odoo-skill.git ~/.claude/skills/odoo-skill

# Create a symlink or copy to your global Claude skills directory
ln -s ~/.claude/skills/odoo-skill/.claude/skills/odoo ~/.claude/skills/
```

### Option 3: Use in Odoo Project

Copy the entire repository to your Odoo addons or project root:

```bash
cp -r odoo-skill/* /path/to/odoo-project/
```

## Slash Commands

Once installed, these commands are available in Claude Code:

| Command | Description |
|---------|-------------|
| `/odoo-steering` | Generate project steering documents |
| `/odoo-spec-create` | Create module specifications |
| `/odoo-feature-create` | Create feature specifications |
| `/odoo-bug-fix` | Fix bugs with systematic workflow |
| `/odoo-bug-analyze` | Analyze existing bugs |
| `/odoo-bug-verify` | Verify bug fixes |
| `/odoo-spec-status` | Check specification status |
| `/odoo-spec-execute` | Execute specifications |
| `/odoo-spec-list` | List all specifications |
| `/odoo-module-test` | Run module tests |

## Usage Examples

### Create a New Odoo Module

```bash
./scripts/create-odoo-module.sh
```

The script will prompt for:
- Module name (lowercase with underscores)
- Description
- Author, license, category
- Dependencies

Creates a complete module structure with models, views, security, tests, and OWL 2.0 components.

### Generate Project Steering Documents

```
/odoo-steering
```

Generates `.odoo-dev/steering/` documents:
- `business-rules.md` - ERP business logic standards
- `technical-stack.md` - Odoo technical guidelines
- `module-standards.md` - Custom module development rules

### Create a Feature Specification

```
/odoo-feature-create my-module-awesome-feature "Implement an awesome feature for my module"
```

Creates specification documents in `[module-path]/.spec/features/[feature-name]/`

### Fix a Bug

```
/odoo-bug-fix my-module_calculation-error "Inventory calculation returns wrong values"
```

Creates systematic bug fix workflow with analysis, reproduction steps, and testing strategy.

## Odoo 19.0 Key Features

### OWL 2.0 Components

```javascript
/** @odoo-module **/
import { Component, useState, onMounted } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";

export class MyComponent extends Component {
    static template = "module_name.MyComponent";

    setup() {
        this.orm = useService("orm");
        this.state = useState({ data: [] });
    }
}
```

### New Field Widgets

```xml
<!-- AI Text Assistant -->
<field name="content" widget="ai_text_assistant"/>

<!-- Rich Text Content -->
<field name="description" widget="rich_text_content"/>

<!-- Enhanced Kanban -->
<field name="state" widget="kanban_state_selection" options="{'clickable': '1'}"/>
```

## Directory Structure

```
odoo-skill/
├── .claude/
│   ├── commands/           # Slash command definitions
│   ├── skills/odoo/        # Odoo 19.0 reference skill
│   └── settings.local.json # Permissions configuration
├── .odoo-dev/
│   ├── config.json         # Version compatibility config
│   └── templates/          # Specification templates
├── scripts/
│   └── create-odoo-module.sh
└── README.md
```

## Requirements

- Claude Code (claude.ai/code)
- Bash (for scaffolding script)
- Odoo 14.0-19.0 (for module development)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

LGPL-3

## Author

Created for the Odoo development community.

## See Also

- [Odoo Documentation](https://www.odoo.com/documentation/19.0/)
- [Claude Code Documentation](https://claude.ai/code)
- [OWL Documentation](https://github.com/odoo/owl)
