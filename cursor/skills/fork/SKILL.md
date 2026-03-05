---
name: fork
description: Fork the current chat session into a new resumable session
---

# Fork

Clone the current chat session so it can be resumed independently as a branched conversation.

## Instructions

Fork the most recent session:

```bash
python3 $DOTFILES/cursor/skills/fork/fork.py
```

Fork with a description:

```bash
python3 $DOTFILES/cursor/skills/fork/fork.py --name "try jwt instead"
```

If the user provides a description after `/fork`, pass it as `--name`.

Report the new session ID and remind the user they can resume with:
- `cursor agent --resume <id>`
- `cursor agent ls`
