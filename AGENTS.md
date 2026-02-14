# AGENTS.md - Guidelines for AI Assistants

This is a Linux application configuration repository (dotfiles). It contains configuration files for various terminal emulators, system tools, and desktop applications.

## Repository Structure

```
configs-ril/
├── alacritty/       # Terminal emulator (TOML)
├── bat/             # Cat clone (config)
├── bpytop/          # System monitor
├── conky/           # System monitor
├── cosmic/          # COSMIC desktop
├── eza/             # ls replacement
├── fd/              # find replacement
├── GIMP/            # Image editor
├── gita/            # Git manager
├── glow/            # Markdown renderer
├── kitty/           # Terminal emulator (conf + Python)
├── lazygit/         # Git TUI (YAML)
├── macchina/        # System info
├── neofetch/        # System info (shell)
├── oh-my-posh/      # Shell prompt (TOML)
├── polybar/         # Status bar (conf + scripts)
├── ranger/          # File manager (Python)
├── ripgrep/         # Search tool
├── rofi/            # Application launcher
├── tealdeer/        # tldr client
├── wezterm/         # Terminal emulator (Lua)
├── zellij/          # Terminal multiplexer (KDL)
├── starship.toml    # Shell prompt
├── user-dirs.dirs   # XDG user directories
└── rilcritch.omp.toml  # Oh-my-posh theme
```

## Build/Lint/Test Commands

This repository has no build system, tests, or lint commands. Configuration files are used directly by their respective applications.

### Validation Commands (Optional)

- **TOML files**: `python3 -c "import tomllib; tomllib.load(open('file.toml', 'rb'))"`
- **YAML files**: `python3 -c "import yaml; yaml.safe_load(open('file.yml'))"`
- **Lua files**: `lua -p file.lua` (syntax check)
- **Python files**: `python3 -m py_compile file.py`

## Configuration File Conventions

### TOML Files (starship.toml, alacritty/alacritty.toml, rilcritch.omp.toml)

- Use `#` for comments
- Section headers: `[section_name]`
- Nested sections: `[parent.child]`
- Arrays: `["item1", "item2"]`
- Inline tables: `{ key = "value" }`
- Multi-line arrays with trailing commas encouraged

```toml
# Header comment describing the section
[section]
key = "value"
nested_array = [
    "item1",
    "item2",
]
```

### YAML Files (lazygit/config.yml)

- 2-space indentation
- Use single quotes for string values with special characters
- Lists use `-` prefix with space

```yaml
section:
  key: "value"
  list:
    - item1
    - item2
```

### Lua Files (wezterm/)

- Use `--[[ -- Header -- ]]--` for file headers
- Use `--[[ Section Name ]]--` for section dividers
- Module pattern: create table `M`, populate, return `M`
- Imports at top with `require()`

```lua
--[[ -- Module Name -- ]]--

local wezterm = require("wezterm")
local M = {}

-- Configuration here

return M

-- vim:fileencoding=utf-8:foldmethod=marker
```

### Python Files (kitty/tab_bar.py, polybar/scripts/, ranger/)

- Standard library imports first, then third-party, then local
- Use type hints in function signatures
- Constants in SCREAMING_SNAKE_CASE at top
- Private functions prefixed with `_`
- Error handling with try/except, return error values for display

```python
from datetime import datetime
from typing import Optional

CONSTANT_NAME = "value"

def _private_helper(arg: str) -> dict:
    ...

def public_function(arg: int) -> Optional[str]:
    try:
        ...
    except ValueError:
        return None
```

### Shell Scripts (polybar/scripts/, polybar/launch.sh)

- Shebang: `#!/usr/bin/env sh` for POSIX compatibility
- Comments with `#` and colon for section markers: `# Section Name {{{`
- Use `case` statements for conditional logic
- Variable assignment without `$`, usage with `$` or `${}`
- Double-quote variables to prevent word splitting

```sh
#!/usr/bin/env sh

# Section Name {{{
variable="value"

case "$variable" in
    pattern1)
        command
        ;;
    pattern2)
        command
        ;;
esac
# }}}
```

### KDL Files (zellij/config.kdl)

- Node syntax: `node_name "value" { children }`
- Properties: `property_name "value"`
- Comments: `//` for line comments

```kdl
section {
    property "value"
    child_node {
        nested_property "value"
    }
}
```

### Conf Files (kitty/kitty.conf, bat/config)

- `#` for comments
- `key value` syntax (no equals sign in kitty)
- Group sections with `# Section Name {{{` and `# }}}`
- Include other configs: `include /path/to/file`

## Style Guidelines

### General Principles

1. **No secrets in configs**: Never commit API keys, passwords, or tokens
2. **Theme consistency**: Prefer Nord/Nordic color themes across applications
3. **Nerd Fonts**: Use Nerd Font icons for visual elements
4. **Vim modelines**: Add at end of files:
   ```
   <!--- vim:fileencoding=utf-8:shiftwidth=4:tabstop=4 --->
   ```
   or
   ```
   -- vim:fileencoding=utf-8:foldmethod=marker
   ```

### Formatting

- **Indentation**: 4 spaces for most files, 2 for YAML
- **Line length**: Keep under 100 characters where practical
- **Trailing whitespace**: Remove
- **Final newline**: Include in all files

### Naming Conventions

- **Files**: lowercase with underscores (`tab_bar.py`) or no separators (`config.yml`)
- **Directories**: lowercase (`kitty/`, `lazygit/`)
- **Config keys**: Follow application defaults (usually snake_case)
- **Variables in scripts**: lowercase with underscores (`desktop_session`)

### Comment Style

- **Headers**: Describe file purpose at top
- **Sections**: Use fold markers `{{{` and `}}}` for large files
- **Inline**: Comment above the line being described
- **Disable markers**: Use `#` prefix to comment out alternatives

```conf
# Primary option
font_family "MonoLisa"

# Alternatives (commented out)
# font_family "FiraCode Nerd Font"
# font_family "JetBrainsMono Nerd Font"
```

### Error Handling

- **Python**: Return error strings/values for UI display (e.g., `"Err 1"`)
- **Shell**: Silent failures where appropriate, log errors to stderr
- **Config files**: Use `none`, `false`, or `""` to disable features

### Imports and Dependencies

- **Lua**: `local module = require("module")` at top
- **Python**: Standard library first, then third-party
- **Avoid**: External dependencies in shell scripts when possible

## File Organization Patterns

### Theme Files

Most applications with theming have a `themes/` subdirectory:
```
kitty/themes/
alacritty/themes/
zellij/themes/
```

Active theme is typically set via `include` or `theme =` directive.

### Modular Configs

Larger configurations are split into modules:
```
wezterm/
├── wezterm.lua      # Main entry, imports modules
├── conf/
│   └── init.lua     # Configuration module
├── colors/          # Color schemes
└── plugins/         # Plugin configs
```

## Common Patterns

### Multiple Theme Alternatives

Comment out inactive themes for easy switching:
```conf
# include themes/everforest.conf
include themes/nord.conf
# include themes/tokyonight.conf
```

### Feature Flags

Disable features with `disabled = true` or comment out:
```lua
config:set_strict_mode(true)
-- config.disable_feature = true
```

### Environment Variables

Define in dedicated sections:
```toml
[env]
TERM = "alacritty"
```

## Notes for AI Agents

1. When editing configs, preserve the existing structure and comment style
2. Match the formatting of nearby lines (indentation, spacing)
3. Keep alternative options commented out rather than deleted
4. Use the same theme family (Nord) for consistency
5. Add new application configs as subdirectories at root level
6. Vim modelines should match the file's actual formatting