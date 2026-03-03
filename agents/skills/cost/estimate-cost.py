#!/usr/bin/env python3
"""Estimate LLM API cost from Cursor/Claude Code conversation transcripts (.jsonl).

Transcripts only capture user/assistant text — not system prompts, tool
definitions, tool call JSON, tool results (file reads, web fetches, shell
output), or thinking/reasoning tokens.  This script applies empirical
overhead multipliers to bridge the gap.

Usage:
    # Auto-detect latest transcript for current project
    python3 estimate-cost.py

    # Specific transcript
    python3 estimate-cost.py /path/to/transcript.jsonl

    # Override model
    python3 estimate-cost.py --model opus-4.6

    # Show last 3 conversations
    python3 estimate-cost.py --last 3

    # Daily spending (today, yesterday, or specific date)
    python3 estimate-cost.py --day
    python3 estimate-cost.py --day yesterday
    python3 estimate-cost.py --day 2026-03-01

    # List available projects
    python3 estimate-cost.py --list-projects
"""

import argparse
import json
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

# ── Pricing per 1M tokens (USD) ─────────────────────────────────────────────
# Sources:
#   Anthropic: https://www.anthropic.com/pricing
#   OpenAI:    https://openai.com/api/pricing/
# Last verified: 2026-03-03

PRICING = {
    # Anthropic
    "opus-4.6":     {"input": 5.00,  "cached": 0.50,  "output": 25.00, "provider": "anthropic"},
    "sonnet-4.6":   {"input": 3.00,  "cached": 0.30,  "output": 15.00, "provider": "anthropic"},
    "haiku-4.5":    {"input": 1.00,  "cached": 0.10,  "output": 5.00,  "provider": "anthropic"},
    # OpenAI flagship
    "gpt-5.2":      {"input": 1.75,  "cached": 0.175, "output": 14.00, "provider": "openai"},
    "gpt-5.2-pro":  {"input": 21.00, "cached": 0.00,  "output": 168.0, "provider": "openai"},
    "gpt-5-mini":   {"input": 0.25,  "cached": 0.025, "output": 2.00,  "provider": "openai"},
    # OpenAI GPT-4.1 family
    "gpt-4.1":      {"input": 2.00,  "cached": 0.50,  "output": 8.00,  "provider": "openai"},
    "gpt-4.1-mini": {"input": 0.40,  "cached": 0.10,  "output": 1.60,  "provider": "openai"},
    "gpt-4.1-nano": {"input": 0.10,  "cached": 0.025, "output": 0.40,  "provider": "openai"},
    # OpenAI reasoning
    "o3":           {"input": 2.00,  "cached": 0.50,  "output": 8.00,  "provider": "openai"},
    "o4-mini":      {"input": 1.10,  "cached": 0.275, "output": 4.40,  "provider": "openai"},
}

# ── Overhead multipliers ────────────────────────────────────────────────────
# Transcripts miss system prompts, tool calls/results, and thinking tokens.
# These multipliers are empirical estimates from comparing transcript sizes
# to actual API usage in agentic coding sessions.

SYSTEM_PROMPT_TOKENS_PER_TURN = 5000   # Cursor/Claude Code system prompt + rules + context
TOOL_RESULT_MULTIPLIER = 4.0           # tool results ≈ 4x visible assistant text in agentic sessions
THINKING_MULTIPLIER = 3.0              # reasoning/thinking tokens ≈ 3x visible output (reasoning models)
CACHE_HIT_RATIO = 0.5                  # ~50% of input tokens are prompt-cached

CHARS_PER_TOKEN = 4

REASONING_MODELS = {"opus-4.6", "o3", "o4-mini", "gpt-5.2", "gpt-5.2-pro", "gpt-5-mini"}

# ── Conversation history locations ──────────────────────────────────────────

CURSOR_PROJECTS = Path.home() / ".cursor" / "projects"
CLAUDE_CODE_PROJECTS = Path.home() / ".claude" / "projects"
CODEX_SESSIONS = Path.home() / ".codex" / "sessions"


