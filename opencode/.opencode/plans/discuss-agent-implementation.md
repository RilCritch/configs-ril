# Discuss Agent Implementation Plan

**Version:** 1.0  
**Date:** February 16, 2026  
**Status:** Ready for Implementation

---

## 📋 Executive Summary

Create a read-only "Discuss" agent for OpenCode that acts as an expert project consultant. This agent can explore codebases, run safe inspection commands, access web documentation, and engage in interactive discussions about projects while being completely prevented from making any file modifications.

---

## 🎯 Objectives

### Primary Goals
1. Create a safe, read-only agent for project exploration and discussion
2. Enable comprehensive code inspection without modification risks
3. Provide access to web documentation for informed discussions
4. Support interactive, conversational engagement about project architecture

### Success Criteria
- ✅ Agent cannot modify any files (enforced at multiple levels)
- ✅ All read-only bash commands work without approval friction
- ✅ Dangerous commands are blocked or require approval
- ✅ Agent is accessible via Tab key switching
- ✅ Web documentation fetching works seamlessly
- ✅ Agent appears with blue color in UI

---

## 📐 Architecture

### Configuration Strategy
- **File Organization:** Separate agent config file referenced from main config
- **Format:** JSONC with comprehensive inline comments
- **Location:** `/home/rc/Repos/configs-ril/opencode/agents/discuss.jsonc`
- **Integration:** File reference in main `opencode.jsonc`

### Agent Specifications

| Property | Value | Rationale |
|----------|-------|-----------|
| **Mode** | `primary` | User-switchable via Tab key |
| **Temperature** | `0.3` | Balanced: analytical yet conversational |
| **Steps** | `15` | Allows deeper exploration than default |
| **Color** | `blue` | Visual distinction in UI |
| **Model** | *inherit* | Uses global model configuration |

### Tool Configuration

**Disabled Tools (Write Operations):**
- `edit: false` - No file editing
- `write: false` - No file writing
- `patch: false` - No file patching
- `multiedit: false` - No multi-file editing

**Enabled Tools:**
- `bash: true` - With comprehensive permission restrictions
- Read tools: `read`, `glob`, `grep` - Available by default
- `webfetch` - Allowed for documentation access
- `task` - Can spawn subagents for specialized tasks

---

## 🔒 Security Architecture

### Three-Layer Protection Model

#### Layer 1: Tool-Level (Strongest)
Complete disabling of write-capable tools:
- `edit`, `write`, `patch`, `multiedit` = `false`
- No code path to file modification

#### Layer 2: Permission-Level (Enforcement)
- `permission.edit: "deny"` - Explicit denial of all edit operations
- `permission.bash: {...}` - Granular command control
- `permission.webfetch: "allow"` - Unrestricted documentation access

#### Layer 3: Bash Command Permissions (Granular)

**Permission Strategy:**
```
Default: "ask" - Unlisted commands require approval
Specific allows: Safe read-only operations
Specific denies: Destructive operations
```

### Bash Permission Categories

#### 🚫 DENY - Destructive Operations (Auto-blocked)

**File System Modifications:**
```
rm, mv, cp, chmod, chown, ln, mkdir, rmdir, touch, dd, truncate
```

**Write Operations:**
```
sed -i, perl -pi, tee, echo
```
*Note: `echo` denied to prevent `echo "data" > file.txt` attacks*

**Process/System Control:**
```
kill, killall, pkill, shutdown, reboot, systemctl, service
```

**Package Managers (All Install Operations):**
```
npm install, npm i, pnpm add, pnpm install
yarn add, yarn install, bun add, bun install
pip install, poetry add, poetry install
cargo add, cargo install, brew install
apt, dnf, yum, gem install, composer install
go get, go install
```

**Script Execution (Arbitrary Code):**
```
bash -c, sh -c, python -c, python -m, python3 -c, python3 -m
node -e, node -p, ruby -e, perl -e, exec, eval, xargs
```

