---
name: optimize
description: Analyze the current conversation to identify new skills, scripts, aliases, or rules that would speed up similar work next time
disable-model-invocation: true
---

# Optimize

Review the entire current conversation to find friction, repetition, and missing automation. Propose concrete artifacts that would make the next similar session faster.

## Analysis

Scan the full conversation for:

1. **Repetitive manual steps** — commands or sequences run more than once that could be an alias or script
2. **Multi-step workflows** — coordinated actions that could become a skill
3. **Wrong approaches** — time wasted because of missing context or rules the agent didn't know
4. **Repeated lookups** — information the agent had to search for that could be pre-documented
5. **Missing tools** — cases where a CLI tool or package would have helped
6. **Boilerplate** — patterns typed out manually that could be scaffolded

## Output

For each finding, propose one of these artifact types:

| Artifact | Location | When |
|----------|----------|------|
| Skill | `$DOTFILES/agents/skills/<name>/SKILL.md` | Multi-step workflow the agent should know how to do |
| Alias | `$DOTFILES/aliases.sh` | One-liner command shortcut |
| Shell function | `$DOTFILES/tools/<name>.sh` | Reusable function (auto-sourced by .zshrc) |
| Bin script | `$DOTFILES/bin/<name>` | Standalone executable |
| Agent rule | `$DOTFILES/agents/AGENTS.md` or project `AGENTS.md` | Context/preference the agent was missing |
| Package | `$DOTFILES/packages.yaml` | CLI tool that should be installed |

## Format

Present each proposal as:

```
### <N>. <artifact type>: <name>

**Problem:** What went wrong or was slow in this conversation.

**Proposal:** What to create and what it does.

**Location:** Target file path.

**Implementation:**

<code block with the full artifact content>
```

After listing all proposals, ask:
- Which proposals to apply (all, specific numbers, or none)
- Whether any need adjustment before applying

## Guidelines

- Prefer the simplest artifact type that solves the problem (alias > function > script > skill)
- Don't propose artifacts that duplicate existing ones — check `$DOTFILES/aliases.sh`, `$DOTFILES/tools/`, and `$DOTFILES/agents/skills/` first
- Keep proposals actionable and concrete — include full implementation, not just ideas
- If nothing worth optimizing is found, say so
