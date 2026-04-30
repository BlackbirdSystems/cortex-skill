#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

remove_startup_block() {
    local target_file="$1"
    local temp_file
    local begin_line
    local end_line

    if [ ! -f "${target_file}" ]; then
        return
    fi

    begin_line="$(grep -nF "# >>> cortex memory startup block >>>" "${target_file}" | head -n1 | cut -d: -f1 || true)"

    if [ -n "${begin_line}" ]; then
        end_line="$(awk -F: -v start="${begin_line}" -v marker="# <<< cortex memory startup block <<<" '$1 >= start && index($2, marker) { print $1; exit }' <(grep -nF "# <<< cortex memory startup block <<<" "${target_file}") || true)"
        if [ -z "${end_line}" ]; then
            end_line="$(wc -l < "${target_file}")"
        fi

        temp_file="$(mktemp)"
        
        # Copy everything before the block
        if [ "${begin_line}" -gt 1 ]; then
            sed -n "1,$((begin_line - 1))p" "${target_file}" > "${temp_file}"
        else
            : > "${temp_file}"
        fi

        # Copy everything after the block
        local total_lines
        total_lines="$(wc -l < "${target_file}")"
        if [ "${end_line}" -lt "${total_lines}" ]; then
            sed -n "$((end_line + 1)),\$p" "${target_file}" >> "${temp_file}"
        fi
        
        # Remove potential double newlines at the end if we added them
        # (Simplified: just move the file)
        mv "${temp_file}" "${target_file}"
    fi
}

remove_gemini_hooks() {
    local settings_file="$1"

    if [ ! -f "${settings_file}" ]; then
        return
    fi

    python3 - "$settings_file" <<'PY'
import json
import sys
import os

settings_path = sys.argv[1]
with open(settings_path, "r") as f:
    try:
        data = json.load(f)
    except json.JSONDecodeError:
        sys.exit(0)

if "hooks" not in data:
    sys.exit(0)

hook_names = ["cortex-memory-session-start", "cortex-memory-before-agent"]

modified = False
for event in list(data["hooks"].keys()):
    new_matcher_groups = []
    for matcher_group in data["hooks"][event]:
        if "hooks" in matcher_group:
            initial_count = len(matcher_group["hooks"])
            matcher_group["hooks"] = [h for h in matcher_group["hooks"] if h.get("name") not in hook_names]
            if len(matcher_group["hooks"]) < initial_count:
                modified = True
            
            if len(matcher_group["hooks"]) > 0:
                new_matcher_groups.append(matcher_group)
        else:
            new_matcher_groups.append(matcher_group)
    
    if len(new_matcher_groups) > 0:
        data["hooks"][event] = new_matcher_groups
    else:
        del data["hooks"][event]
        modified = True

if modified:
    with open(settings_path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
PY
}

remove_hooks_config() {
    local config_file="$1"
    local session_start_hook="$2"
    local user_prompt_hook="$3"

    if [ ! -f "${config_file}" ]; then
        return
    fi

    python3 - "${config_file}" "${session_start_hook}" "${user_prompt_hook}" <<'PY'
import json
import sys

config_path, session_start_hook, user_prompt_hook = sys.argv[1:]

with open(config_path, "r", encoding="utf-8") as f:
    try:
        data = json.load(f)
    except json.JSONDecodeError:
        sys.exit(0)

hooks = data.get("hooks")
if not hooks:
    sys.exit(0)

target_commands = {session_start_hook, user_prompt_hook}
modified = False

for event_name in list(hooks.keys()):
    matcher_groups = []
    for matcher_group in hooks[event_name]:
        group_hooks = matcher_group.get("hooks", [])
        filtered_hooks = [hook for hook in group_hooks if hook.get("command") not in target_commands]
        if len(filtered_hooks) != len(group_hooks):
            modified = True
        if filtered_hooks:
            matcher_copy = dict(matcher_group)
            matcher_copy["hooks"] = filtered_hooks
            matcher_groups.append(matcher_copy)
        else:
            modified = True
    if matcher_groups:
        hooks[event_name] = matcher_groups
    else:
        del hooks[event_name]
        modified = True

if modified:
    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
PY
}

echo "Uninstalling Cortex Memory Lifecycle Hooks..."

# 1. Project Global Guidance
echo "Removing from AGENTS.md..."
remove_startup_block "${PROJECT_ROOT}/AGENTS.md"

# 2. Codex Specific
PROJECT_CODEX_DIR="${PROJECT_ROOT}/.codex"
echo "Cleaning up Codex hooks..."
remove_hooks_config "${PROJECT_CODEX_DIR}/hooks/hooks.json" "${PROJECT_CODEX_DIR}/hooks/session-start.sh" "${PROJECT_CODEX_DIR}/hooks/user-prompt-submit.sh"
rm -f "${PROJECT_CODEX_DIR}/hooks/session-start.sh" "${PROJECT_CODEX_DIR}/hooks/user-prompt-submit.sh"

# 3. Gemini CLI Specific
echo "Cleaning up Gemini hooks..."
remove_gemini_hooks "${PROJECT_ROOT}/.gemini/settings.json"
rm -f "${PROJECT_ROOT}/.gemini/hooks/session-start.sh" "${PROJECT_ROOT}/.gemini/hooks/before-agent.sh"

# 4. Claude Specific
echo "Cleaning up Claude hooks..."
remove_hooks_config "${PROJECT_ROOT}/.claude/hooks/hooks.json" "${PROJECT_ROOT}/.claude/hooks/scripts/session-start.sh" "${PROJECT_ROOT}/.claude/hooks/scripts/user-prompt.sh"
rm -f "${PROJECT_ROOT}/.claude/hooks/scripts/session-start.sh" "${PROJECT_ROOT}/.claude/hooks/scripts/user-prompt.sh"

echo "Done."