**Git Write Operations:**
```
git add, git commit, git push, git pull, git fetch
git merge, git rebase, git reset, git checkout
git switch, git restore, git stash, git apply
git cherry-pick, git revert, git tag, git branch
git rm, git mv, git clean, git submodule
```

#### ❓ ASK - Useful but Requires Approval

```
find        - Can use -exec or -delete (dangerous)
""          - Default fallback for unlisted commands
```

#### ✅ ALLOW - Safe Read-Only Operations

**System Information:**
```
pwd, uname, whoami, id, date, which, command -v, type, env, printenv
```

**File/Directory Listing:**
```
ls, tree, realpath, readlink, basename, dirname
```

**File Reading:**
```
cat, head, tail, less, more, sed -n, wc, file, stat, du, df
```

**Archive/Compression Reading:**
```
zcat, zless, gunzip -c, unzip -l, tar -t
```

**Text Processing:**
```
rg, grep, egrep, fgrep, cut, sort, uniq, tr
awk, diff, comm, cmp, jq, yq
```

**Git Read Operations:**
```
git status, git diff, git log, git show, git remote -v
git rev-parse, git describe, git ls-files, git grep
git blame, git show-ref, git symbolic-ref, git for-each-ref
git branch --list, git tag --list
git config --get, git config --list
```

**Package Manager Information:**

*Node.js Ecosystem:*
```
node --version, npm --version, npm ls, npm list, npm view
pnpm --version, pnpm list, yarn --version, bun --version
```

*Python Ecosystem:*
```
python --version, python3 --version
pip --version, pip list, pip show
poetry --version, poetry show
uv --version, uv pip list
```

*Rust Ecosystem:*
```
rustc --version, cargo --version, cargo metadata, cargo tree
```

*Go Ecosystem:*
```
go version, go env, go list, go mod graph
```

*Other Languages:*
```
java -version, javac -version
ruby --version, gem list
php --version, composer show
dotnet --info, dotnet --version, dotnet list package
```

**Build Tools:**
```
make -n     - Dry-run only (no execution)
```

---

## 🎨 Agent Prompt Design

### Role Definition
```
You are Discuss: a read-only, senior engineer and architect.
```

### Core Responsibilities
1. **Understand:** Help users comprehend codebase architecture, data flow, patterns
2. **Explain:** Provide clear explanations of complex systems and decisions
3. **Analyze:** Identify tradeoffs, alternatives, and improvement opportunities
4. **Discuss:** Engage in interactive, exploratory conversations

### Hard Constraints
- **NEVER** modify files (no edits/writes/patches)
- **ONLY** bash for information gathering and inspection
- **NO** code execution or tests that modify state

### Tool Usage Guidelines

**Preference Hierarchy:**
1. **First:** OpenCode read/glob/grep tools for file exploration
2. **Second:** Bash commands for system inspection (git, version checks, etc.)
3. **Third:** Webfetch for documentation and external resources

**Bash Usage:**
- Run only inspection commands (git status/diff/log, rg/grep, ls/tree, cat/head/tail)
- Explain reasoning when requesting approval for `ask` commands
- Never attempt file modifications or state changes

**Web Usage:**
- Retrieve documentation pages when helpful for informed discussion
- Prefer official docs and primary sources
- Use to stay current on best practices and frameworks

### Response Guidelines

**Citation Format:**
```
src/app.ts:42
```
- Always include file paths with line numbers for code references
- Makes it easy for users to navigate to exact locations

**Interaction Style:**
- Ask targeted questions rather than guessing when uncertain
- Provide suggested changes as plain-text proposals or diffs
- Engage in back-and-forth discussion to clarify requirements
- Explore alternatives and explain tradeoffs

**Output Format:**
- Code snippets for proposed changes (not applied automatically)
- Architectural diagrams or explanations when helpful
- Comparative analysis of different approaches
- Clear reasoning for recommendations

---

## 📁 File Structure

### Before Implementation
```
/home/rc/Repos/configs-ril/opencode/
├── .gitignore
├── bun.lock
├── node_modules/
├── opencode.jsonc
└── package.json
```

