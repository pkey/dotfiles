---
name: cost
description: Estimate the cost of LLM interactions from recent conversations.
---

# Cost

## Instructions

Run the script — it auto-detects the latest transcript for the current project:

```bash
python3 $DOTFILES/agents/skills/cost/estimate-cost.py
```

Other modes:

```bash
python3 $DOTFILES/agents/skills/cost/estimate-cost.py --model opus-4.6
python3 $DOTFILES/agents/skills/cost/estimate-cost.py --last 5
python3 $DOTFILES/agents/skills/cost/estimate-cost.py --day            # today, all projects
python3 $DOTFILES/agents/skills/cost/estimate-cost.py --day yesterday
python3 $DOTFILES/agents/skills/cost/estimate-cost.py --day 2026-03-01
```

Report the output to the user.
