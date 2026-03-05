#!/usr/bin/env python3
"""Fork (clone) a Cursor agent chat session so it can be resumed independently.

Cursor stores chat sessions as SQLite databases at:
    ~/.cursor/chats/<workspace-hash>/<chat-uuid>/store.db

This script copies a session directory, assigns a new UUID, and updates
the metadata so `cursor agent --resume <new-uuid>` picks it up.

Usage:
    python3 fork.py                        # clone most recent session
    python3 fork.py --name "try jwt"       # clone with a custom fork label
    python3 fork.py --session <uuid>       # clone a specific session
    python3 fork.py --list                 # list sessions in current workspace
"""

import argparse
import json
import re
import shutil
import sqlite3
import sys
import uuid
from pathlib import Path

CURSOR_CHATS = Path.home() / ".cursor" / "chats"
CURSOR_PROJECTS = Path.home() / ".cursor" / "projects"


def _workspace_slug() -> str:
    return str(Path.cwd()).replace("/", "-").lstrip("-")


def workspace_hash_dir() -> Path | None:
    """Find the chat storage directory for the current workspace.

    Cross-references agent-transcript UUIDs (which live under a
    deterministic slug) with chat UUIDs inside ~/.cursor/chats/ to
    reliably map the current workspace to its opaque hash directory.
    Falls back to most-recently-modified if no match is found.
    """
    if not CURSOR_CHATS.exists():
        return None

    slug = _workspace_slug()
    transcripts_dir = CURSOR_PROJECTS / slug / "agent-transcripts"
    if transcripts_dir.exists():
        transcript_ids = {
            p.stem for p in transcripts_dir.iterdir() if p.suffix in (".jsonl", ".txt")
        }
        if transcript_ids:
            for ws_dir in CURSOR_CHATS.iterdir():
                if not ws_dir.is_dir():
                    continue
                chat_ids = {d.name for d in ws_dir.iterdir() if d.is_dir()}
                if transcript_ids & chat_ids:
                    return ws_dir

    candidates = sorted(
        (d for d in CURSOR_CHATS.iterdir() if d.is_dir()),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    return candidates[0] if candidates else None


def read_meta(db_path: Path) -> dict:
    conn = sqlite3.connect(str(db_path))
    row = conn.execute("SELECT value FROM meta WHERE key = '0'").fetchone()
    conn.close()
    if not row:
        return {}
    return json.loads(bytes.fromhex(row[0]).decode())


def write_meta(db_path: Path, meta: dict):
    encoded = json.dumps(meta).encode().hex()
    conn = sqlite3.connect(str(db_path))
    conn.execute("UPDATE meta SET value = ? WHERE key = '0'", [encoded])
    conn.commit()
    conn.close()


def list_sessions(ws_dir: Path):
    for session_dir in sorted(ws_dir.iterdir(), key=_session_mtime, reverse=True):
        db = session_dir / "store.db"
        if not db.exists():
            continue
        meta = read_meta(db)
        name = meta.get("name", "?")
        agent_id = meta.get("agentId", session_dir.name)
        print(f"  {agent_id}  {name}")


def _session_mtime(session_dir: Path) -> float:
    """Most recent modification time across store.db and its WAL file.

    In WAL mode, active writes go to store.db-wal while store.db stays
    stale. Using the max of both gives the true "last active" time.
    """
    db = session_dir / "store.db"
    wal = session_dir / "store.db-wal"
    t = db.stat().st_mtime if db.exists() else 0
    if wal.exists():
        t = max(t, wal.stat().st_mtime)
    return t


def find_latest_session(ws_dir: Path) -> Path | None:
    candidates = sorted(
        (d for d in ws_dir.iterdir() if d.is_dir() and (d / "store.db").exists()),
        key=_session_mtime,
        reverse=True,
    )
    return candidates[0] if candidates else None


def fork_session(ws_dir: Path, source_uuid: str, name: str | None) -> str:
    source_dir = ws_dir / source_uuid
    if not source_dir.exists():
        print(f"Session not found: {source_uuid}", file=sys.stderr)
        sys.exit(1)

    new_uuid = str(uuid.uuid4())
    dest_dir = ws_dir / new_uuid
    shutil.copytree(source_dir, dest_dir)

    db_path = dest_dir / "store.db"
    meta = read_meta(db_path)
    original_name = meta.get("name", "Unnamed")
    base_name = re.sub(r"\s*\(fork(?::\s*[^)]*)?\)\s*$", "", original_name) or original_name
    meta["agentId"] = new_uuid
    meta["name"] = f"{base_name} (fork: {name})" if name else f"{base_name} (fork)"
    write_meta(db_path, meta)

    print(f"Forked: {original_name}")
    print(f"    as: {meta['name']}")
    print(f"    id: {new_uuid}")
    print()
    print(f"Resume with:")
    print(f"    cursor agent --resume {new_uuid}")
    return new_uuid


def main():
    parser = argparse.ArgumentParser(description="Fork a Cursor agent chat session.")
    parser.add_argument("-n", "--name", help="Label for the fork")
    parser.add_argument("-s", "--session", help="Source session UUID (default: most recent)")
    parser.add_argument("-l", "--list", action="store_true", help="List sessions and exit")
    args = parser.parse_args()

    ws_dir = workspace_hash_dir()
    if not ws_dir:
        print("No Cursor chat storage found at ~/.cursor/chats/", file=sys.stderr)
        sys.exit(1)

    if args.list:
        list_sessions(ws_dir)
        return

    if args.session:
        source_uuid = args.session
    else:
        latest = find_latest_session(ws_dir)
        if not latest:
            print("No sessions found in workspace.", file=sys.stderr)
            sys.exit(1)
        source_uuid = latest.name

    fork_session(ws_dir, source_uuid, args.name)


if __name__ == "__main__":
    main()