### After Implementation
```
/home/rc/Repos/configs-ril/opencode/
├── .gitignore
├── .opencode/
│   └── plans/
│       └── discuss-agent-implementation.md    # This document
├── bun.lock
├── node_modules/
├── opencode.jsonc                             # Modified
├── package.json
└── agents/                                    # New
    └── discuss.jsonc                          # New
```

---

## 🔧 Implementation Steps

### Phase 1: Directory Structure Setup

#### Step 1.1: Create Agents Directory
```bash
mkdir -p /home/rc/Repos/configs-ril/opencode/agents
```

**Verification:**
```bash
ls -la /home/rc/Repos/configs-ril/opencode/agents
```

---

### Phase 2: Create Agent Configuration File

#### Step 2.1: Create discuss.jsonc

**Location:** `/home/rc/Repos/configs-ril/opencode/agents/discuss.jsonc`

**Content Structure:**
```jsonc
{
  "discuss": {
    // ---------------------------------------------------------------------------
    // Agent Metadata
    // ---------------------------------------------------------------------------
    "mode": "primary",
    "description": "Read-only expert for understanding and discussing the project. Can explore files and run read-only shell commands with approval, and fetch web pages for documentation.",
    "temperature": 0.3,
    "steps": 15,
    "color": "blue",

    // ---------------------------------------------------------------------------
    // Tool Configuration
    // ---------------------------------------------------------------------------
    "tools": {
      "edit": false,
      "write": false,
      "patch": false,
      "multiedit": false,
      "bash": true
    },

    // ---------------------------------------------------------------------------
    // Permission Configuration
    // ---------------------------------------------------------------------------
    "permission": {
      "edit": "deny",
      "bash": {
        // === DEFAULT ===
        "": "ask",

        // === DESTRUCTIVE OPERATIONS ===
        "rm ": "deny",
        "mv ": "deny",
        // ... (full list from security architecture)

        // === ALLOW READ-ONLY ===
        "pwd": "allow",
        "ls ": "allow",
        // ... (full list from security architecture)
      },
      "webfetch": "allow"
    },

    // ---------------------------------------------------------------------------
    // Agent Prompt
    // ---------------------------------------------------------------------------
    "prompt": "You are Discuss: a read-only, senior engineer and architect.\n\n..."
  }
}
```

**Requirements:**
- Complete bash permission mappings (all categories from security architecture)
- Full agent prompt text (from prompt design section)
- Comprehensive inline comments explaining each section
- Proper JSONC formatting (2-space indentation)

#### Step 2.2: Add Vim Modeline
Add at end of file:
```jsonc
// vim:fileencoding=utf-8:shiftwidth=2:tabstop=2:expandtab
```

---

### Phase 3: Integrate Agent into Main Config

#### Step 3.1: Update opencode.jsonc

**Modification:** Add to `agent` section

**Before:**
```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  // ... existing config ...
  "agent": {
    // "code-reviewer": {
    //   "description": "Reviews code for best practices, correctness, and potential issues.",
    //   "model": "anthropic/claude-sonnet-4-5"
    // }
  }
}
```

**After:**
```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  // ... existing config ...

  // ---------------------------------------------------------------------------
  // 5) Agents
  // ---------------------------------------------------------------------------
  "default_agent": "build",

  "agent": {
    // ---------------------------------------------------------------------------
    // Custom Agents
    // ---------------------------------------------------------------------------
    
    // Discuss Agent: Read-only expert for project exploration and discussion
    // - Can explore files and run safe inspection commands
    // - Cannot modify any files (enforced at tool and permission levels)
    // - Has web access for documentation lookup
    // - Switch to this agent using Tab key
    ..."{file:./agents/discuss.jsonc}"

    // "code-reviewer": {
    //   "description": "Reviews code for best practices, correctness, and potential issues.",
    //   "model": "anthropic/claude-sonnet-4-5"
    // }
  }
}
```

**Note:** The `...` spread operator imports the agent configuration from the external file.

---

### Phase 4: Validation

#### Step 4.1: Syntax Validation

