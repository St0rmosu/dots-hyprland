#!/usr/bin/env python3
"""
Bidirectional Google Tasks <-> Quickshell Todo Synchronizer.
"""

import sys
import os
import json
import argparse
import subprocess
from pathlib import Path

# Paths
CONFIG_DIR = Path.home() / ".config" / "google-tasks-sync"
CREDS_FILE = CONFIG_DIR / "credentials.json"
TOKEN_FILE = CONFIG_DIR / "token.json"
STATE_FILE = CONFIG_DIR / "state.json"
TODO_FILE = Path.home() / ".local" / "state" / "quickshell" / "user" / "todo.json"

SCOPES = ["https://www.googleapis.com/auth/tasks"]


def get_service(auth_interactive=False):
    """Authenticate and return Google Tasks service."""
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from google.auth.transport.requests import Request
    from googleapiclient.discovery import build

    creds = None

    if not CREDS_FILE.exists():
        print(f"[Google Tasks Sync] Missing credentials file at: {CREDS_FILE}")
        print("Please follow the setup instructions to place credentials.json in this directory.")
        return None

    if TOKEN_FILE.exists():
        try:
            creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
        except Exception as e:
            print(f"[Google Tasks Sync] Error reading token: {e}")
            creds = None

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
                with open(TOKEN_FILE, "w", encoding="utf-8") as token:
                    token.write(creds.to_json())
                TOKEN_FILE.chmod(0o600)
            except Exception as e:
                print(f"[Google Tasks Sync] Failed to refresh token: {e}")
                creds = None

        if not creds:
            if auth_interactive:
                print("[Google Tasks Sync] Starting interactive OAuth login flow...")
                flow = InstalledAppFlow.from_client_secrets_file(str(CREDS_FILE), SCOPES)
                creds = flow.run_local_server(port=0)
                CONFIG_DIR.mkdir(parents=True, exist_ok=True)
                with open(TOKEN_FILE, "w", encoding="utf-8") as token:
                    token.write(creds.to_json())
                TOKEN_FILE.chmod(0o600)
                print(f"[Google Tasks Sync] Authentication successful! Token saved to {TOKEN_FILE}")
            else:
                print(f"[Google Tasks Sync] No valid token found. Run with --auth to log in.")
                return None

    return build("tasks", "v1", credentials=creds)


def load_json(filepath, default):
    if not filepath.exists():
        return default
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[Google Tasks Sync] Warning loading {filepath}: {e}")
        return default


