import hashlib
import json
import os
import sys

INSTRUCTION_ALIASES = {
    "codex-prompt.json": "claude-prompt.json",
}

HOOK_INSTRUCTION_MAP = {
    "SessionStart": "session-start",
    "UserPromptSubmit": "codex-prompt",
    "PreToolUse": "",
    "PostToolUse": "",
    "Stop": "",
}


def script_dir() -> str:
    return os.path.dirname(os.path.realpath(__file__))


def load_json(path: str, default):
    if not os.path.exists(path):
        return default
    try:
        with open(path, "r") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return default


def load_instruction(instruction_name: str) -> str:
    if not instruction_name:
        return ""

    if not instruction_name.endswith(".json"):
        instruction_name += ".json"

    instruction_path = os.path.join(script_dir(), "instructions", instruction_name)
    if not os.path.exists(instruction_path):
        aliased_name = INSTRUCTION_ALIASES.get(instruction_name)
        if aliased_name:
            instruction_path = os.path.join(script_dir(), "instructions", aliased_name)

    data = load_json(instruction_path, {})
    if not isinstance(data, dict):
        return ""
    return data.get("additionalContext") or ""


def emit_hook_context(event_name: str, context: str) -> int:
    if not context:
        return 0

    payload = {
        "hookSpecificOutput": {
            "hookEventName": event_name,
            "additionalContext": context,
        }
    }
    sys.stdout.write(json.dumps(payload))
    return 0


def calculate_checksum(path: str) -> str:
    if not os.path.exists(path):
        return f"Error: File not found: {path}"
    try:
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                h.update(chunk)
        return h.hexdigest()
    except Exception as e:
        return f"Error: {e}"


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: hook.py <instruction-name-or-hook-event-or-command> [args...]", file=sys.stderr)
        return 1

    command = sys.argv[1]

    # Special Command: Checksum
    if command == "Checksum":
        if len(sys.argv) < 3:
            print("Error: Missing file path for Checksum command", file=sys.stderr)
            return 1
        print(calculate_checksum(sys.argv[2]))
        return 0

    if command in HOOK_INSTRUCTION_MAP:
        return emit_hook_context(command, load_instruction(HOOK_INSTRUCTION_MAP[command]))

    context = load_instruction(command)
    if context:
        sys.stdout.write(context)
    return 0


if __name__ == "__main__":
    sys.exit(main())