**JSONC Validation:**
```bash
# Using Node.js (if available)
node -e "const fs = require('fs'); JSON.parse(fs.readFileSync('agents/discuss.jsonc', 'utf8').replace(/\/\*[\s\S]*?\*\/|\/\/.*/g, ''))"

# Alternative: Check with OpenCode itself
opencode --version  # Verify OpenCode is installed
```

#### Step 4.2: Visual Inspection
- Verify proper indentation (2 spaces)
- Check all comments are properly formatted
- Ensure no trailing commas in final array/object elements
- Confirm vim modeline is present

---

## ✅ Validation Checklist

### Pre-Implementation
- [x] Plan document created in `.opencode/plans/`
- [x] All decisions documented (no README, inherit model, blue color, etc.)
- [x] Security architecture reviewed and approved
- [x] Bash permission lists comprehensive

### During Implementation
- [ ] `agents/` directory created successfully
- [ ] `discuss.jsonc` created with all required content
- [ ] All bash permissions from security architecture included
- [ ] Full agent prompt included from prompt design section
- [ ] Vim modeline added to `discuss.jsonc`
- [ ] `opencode.jsonc` updated with file reference
- [ ] Documentation comments added to `opencode.jsonc`
- [ ] JSONC syntax validated

### Post-Implementation Testing
- [ ] OpenCode loads configuration without errors
- [ ] "Discuss" agent appears in agent list (Tab key)
- [ ] Agent shows blue color in UI
- [ ] File edit operations are blocked
- [ ] Bash read commands work (e.g., `ls`, `git status`)
- [ ] Bash write commands blocked (e.g., `rm`, `git commit`)
- [ ] Commands requiring approval prompt user (e.g., `find`)
- [ ] Webfetch works for documentation
- [ ] Agent responds in conversational tone
- [ ] Agent provides code references with line numbers

---

## 🧪 Testing Strategy

### Functional Testing

**Test Case 1: Write Operations Blocked**
```
User: "Can you add a comment to this file?"
Expected: Agent explains it cannot modify files, offers to suggest the comment
```

**Test Case 2: Read Operations Work**
```
User: "Show me the git status"
Expected: Agent runs `git status` without approval prompt
```

**Test Case 3: Approval Required**
```
User: "Find all TypeScript files"
Expected: Agent requests approval for `find` command
```

**Test Case 4: Web Documentation**
```
User: "Look up the latest React best practices"
Expected: Agent uses webfetch to retrieve documentation
```

**Test Case 5: Interactive Discussion**
```
User: "How does authentication work in this project?"
Expected: Agent explores relevant files, asks clarifying questions, provides analysis
```

### Security Testing

**Test Case 6: Echo Redirection Blocked**
```
User: "Run echo 'test' > output.txt"
Expected: Agent refuses, explains it cannot modify files
```

**Test Case 7: Git Commit Blocked**
```
User: "Commit these changes"
Expected: Agent refuses, explains it cannot run git write operations
```

**Test Case 8: Package Installation Blocked**
```
User: "Install the axios package"
Expected: Agent refuses, explains it cannot install packages
```

---

## 🚨 Known Limitations

### Technical Limitations
1. **Shell Redirection Operators:** Cannot block `>` and `>>` at permission level (relies on tool-level blocks)
2. **Complex Pipes:** Some piped commands may bypass restrictions (default `ask` provides safeguard)
3. **Find Command Risk:** Allowed with approval due to usefulness, but has `-exec`/`-delete` capabilities

### Operational Limitations
1. **No Test Execution:** Cannot run tests that modify state (even temporarily)
2. **No Build Operations:** Cannot run build commands (only `make -n` dry-run)
3. **Read-Only Git:** Can view history but cannot create branches or tags

### Workarounds
- **For Changes:** Agent provides plain-text proposals or diffs
- **For Testing:** User runs tests manually, agent analyzes results
- **For Builds:** User runs build, agent analyzes output

---

## 📊 Risk Assessment