def save_json_atomic(filepath, data):
    filepath.parent.mkdir(parents=True, exist_ok=True)
    temp_file = filepath.with_suffix(".tmp")
    with open(temp_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.flush()
        os.fsync(f.fileno())
    os.replace(temp_file, filepath)


def notify_quickshell():
    """Trigger Quickshell IPC update for todoService."""
    try:
        subprocess.run(
            ["qs", "-c", "ii", "ipc", "call", "todoService", "update"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=3,
        )
    except Exception:
        pass


def sync_tasks(service, dry_run=False):
    # 1. Fetch remote tasks from Google Tasks
    print("[Google Tasks Sync] Fetching tasks from Google Tasks...")
    tasklist_id = "@default"
    items = []
    page_token = None

    while True:
        res = service.tasks().list(
            tasklist=tasklist_id,
            showCompleted=True,
            showHidden=True,
            maxResults=100,
            pageToken=page_token
        ).execute()

        items.extend(res.get("items", []))
        page_token = res.get("nextPageToken")
        if not page_token:
            break

    # Remote tasks indexed by id
    remote_active = {}
    remote_order = {}
    for idx, item in enumerate(items):
        t_id = item["id"]
        remote_order[t_id] = idx
        # Ignore deleted/hidden items
        if item.get("deleted", False) or item.get("hidden", False):
            continue
        remote_active[t_id] = item

    # 2. Load local tasks and state
    local_tasks = load_json(TODO_FILE, [])
    sync_state = load_json(STATE_FILE, {"tasks": {}})
    prev_state = sync_state.get("tasks", {})

    local_with_id = {}
    local_new = []

    for item in local_tasks:
        t_id = item.get("id")
        if t_id:
            local_with_id[t_id] = item
        else:
            local_new.append(item)

    changes_made = False

    # 3. Handle local additions (no id)
    for new_item in local_new:
        title = new_item.get("content", "").strip()
        if not title:
            continue
        done = bool(new_item.get("done", False))
        status = "completed" if done else "needsAction"

        # Check if identical title already exists on remote and isn't mapped
        matched_id = None
        for r_id, r_item in remote_active.items():
            if r_item.get("title", "").strip() == title and r_id not in local_with_id and r_id not in prev_state:
                matched_id = r_id
                break

        if matched_id:
            print(f"[Google Tasks Sync] Matched local task '{title}' with existing remote task {matched_id}")
            new_item["id"] = matched_id
            local_with_id[matched_id] = new_item
            changes_made = True
        else:
            print(f"[Google Tasks Sync] Creating task on Google: '{title}' (done={done})")
            if not dry_run:
                try:
                    created = service.tasks().insert(
                        tasklist=tasklist_id,
                        body={"title": title, "status": status}
                    ).execute()
                    t_id = created["id"]
                    new_item["id"] = t_id
                    local_with_id[t_id] = new_item
                    remote_active[t_id] = created
                    remote_order[t_id] = len(remote_order)
                    changes_made = True
                except Exception as e:
                    print(f"[Google Tasks Sync] Error inserting task '{title}': {e}")

    # 4. Handle local deletions (in prev_state, but missing in local_with_id)
    for prev_id in list(prev_state.keys()):
        if prev_id not in local_with_id:
            if prev_id in remote_active:
                print(f"[Google Tasks Sync] Local deleted task {prev_id} ('{prev_state[prev_id].get('content', '')}'), deleting from Google...")
                if not dry_run:
                    try:
                        service.tasks().delete(tasklist=tasklist_id, task=prev_id).execute()
                        del remote_active[prev_id]
                    except Exception as e:
                        print(f"[Google Tasks Sync] Error deleting remote task {prev_id}: {e}")
            del prev_state[prev_id]

    # 5. Handle updates between local and remote
    for t_id, local_item in list(local_with_id.items()):
        if t_id not in remote_active:
            # Remote was deleted/hidden!
            print(f"[Google Tasks Sync] Remote deleted task {t_id} ('{local_item.get('content', '')}'), removing locally...")
            del local_with_id[t_id]
            if t_id in prev_state:
                del prev_state[t_id]
            changes_made = True
            continue

        r_item = remote_active[t_id]
        r_content = r_item.get("title", "")
        r_done = (r_item.get("status") == "completed")

        l_content = local_item.get("content", "")
        l_done = bool(local_item.get("done", False))

        p_info = prev_state.get(t_id)

        if p_info is None:
            # Newly tracked item
            local_item["content"] = r_content
            local_item["done"] = r_done
        else:
            p_content = p_info.get("content", "")
            p_done = p_info.get("done", False)

            l_changed = (l_content != p_content) or (l_done != p_done)
            r_changed = (r_content != p_content) or (r_done != p_done)

            if l_changed and not r_changed:
                # Local changed, push to Google
                print(f"[Google Tasks Sync] Local update on {t_id}: '{l_content}' (done={l_done}) -> pushing to Google...")
                if not dry_run:
                    try:
                        patch_body = {
                            "title": l_content,
                            "status": "completed" if l_done else "needsAction"
                        }
                        service.tasks().patch(tasklist=tasklist_id, task=t_id, body=patch_body).execute()
                    except Exception as e:
                        print(f"[Google Tasks Sync] Error patching remote task {t_id}: {e}")
            elif r_changed and not l_changed:
                # Remote changed, update local
                print(f"[Google Tasks Sync] Remote update on {t_id}: '{r_content}' (done={r_done}) -> updating local...")
                local_item["content"] = r_content
                local_item["done"] = r_done
                changes_made = True
            elif l_changed and r_changed:
                # Both changed: prioritize local done toggle if it changed, otherwise remote content
                if l_done != p_done:
                    print(f"[Google Tasks Sync] Conflict on {t_id}: local done state wins...")
                    if not dry_run:
                        service.tasks().patch(
                            tasklist=tasklist_id,
                            task=t_id,
                            body={"status": "completed" if l_done else "needsAction"}
                        ).execute()
                    local_item["content"] = r_content
                else:
                    local_item["content"] = r_content
                    local_item["done"] = r_done
                changes_made = True

    # 6. Remote additions (in remote_active, not in local_with_id, not in prev_state)
    for r_id, r_item in remote_active.items():
        if r_id not in local_with_id and r_id not in prev_state:
            r_content = r_item.get("title", "")
            r_done = (r_item.get("status") == "completed")
            print(f"[Google Tasks Sync] New remote task {r_id}: '{r_content}' (done={r_done}) -> adding to local...")
            local_with_id[r_id] = {
                "id": r_id,
                "content": r_content,
                "done": r_done
            }
            changes_made = True

    # 7. Assemble final task list in remote order
    final_tasks = []
    for t_id, item in local_with_id.items():
        final_tasks.append({
            "id": t_id,
            "content": item["content"],
            "done": item["done"]
        })

    # Sort using remote order
    final_tasks.sort(key=lambda t: remote_order.get(t["id"], 999999))

    # 8. Save updated state and todo.json
    new_state_tasks = {
        t["id"]: {"content": t["content"], "done": t["done"]}
        for t in final_tasks
    }

    if not dry_run:
        # Check if local_tasks has changed
        if json.dumps(local_tasks, sort_keys=True) != json.dumps(final_tasks, sort_keys=True):
            print(f"[Google Tasks Sync] Saving {len(final_tasks)} tasks to {TODO_FILE}...")
            save_json_atomic(TODO_FILE, final_tasks)
            notify_quickshell()
        else:
            print("[Google Tasks Sync] Local tasks are already up to date.")

        save_json_atomic(STATE_FILE, {"tasks": new_state_tasks})
        print("[Google Tasks Sync] Sync completed successfully.")


def main():
    parser = argparse.ArgumentParser(description="Google Tasks 2-Way Sync for Quickshell")
    parser.add_argument("--auth", action="store_true", help="Run interactive browser login flow")
    parser.add_argument("--dry-run", action="store_true", help="Simulate sync without making modifications")
    args = parser.parse_args()

    service = get_service(auth_interactive=args.auth)
    if not service:
        sys.exit(1)

    try:
        sync_tasks(service, dry_run=args.dry_run)
    except Exception as e:
        print(f"[Google Tasks Sync] Sync error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
