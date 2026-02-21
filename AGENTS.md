# AGENTS.md

Guidelines for agentic coding assistants working in this repository.
This is a Linux dotfiles/configs repo with mixed formats (TOML, YAML, Lua,
Python, shell, KDL, and app-specific conf files).

## Build / Lint / Test

There is no unified build, lint, or test system in this repo.
Configs are consumed directly by their respective applications.

### Single test

No test framework is configured, so there is no single-test command.
If you need to validate a specific file, use the format checks below.

### Format validation (per file)

- TOML: `python3 -c "import tomllib; tomllib.load(open('file.toml','rb'))"`
- YAML: `python3 -c "import yaml; yaml.safe_load(open('file.yml'))"`
- Lua: `lua -p file.lua`
- Python: `python3 -m py_compile file.py`
- Shell: `sh -n file.sh` (POSIX syntax check)

## Repository Structure (high level)

configs-ril/
- alacritty/, kitty/, wezterm/ (terminal emulators)
- polybar/, rofi/, zellij/ (desktop UI tools)
- ranger/, bat/, ripgrep/, fd/, eza/ (CLI tools)
- starship.toml, user-dirs.dirs, rilcritch.omp.toml (top-level configs)

## Code Style Guidelines

### General

- Preserve existing file structure and comment style.
- Keep alternative options commented out instead of deleting.
- Match the surrounding formatting (indentation, spacing, key order).
- Avoid secrets: never add tokens, passwords, or API keys.
- Themes: favor the existing Nord/Nordic palette when adding colors.
- Nerd Fonts: prefer Nerd Font icon variants where the file already uses them.

### Formatting

- Indentation: 4 spaces by default, 2 spaces for YAML.
- Line length: keep under 100 characters where practical.
- Trailing whitespace: remove.
- Final newline: always include.

### Naming

- Files/dirs: lowercase with underscores or no separators.
- Variables in scripts: lowercase_with_underscores.
- Constants: SCREAMING_SNAKE_CASE (Python).
- Config keys: follow each app's established conventions.

### Imports

- Python: standard library, then third-party, then local imports.
- Lua: `local module = require("module")` at the top.

### Types

- Python: use type hints for function signatures where applicable.
- Lua: avoid ad-hoc globals; use module tables (`local M = {}` then return `M`).

### Error handling

- Python: catch expected exceptions and return values suitable for UI display.
- Shell: prefer predictable exit codes; log errors to stderr when helpful.
- Configs: disable features with `false`, `none`, or empty strings per app.

## File-Type Conventions

### TOML

- Comments: `#`
- Sections: `[section]`, nested `[parent.child]`
- Arrays: prefer multi-line arrays with trailing commas

### YAML

- 2-space indentation
- Use quotes for strings with special characters

### Lua (wezterm/)

- File header/sections use block comments when present
- `require()` imports at top
- Return a module table `M`

### Python (kitty/, polybar/scripts/, ranger/)

- Prefer small helpers; keep side effects contained
- Private helpers prefixed with `_`

### Shell (polybar/scripts/, launchers)

- Shebang: `#!/usr/bin/env sh` for POSIX scripts
- Quote variables to avoid word splitting
- Prefer `case` for multi-branch conditionals
- Section markers may use `# Section Name {{{` and `# }}}`

### KDL (zellij/)

- Comments: `//`
- Node syntax: `node "value" { children }`

### Conf (kitty.conf, bat/config, etc.)

- Comments: `#`
- Group sections with fold markers when present
- Use `include` for modularization

## Layout and Organization Patterns

- Themes often live under `themes/` subdirectories
- Larger configs are split into modules and imported by a main file
- Environment variables are grouped in dedicated sections when supported

## Vim modelines

Use existing modelines if present and keep them accurate for the file.
Examples already used in this repo:

- `<!--- vim:fileencoding=utf-8:shiftwidth=4:tabstop=4 --->`
- `-- vim:fileencoding=utf-8:foldmethod=marker`

## Agent notes

- Do not introduce unrelated formatting changes.
- If you add a new config, place it at the repo root unless an existing
  subdirectory matches the tool.
- Avoid external dependencies in shell scripts when possible.

## Cursor / Copilot Rules

No `.cursorrules`, `.cursor/rules/`, or `.github/copilot-instructions.md`
were found in this repository at the time of writing.
