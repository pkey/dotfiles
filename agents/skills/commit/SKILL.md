---
name: commit
description: Commit current changes
disable-model-invocation: false
---

### Commit Guidelines

- Use **conventional commits** (`feat`, `fix`, `refactor`, `chore`, etc.).
- Write the type directly: `feat:`, `fix:` — **do not use parentheses**.
- **One commit = one user-visible outcome / logical deliverable.**
  If several small changes serve the same goal, they may live together.
- The **title states the change**, but the **body explains the WHY**, not the WHAT.
- If the motivation is unclear from the diff, infer the WHY from surrounding context.
  If the WHY still cannot be reasonably inferred, ask the user for clarification.
- In the commit body use `- ` **bullet points**, not prose paragraphs.
- Keep bullet points **short and concise**.

**Never add attribution trailers** such as:
`--trailer`, `Co-authored-by`, `Generated-by`, `Made-with`, `Cursor`, `Claude`, etc.