| Risk | Severity | Mitigation | Status |
|------|----------|------------|--------|
| Accidental file modification | **HIGH** | 3-layer protection (tool/permission/bash) | ✅ Mitigated |
| Bash command bypass | **MEDIUM** | Default `ask`, explicit denies | ✅ Mitigated |
| Package installation | **MEDIUM** | All install commands denied | ✅ Mitigated |
| Git repository corruption | **MEDIUM** | All write operations denied | ✅ Mitigated |
| Script execution | **MEDIUM** | All `-c`/`-e` execution denied | ✅ Mitigated |
| Find command abuse | **LOW** | Set to `ask` (approval required) | ✅ Mitigated |
| Shell redirection | **LOW** | Tool-level blocks, echo denied | ⚠️ Accepted |

**Overall Risk Level:** **LOW** - Multiple layers of protection with minimal accepted risks

---

## 🔄 Future Enhancements

### Potential Improvements
1. **Model Specialization:** Consider using a faster model for quick queries
2. **Additional Language Support:** Add more language-specific inspection commands
3. **Custom Subagents:** Create specialized read-only subagents (e.g., "analyze-security")
4. **Enhanced Permissions:** Add more granular git command permissions
5. **Metrics/Logging:** Track which commands are most commonly used/blocked

### Versioning Strategy
- **v1.0:** Initial implementation (this plan)
- **v1.1:** Add user feedback-based improvements
- **v2.0:** Consider model specialization or advanced features

---

## 📚 References

### OpenCode Documentation
- [Agents Configuration](https://opencode.ai/docs/agents/)
- [Permissions System](https://opencode.ai/docs/permissions/)
- [Tools Configuration](https://opencode.ai/docs/tools/)
- [Config File Format](https://opencode.ai/docs/config/)

### Configuration Files
- Main config: `/home/rc/Repos/configs-ril/opencode/opencode.jsonc`
- Agent config: `/home/rc/Repos/configs-ril/opencode/agents/discuss.jsonc`
- Repository guidelines: `/home/rc/Repos/configs-ril/AGENTS.md`

---

## 📝 Decision Log

| Decision | Rationale | Date |
|----------|-----------|------|
| No README in agents/ | Follow repository guideline: no unnecessary markdown | 2026-02-16 |
| Inherit global model | Flexibility to change model globally | 2026-02-16 |
| Blue color for UI | Visual distinction from build/plan agents | 2026-02-16 |
| Temperature 0.3 | Balance analytical and conversational | 2026-02-16 |
| 15 steps max | Allow deeper exploration than default | 2026-02-16 |
| Find requires approval | Useful but potentially dangerous | 2026-02-16 |
| Echo denied | Prevent redirection attacks | 2026-02-16 |
| Separate config file | Maintainability and version control | 2026-02-16 |

---

## 👥 Stakeholders

- **Primary User:** System administrator managing dotfiles repository
- **Use Cases:** 
  - Understanding configuration patterns
  - Exploring application settings
  - Discussing configuration tradeoffs
  - Getting documentation references

---

## 📅 Timeline

**Estimated Implementation Time:** 30-45 minutes

1. **Phase 1 - Directory Setup:** 2 minutes
2. **Phase 2 - Agent Config Creation:** 20-30 minutes (most time spent on comprehensive bash permissions)
3. **Phase 3 - Main Config Integration:** 5 minutes
4. **Phase 4 - Validation:** 5-10 minutes
5. **Testing:** 10-15 minutes (manual functional testing)

**Total:** ~45 minutes for complete implementation and testing

---

## ✨ Summary

This plan provides a complete blueprint for implementing a safe, read-only "Discuss" agent that:

- ✅ Cannot modify files (enforced at 3 levels)
- ✅ Has comprehensive inspection capabilities
- ✅ Can access web documentation
- ✅ Engages in interactive discussions
- ✅ Follows repository conventions
- ✅ Is maintainable and well-documented

**Status:** Ready for implementation ✅

---

*End of Implementation Plan*

<!--- vim:fileencoding=utf-8:shiftwidth=4:tabstop=4 --->
