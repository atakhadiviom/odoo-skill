# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is an Odoo 19.0 development skill for Claude Code - a collection of slash commands, templates, and reference documentation for developing Odoo modules (versions 14.0-19.0, with 19.0 as primary target).

## Architecture

### Directory Structure

```
.claude/
├── commands/          # Slash command definitions for Claude Code
├── skills/odoo/       # Odoo 19.0 reference skill (auto-loaded)
└── settings.local.json # Permission configuration

.odoo-dev/
├── config.json        # Odoo version compatibility matrix
├── steering/          # Project-level steering documents (generated)
└── templates/         # Specification templates (requirements, design, tasks)

scripts/
└── create-odoo-module.sh  # Module scaffolding script
```

### Core Concepts

**Odoo-Specific Workflow:** This repository uses an Odoo-specific specification workflow that differs from standard Claude Code practices. Specifications are stored in module directories (`[module-path]/.spec/`) rather than the project-level `.claude/specs/`.

**Three-Layer Command System:**
1. **Steering** (`/odoo-steering`) - Generate project-level guidelines
2. **Specification** (`/odoo-spec-create`, `/odoo-feature-create`) - Create module/feature specs
3. **Execution** (`/odoo-spec-execute`, `/odoo-bug-fix`) - Implement or fix

**Template Hierarchy:** Commands use templates from `.odoo-dev/templates/`:
- `odoo-requirements-template.md` - Business requirements
- `odoo-design-template.md` - Technical design (includes OWL 2.0 patterns)
- `odoo-tasks-template.md` - Implementation task breakdown

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/odoo-steering` | Generate project steering documents (business rules, tech stack, module standards) |
| `/odoo-spec-create` | Create full module specifications |
| `/odoo-feature-create` | Create feature specifications for existing modules |
| `/odoo-bug-fix` | Create systematic bug fix workflows |
| `/odoo-bug-analyze` | Analyze existing bugs |
| `/odoo-bug-verify` | Verify bug fixes |
| `/odoo-spec-status` | Check specification status |
| `/odoo-module-test` | Run module tests |

## Creating a New Odoo Module

```bash
./scripts/create-odoo-module.sh
```

Interactive script that creates:
- Complete module directory structure
- `__manifest__.py` with Odoo 19.0 format
- Base model with mail.thread inheritance
- Security files (access rights, record rules)
- Demo data and unit tests
- OWL 2.0 component structure in `static/src/components/`

## Odoo Version Compatibility

The `.odoo-dev/config.json` defines supported versions:

| Version | Python | PostgreSQL | LTS |
|---------|--------|------------|-----|
| 17.0 | 3.10 | 14 | Yes (until 2034-05) |
| 18.0 | 3.11 | 15 | No |
| 19.0 | 3.11+ | 15+ | Yes (primary target) |

**Odoo 19.0 Key Changes:**
- Frontend: OWL 2.0 (complete rewrite from OWL 1.x)
- New widgets: `ai_text_assistant`, `rich_text_content`
- Enhanced mobile responsiveness
- Asset bundle structure changes

## Reference Skill

The `.claude/skills/odoo/SKILL.md` file contains:
- OWL 2.0 component patterns
- Model/View development templates
- Security setup patterns
- Common code patterns (onchange, constraints, computed fields)
- Migration notes from 18.0 to 19.0

This is automatically loaded when working on Odoo projects.

## Module Standards

When creating or modifying Odoo modules:

1. **Naming**: Use lowercase with underscores (`my_module`)
2. **Model files**: Use descriptive names, not module prefixes (`product.py` not `my_module_product.py`)
3. **Frontend components**: Place in `static/src/components/[component_name]/` with .js, .xml, .scss
4. **Security**: Always include `ir.model.access.csv` and record rules for multi-company
5. **Testing**: Target 80% coverage with pytest-odoo
