#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

AGENTS_TEMPLATE="${INSTALL_DIR}/templates/AGENTS.md"

if [ ! -f "${AGENTS_TEMPLATE}" ]; then
    echo "Error: template not found at ${AGENTS_TEMPLATE}" >&2
    exit 1
fi

ensure_codex_hooks_enabled() {
    local config_file="$1"
    local temp_file

    mkdir -p "$(dirname "${config_file}")"

    if [ ! -f "${config_file}" ]; then
        cat > "${config_file}" <<'EOF'
[features]
codex_hooks = true
EOF
        return
    fi

    temp_file="$(mktemp)"
    awk '
        BEGIN {
            in_features = 0
            features_seen = 0
            hooks_seen = 0
        }

        function emit_codex_hooks() {
            if (!hooks_seen) {
                print "codex_hooks = true"
                hooks_seen = 1
            }
        }

        /^\[features\]$/ {
            features_seen = 1
            in_features = 1
            print
            next
        }

        in_features && /^\[/ {
            emit_codex_hooks()
            in_features = 0
            print
            next
        }

        in_features && /^[[:space:]]*codex_hooks[[:space:]]*=/ {
            print "codex_hooks = true"
            hooks_seen = 1
            next
        }

        {
            print
        }

        END {
            if (in_features) {
                emit_codex_hooks()
            } else if (!features_seen) {
                if (NR > 0) {
                    print ""
                }
                print "[features]"
                print "codex_hooks = true"
            }
        }
    ' "${config_file}" > "${temp_file}"

    mv "${temp_file}" "${config_file}"
}

upsert_startup_block() {
    local target_file="$1"
    local temp_file
    local begin_line
    local end_line
    local total_lines

    mkdir -p "$(dirname "${target_file}")"

    if [ ! -f "${target_file}" ]; then
        cp "${AGENTS_TEMPLATE}" "${target_file}"
        return
    fi

    temp_file="$(mktemp)"
    begin_line="$(grep -nF "# >>> cortex memory startup block >>>" "${target_file}" | head -n1 | cut -d: -f1 || true)"

    if [ -n "${begin_line}" ]; then
        end_line="$(awk -F: -v start="${begin_line}" -v marker="# <<< cortex memory startup block <<<" '$1 >= start && index($2, marker) { print $1; exit }' <(grep -nF "# <<< cortex memory startup block <<<" "${target_file}") || true)"
        if [ -z "${end_line}" ]; then
            end_line="$(wc -l < "${target_file}")"
        fi
        total_lines="$(wc -l < "${target_file}")"

        if [ "${begin_line}" -gt 1 ]; then
            sed -n "1,$((begin_line - 1))p" "${target_file}" > "${temp_file}"
            echo "" >> "${temp_file}"
        else
            : > "${temp_file}"
        fi
        cat "${AGENTS_TEMPLATE}" >> "${temp_file}"

        if [ "${end_line}" -lt "${total_lines}" ]; then
            echo "" >> "${temp_file}"
            sed -n "$((end_line + 1)),\$p" "${target_file}" >> "${temp_file}"
        fi
    else
        cat "${target_file}" > "${temp_file}"
        total_lines="$(wc -l < "${target_file}")"
        if [ "${total_lines}" -gt 0 ]; then
            echo "" >> "${temp_file}"
        fi
        cat "${AGENTS_TEMPLATE}" >> "${temp_file}"
    fi

    mv "${temp_file}" "${target_file}"
}

upsert_gemini_hooks() {
    local settings_file="$1"

    python3 - "$settings_file" <<'PY'
import json
import sys
import os

settings_path = sys.argv[1]
if os.path.exists(settings_path):
    with open(settings_path, "r") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            data = {}
else:
    data = {}

if "hooks" not in data:
    data["hooks"] = {}

hooks_config = {
    "SessionStart": {
        "name": "cortex-memory-session-start",
        "type": "command",
        "command": "$GEMINI_PROJECT_DIR/.gemini/hooks/session-start.sh"
    },
    "BeforeAgent": {
        "name": "cortex-memory-before-agent",
        "type": "command",
        "command": "$GEMINI_PROJECT_DIR/.gemini/hooks/before-agent.sh"
    }
}

for event, hook_def in hooks_config.items():
    if event not in data["hooks"]:
        data["hooks"][event] = []

    # Check if hook already exists
    exists = False
    for matcher_group in data["hooks"][event]:
        if "hooks" in matcher_group:
            for h in matcher_group["hooks"]:
                if h.get("name") == hook_def["name"]:
                    h.update(hook_def)
                    exists = True
                    break
        if exists: break

    if not exists:
        data["hooks"][event].append({
            "matcher": "*",
            "hooks": [hook_def]
        })

with open(settings_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

write_hooks_config() {
    local template="$1"
    local output_path="$2"
    local session_start_hook="$3"
    local user_prompt_hook="$4"

    python3 - "$template" "$output_path" "$session_start_hook" "$user_prompt_hook" <<'PY'
import json
import os
import sys
from copy import deepcopy

template_path, output_path, session_start_hook, user_prompt_hook = sys.argv[1:]

with open(template_path, "r", encoding="utf-8") as f:
    template = json.load(f)

if os.path.exists(output_path):
    try:
        with open(output_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError:
        data = {}
else:
    data = {}

data.setdefault("hooks", {})

def substitute_command(hook):
    hook = deepcopy(hook)
    command = hook.get("command")
    if command == "__SESSION_START_HOOK__":
        hook["command"] = session_start_hook
    elif command == "__USER_PROMPT_HOOK__":
        hook["command"] = user_prompt_hook
    return hook

for event_name, matchers in template.get("hooks", {}).items():
    existing_matchers = data["hooks"].setdefault(event_name, [])
    for matcher in matchers:
        hooks = [substitute_command(hook) for hook in matcher.get("hooks", [])]
        if not hooks:
            continue

        existing_commands = {
            hook.get("command")
            for group in existing_matchers
            for hook in group.get("hooks", [])
        }
        new_hooks = [hook for hook in hooks if hook.get("command") not in existing_commands]
        if new_hooks:
            matcher_copy = deepcopy(matcher)
            matcher_copy["hooks"] = new_hooks
            existing_matchers.append(matcher_copy)

with open(output_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

echo "Installing Cortex Memory Lifecycle Hooks for Codex, Gemini, and Claude..."

# 1. Project Global Guidance
echo "Updating AGENTS.md..."
upsert_startup_block "${PROJECT_ROOT}/AGENTS.md"

# 2. Codex Specific
CODEX_HOME_DIR="${CODEX_HOME:-${HOME}/.codex}"
PROJECT_CODEX_DIR="${PROJECT_ROOT}/.codex"
PROJECT_HOOKS_DIR="${PROJECT_CODEX_DIR}/hooks"
CODEX_CONFIG_FILE="${CODEX_HOME_DIR}/config.toml"

echo "Updating Codex hooks..."
mkdir -p "${PROJECT_HOOKS_DIR}"
cp "${INSTALL_DIR}/claude/hooks/scripts/session-start.sh" "${PROJECT_HOOKS_DIR}/session-start.sh"
cp "${INSTALL_DIR}/claude/hooks/scripts/user-prompt.sh" "${PROJECT_HOOKS_DIR}/user-prompt-submit.sh"
chmod +x "${PROJECT_HOOKS_DIR}/session-start.sh" "${PROJECT_HOOKS_DIR}/user-prompt-submit.sh"
write_hooks_config "${INSTALL_DIR}/claude/hooks/hooks.json" "${PROJECT_HOOKS_DIR}/hooks.json" "${PROJECT_HOOKS_DIR}/session-start.sh" "${PROJECT_HOOKS_DIR}/user-prompt-submit.sh"
ensure_codex_hooks_enabled "${CODEX_CONFIG_FILE}"

# 3. Gemini CLI Specific
echo "Updating Gemini hooks..."

GEMINI_HOOKS_DIR="${PROJECT_ROOT}/.gemini/hooks"
mkdir -p "${GEMINI_HOOKS_DIR}"
cp "${INSTALL_DIR}/gemini/hooks/session-start.sh" "${GEMINI_HOOKS_DIR}/session-start.sh"
cp "${INSTALL_DIR}/gemini/hooks/before-agent.sh" "${GEMINI_HOOKS_DIR}/before-agent.sh"
chmod +x "${GEMINI_HOOKS_DIR}/session-start.sh" "${GEMINI_HOOKS_DIR}/before-agent.sh"
upsert_gemini_hooks "${PROJECT_ROOT}/.gemini/settings.json"

# 4. Claude Specific (Convention)
echo "Updating Claude hooks..."

CLAUDE_HOOKS_DIR="${PROJECT_ROOT}/.claude/hooks"
mkdir -p "${CLAUDE_HOOKS_DIR}/scripts"
cp "${INSTALL_DIR}/claude/hooks/scripts/session-start.sh" "${CLAUDE_HOOKS_DIR}/scripts/session-start.sh"
cp "${INSTALL_DIR}/claude/hooks/scripts/user-prompt.sh" "${CLAUDE_HOOKS_DIR}/scripts/user-prompt.sh"
chmod +x "${CLAUDE_HOOKS_DIR}/scripts/session-start.sh" "${CLAUDE_HOOKS_DIR}/scripts/user-prompt.sh"
write_hooks_config "${INSTALL_DIR}/claude/hooks/hooks.json" "${CLAUDE_HOOKS_DIR}/hooks.json" "${CLAUDE_HOOKS_DIR}/scripts/session-start.sh" "${CLAUDE_HOOKS_DIR}/scripts/user-prompt.sh"

echo ""
echo "Done."
echo "--------------------------------------------------------"
echo "Manual Step for Claude Desktop / Web:"
echo "If you use Claude Desktop or the web interface, please ensure"
echo "your 'Custom Instructions' include the policy found in AGENTS.md."
echo "--------------------------------------------------------"