def tokens(chars: int) -> int:
    return max(1, chars // CHARS_PER_TOKEN)


def find_project_dir(base: Path) -> Path | None:
    """Find the project transcript dir matching cwd."""
    if not base.exists():
        return None
    cwd = Path.cwd()
    slug = str(cwd).replace("/", "-").lstrip("-")
    candidate = base / slug / "agent-transcripts"
    if candidate.exists():
        return candidate
    for d in sorted(base.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True):
        transcripts = d / "agent-transcripts"
        if transcripts.exists() and slug in d.name:
            return transcripts
    return None


def find_transcripts(n: int = 1) -> list[Path]:
    """Find the N most recent transcript files across Cursor and Claude Code."""
    dirs = []
    for base in [CURSOR_PROJECTS, CLAUDE_CODE_PROJECTS]:
        d = find_project_dir(base)
        if d:
            dirs.append(d)
    if not dirs:
        for base in [CURSOR_PROJECTS, CLAUDE_CODE_PROJECTS]:
            if base.exists():
                for project in base.iterdir():
                    t = project / "agent-transcripts"
                    if t.exists():
                        dirs.append(t)

    files = []
    for d in dirs:
        files.extend(d.glob("*.jsonl"))
    files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return files[:n]


def all_transcript_dirs() -> list[tuple[str, Path]]:
    """Return (label, dir) for every project with transcripts."""
    results = []
    for label, base in [("Cursor", CURSOR_PROJECTS), ("Claude Code", CLAUDE_CODE_PROJECTS)]:
        if not base.exists():
            continue
        for d in base.iterdir():
            t = d / "agent-transcripts"
            if t.exists():
                results.append((label, t))
    return results


def find_transcripts_by_date(target: date) -> list[tuple[str, Path]]:
    """Return (project_label, file) for all transcripts modified on target date."""
    results = []
    for label, tdir in all_transcript_dirs():
        for f in tdir.glob("*.jsonl"):
            mtime = datetime.fromtimestamp(f.stat().st_mtime).date()
            if mtime == target:
                project = tdir.parent.name
                results.append((f"{label}/{project}", f))
    results.sort(key=lambda x: x[1].stat().st_mtime)
    return results


def list_projects():
    for label, base in [("Cursor", CURSOR_PROJECTS), ("Claude Code", CLAUDE_CODE_PROJECTS)]:
        if not base.exists():
            continue
        for d in sorted(base.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True):
            t = d / "agent-transcripts"
            if t.exists():
                count = len(list(t.glob("*.jsonl")))
                if count:
                    print(f"  {label}: {d.name} ({count} conversations)")


def parse_transcript(path: Path) -> dict:
    user_chars = 0
    assistant_chars = 0
    turns = []

    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            role = obj.get("role", "unknown")
            content = obj.get("message", {}).get("content", [])
            chars = sum(len(c.get("text", "")) for c in content if isinstance(c, dict))
            turns.append({"role": role, "chars": chars})
            if role == "user":
                user_chars += chars
            elif role == "assistant":
                assistant_chars += chars

    user_turns = sum(1 for t in turns if t["role"] == "user")
    assistant_turns = sum(1 for t in turns if t["role"] == "assistant")

    cumulative_input_chars = 0
    running = 0
    for t in turns:
        running += t["chars"]
        if t["role"] == "assistant":
            cumulative_input_chars += running

    return {
        "user_chars": user_chars,
        "assistant_chars": assistant_chars,
        "user_turns": user_turns,
        "assistant_turns": assistant_turns,
        "cumulative_input_chars": cumulative_input_chars,
        "turns": turns,
    }


def estimate(data: dict, model: str) -> dict:
    prices = PRICING[model]
    is_reasoning = model in REASONING_MODELS
    n_assistant = data["assistant_turns"]

    # Visible tokens from transcript
    visible_input_tokens = tokens(data["cumulative_input_chars"])
    visible_output_tokens = tokens(data["assistant_chars"])

    # Overhead: system prompt re-sent each assistant turn
    system_overhead = SYSTEM_PROMPT_TOKENS_PER_TURN * n_assistant

    # Overhead: tool results not in transcript (scales with assistant output)
    tool_overhead = int(visible_output_tokens * TOOL_RESULT_MULTIPLIER)

    total_input_tokens = visible_input_tokens + system_overhead + tool_overhead

    # Split input into cached vs fresh
    cached_tokens = int(total_input_tokens * CACHE_HIT_RATIO)
    fresh_tokens = total_input_tokens - cached_tokens

    # Output: visible + thinking overhead for reasoning models
    thinking_tokens = int(visible_output_tokens * THINKING_MULTIPLIER) if is_reasoning else 0
    total_output_tokens = visible_output_tokens + thinking_tokens

    input_cost = (fresh_tokens / 1_000_000) * prices["input"]
    cached_cost = (cached_tokens / 1_000_000) * prices["cached"]
    output_cost = (total_output_tokens / 1_000_000) * prices["output"]
    total_cost = input_cost + cached_cost + output_cost

    return {
        "visible_input_tokens": visible_input_tokens,
        "system_overhead": system_overhead,
        "tool_overhead": tool_overhead,
        "total_input_tokens": total_input_tokens,
        "fresh_tokens": fresh_tokens,
        "cached_tokens": cached_tokens,
        "visible_output_tokens": visible_output_tokens,
        "thinking_tokens": thinking_tokens,
        "total_output_tokens": total_output_tokens,
        "input_cost": input_cost,
        "cached_cost": cached_cost,
        "output_cost": output_cost,
        "total_cost": total_cost,
    }


DOWNGRADE_MAP = {
    "opus-4.6":     ["sonnet-4.6", "haiku-4.5"],
    "sonnet-4.6":   ["haiku-4.5"],
    "gpt-5.2":      ["gpt-5-mini", "gpt-4.1"],
    "gpt-5.2-pro":  ["gpt-5.2", "gpt-5-mini"],
    "gpt-4.1":      ["gpt-4.1-mini", "gpt-4.1-nano"],
    "gpt-4.1-mini": ["gpt-4.1-nano"],
    "o3":           ["o4-mini", "gpt-5-mini"],
    "o4-mini":      ["gpt-5-mini", "gpt-4.1-mini"],
}


def suggestions(data: dict, est: dict, model: str) -> list[str]:
    tips = []

    alternatives = DOWNGRADE_MAP.get(model, [])
    for alt in alternatives:
        alt_est = estimate(data, alt)
        saving = est["total_cost"] - alt_est["total_cost"]
        if saving > 0.01:
            pct = (saving / est["total_cost"]) * 100
            tips.append(f"Switch to {alt}: ${alt_est['total_cost']:.2f} (save ${saving:.2f}, -{pct:.0f}%)")

    if data["assistant_turns"] > 15:
        tips.append(f"Long conversation ({data['assistant_turns']} assistant turns) — "
                    "context grows each turn. Start a new chat to reset context window costs.")

    if est["thinking_tokens"] > est["visible_output_tokens"] * 2:
        tips.append("Thinking tokens dominate output cost. "
                    "A non-reasoning model (sonnet-4.6, gpt-4.1) avoids this overhead.")

    if est["system_overhead"] > est["visible_input_tokens"]:
        tips.append("System prompt overhead exceeds visible input. "
                    "Fewer turns or shorter AGENTS.md/rules reduce per-turn fixed cost.")

    return tips


def print_estimate(path: Path, data: dict, est: dict, model: str):
    print(f"{path.name}  model={model}  "
          f"turns={data['user_turns']}u/{data['assistant_turns']}a")
    print(f"  input:  {est['total_input_tokens']:>8,} tok  "
          f"(visible={est['visible_input_tokens']:,} + sys={est['system_overhead']:,} + tools={est['tool_overhead']:,})  "
          f"fresh=${est['input_cost']:.3f}  cached=${est['cached_cost']:.3f}")
    print(f"  output: {est['total_output_tokens']:>8,} tok  "
          f"(visible={est['visible_output_tokens']:,}"
          + (f" + thinking={est['thinking_tokens']:,}" if est['thinking_tokens'] else "")
          + f")  ${est['output_cost']:.3f}")
    print(f"  total:  ${est['total_cost']:.2f}")

    tips = suggestions(data, est, model)
    if tips:
        print("  suggestions:")
        for tip in tips:
            print(f"    - {tip}")


def main():
    parser = argparse.ArgumentParser(
        description="Estimate LLM API cost from conversation transcripts.")
    parser.add_argument("transcript", nargs="?", type=Path,
                        help="Path to .jsonl transcript (auto-detects latest if omitted)")
    parser.add_argument("-m", "--model", default="sonnet-4.6", choices=list(PRICING.keys()))
    parser.add_argument("-n", "--last", type=int, default=1,
                        help="Estimate last N conversations (default: 1)")
    parser.add_argument("--day", nargs="?", const="today", default=None,
                        help="Daily summary across all projects. "
                             "Accepts: today, yesterday, YYYY-MM-DD (default: today)")
    parser.add_argument("--list-projects", action="store_true",
                        help="List discovered projects and exit")
    parser.add_argument("--json", action="store_true", help="Output JSON")
    args = parser.parse_args()

    if args.list_projects:
        list_projects()
        return

    if args.day is not None:
        run_daily(args)
        return

    if args.transcript:
        files = [args.transcript]
    else:
        files = find_transcripts(args.last)

    if not files:
        print("No transcripts found. Use --list-projects or pass a path.", file=sys.stderr)
        sys.exit(1)

    grand_total = 0.0
    for f in files:
        if not f.exists():
            print(f"Not found: {f}", file=sys.stderr)
            continue
        data = parse_transcript(f)
        est = estimate(data, args.model)
        grand_total += est["total_cost"]
        if args.json:
            print(json.dumps({"file": str(f), "model": args.model, **data, **est}, default=str))
        else:
            print_estimate(f, data, est, args.model)

    if len(files) > 1 and not args.json:
        print(f"\n  sum:    ${grand_total:.2f}  ({len(files)} conversations)")


def parse_day(value: str) -> date:
    if value == "today":
        return date.today()
    if value == "yesterday":
        return date.today() - timedelta(days=1)
    try:
        return date.fromisoformat(value)
    except ValueError:
        print(f"Invalid date: {value}  (use today, yesterday, or YYYY-MM-DD)", file=sys.stderr)
        sys.exit(1)


def run_daily(args):
    target = parse_day(args.day)
    matches = find_transcripts_by_date(target)

    if not matches:
        print(f"No conversations found for {target}")
        return

    grand_total = 0.0
    by_project: dict[str, float] = {}

    print(f"Daily spending: {target}  model={args.model}")
    print()

    for project, f in matches:
        data = parse_transcript(f)
        est = estimate(data, args.model)
        grand_total += est["total_cost"]
        by_project[project] = by_project.get(project, 0.0) + est["total_cost"]

        if args.json:
            print(json.dumps({"file": str(f), "project": project,
                              "model": args.model, **data, **est}, default=str))
        else:
            mtime = datetime.fromtimestamp(f.stat().st_mtime).strftime("%H:%M")
            print(f"  {mtime}  ${est['total_cost']:.2f}  "
                  f"{data['user_turns']}u/{data['assistant_turns']}a  "
                  f"{project}")

    if not args.json:
        print()
        if len(by_project) > 1:
            print("  by project:")
            for proj, cost in sorted(by_project.items(), key=lambda x: -x[1]):
                print(f"    ${cost:.2f}  {proj}")
            print()
        print(f"  total: ${grand_total:.2f}  ({len(matches)} conversations)")


if __name__ == "__main__":
    main()
