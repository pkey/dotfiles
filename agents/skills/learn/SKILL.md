---
name: learn
description: Capture learnings from mistakes and update agent context to prevent future issues
disable-model-invocation: false
---

# Learn

Extract learnings from agent mistakes or misunderstandings and propose updates to the appropriate context file. This skill can be invoked by the user or automatically by the agent when it recognizes an error.

## Input

The issue can come from:
- The current conversation context (what went wrong)
- Additional context provided by the user when invoking the skill

## Process

1. **Identify the issue** - What did the agent get wrong?
   - Scan the entire conversation for ALL learnings, not just the most recent issue
   - Present multiple learnings in a single response if applicable
2. **Determine target location** - Select the appropriate file based on scope
3. **Check existing context** - Read the target file to verify similar guidance doesn't already exist
4. **Formulate the learning** - Convert the mistake into a clear, actionable guideline
5. **Present plan** - Show the proposed change for user verification
6. **Apply on confirmation** - Make the edit after user approves

## Target Selection

Evaluate the scope of the learning to determine where it belongs:

| Scope | Target File | When to Use |
|-------|-------------|-------------|
| Skill-specific | `$DOTFILES/agents/skills/<skill>/SKILL.md` | Issue relates to a specific skill's behavior |
| Project-specific | `./AGENTS.md` (local to current project) | Convention or pattern specific to this codebase |
| Universal | `$DOTFILES/agents/AGENTS.md` | General preference that applies everywhere |
| Permissions | `$DOTFILES/agents/permissions.json` | Commands that should be in allow/deny/ask lists |

### Decision Flow

```
1. Is this about a specific skill? → Update that skill's SKILL.md
2. Is this about command permissions? → Update permissions.json
3. Is this specific to the current project? → Update local AGENTS.md
4. Otherwise → Update global AGENTS.md
```

## Output Format

Present the proposed change in this format:

```
## Issue Identified

[Brief description of what went wrong]

## Proposed Learning

[The guideline/rule to add, written clearly and concisely]

## Target

- **File:** [path to file]
- **Reason:** [why this location was chosen]

## Proposed Change

[Show the exact addition or modification as a diff or code block]
```

Wait for user confirmation before applying the change.

## Guidelines for Writing Learnings

- Be specific and actionable
- Use imperative mood ("Do X" not "Should do X")
- Keep rules concise - one clear instruction per learning
- Avoid redundancy with existing rules
- For permissions.json, use the exact glob/command pattern format

## Examples

### Example 1: Universal Preference

Issue: Agent used `grep` instead of `rg`
```
## Issue Identified
Used grep instead of ripgrep (rg) for searching.

## Proposed Learning
- tools: Always use rg instead of grep

## Target
- **File:** $DOTFILES/agents/AGENTS.md
- **Reason:** This is a universal tool preference

## Proposed Change
Add under tools section:
- Always use rg instead of grep
```

### Example 2: Permission Update

Issue: Agent asked for permission to run `cargo build` every time
```
## Issue Identified
Agent repeatedly asked for permission to run cargo build.

## Proposed Learning
Add cargo commands to allow list.

## Target
- **File:** $DOTFILES/agents/permissions.json
- **Reason:** This is about command permissions

## Proposed Change
Add to "allow" array:
"Bash(cargo:*)"
```

### Example 3: Project-Specific

Issue: Agent created components in wrong directory for this project
```
## Issue Identified
Created React components in src/ instead of src/components/.

## Proposed Learning
- All React components go in src/components/

## Target
- **File:** ./AGENTS.md (local)
- **Reason:** This is specific to this project's structure

## Proposed Change
Add under Architecture section:
- React components: Always place in src/components/
```
