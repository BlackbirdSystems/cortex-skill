import os
import sys
import subprocess
import json
import shutil

STARTUP_BLOCK_BEGIN = "# >>> cortex memory startup block >>>"
STARTUP_BLOCK_END = "# <<< cortex memory startup block <<<"

def run_command(cmd, cwd=None):
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
    return result


def load_json(path, default):
    if not os.path.exists(path):
        return default
    try:
        with open(path, "r") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return default


def save_json(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def read_text(path):
    if not os.path.exists(path):
        return ""
    with open(path, "r") as f:
        return f.read()


def save_text(path, content):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(path, "w") as f:
        f.write(content)


def resolve_skill_dir(script_path):
    script_dir = os.path.dirname(os.path.realpath(script_path))
    if os.path.exists(os.path.join(script_dir, "SKILL.md")):
        return script_dir
    return os.path.dirname(script_dir)


def upsert_named_hook(hook_groups, hook_name, command):
    for group in hook_groups:
        hooks = group.get("hooks", [])
        for inner in hooks:
            if inner.get("name") == hook_name:
                inner["type"] = "command"
                inner["command"] = command
                return

    hook_groups.append({
        "matcher": "*",
        "hooks": [
            {
                "name": hook_name,
                "type": "command",
                "command": command,
            }
        ]
    })


def upsert_startup_block(project_root, skill_dir):
    template_path = os.path.join(skill_dir, "install", "templates", "AGENTS.md")
    if not os.path.exists(template_path):
        return

    template = read_text(template_path).strip()
    target_path = os.path.join(project_root, "AGENTS.md")
    existing = read_text(target_path)

    if not existing.strip():
        save_text(target_path, template + "\n")
        return

    start = existing.find(STARTUP_BLOCK_BEGIN)
    end = existing.find(STARTUP_BLOCK_END)
    if start != -1 and end != -1 and end >= start:
        end += len(STARTUP_BLOCK_END)
        replacement = template
        prefix = existing[:start].rstrip()
        suffix = existing[end:].lstrip("\n")
        parts = [part for part in [prefix, replacement, suffix] if part]
        save_text(target_path, "\n\n".join(parts) + "\n")
        return

    save_text(target_path, existing.rstrip() + "\n\n" + template + "\n")

def main():
    skill_dir = resolve_skill_dir(__file__)

    # Allow passing project root as an argument, otherwise default to current workspace
    if len(sys.argv) > 1:
        project_root = os.path.abspath(sys.argv[1])
    else:
        project_root = os.path.abspath(os.path.join(skill_dir, "..", ".."))
    
    print(f"Installing cortex-memory skill...")
    print(f"Project root: {project_root}")

    upsert_startup_block(project_root, skill_dir)

    # 1. Setup virtual environment
    venv_dir = os.path.join(skill_dir, ".venv")
    if not os.path.exists(venv_dir):
        run_command([sys.executable, "-m", "venv", venv_dir])
    
    # 2. Install requirements (if any)
    requirements_path = os.path.join(skill_dir, "requirements.txt")
    if os.path.exists(requirements_path) and os.path.getsize(requirements_path) > 0:
        pip_path = os.path.join(venv_dir, "bin", "pip")
        run_command([pip_path, "install", "-r", requirements_path])

    # 3. Setup hooks for Claude, Codex, and Gemini
    hook_py_path = os.path.join(skill_dir, "hooks", "hook.py")
    instructions_dir = os.path.join(skill_dir, "hooks", "instructions")
    references_dir = os.path.join(skill_dir, "references")
    python_path = os.path.join(venv_dir, "bin", "python3")

    for agent in [".claude", ".codex", ".gemini"]:
        agent_dir = os.path.join(project_root, agent)
        hooks_dir = os.path.join(agent_dir, "hooks")
        os.makedirs(hooks_dir, exist_ok=True)

        # Helper to create/update symlink
        def update_symlink(src, dst_dir, name):
            dst = os.path.join(dst_dir, name)
            if os.path.islink(dst):
                os.remove(dst)
            elif os.path.exists(dst):
                if os.path.isdir(dst):
                    shutil.rmtree(dst)
                else:
                    os.remove(dst)
            
            rel_path = os.path.relpath(src, dst_dir)
            os.symlink(rel_path, dst)
            return dst

        # Link artifacts
        hook_symlink_path = os.path.join(hooks_dir, "hook.py")
        update_symlink(hook_py_path, hooks_dir, "hook.py")
        update_symlink(instructions_dir, hooks_dir, "instructions")
        update_symlink(references_dir, hooks_dir, "references")

        # Create/Update hooks.json (for Claude/Codex) without clobbering other hooks.
        if agent in [".claude", ".codex"]:
            hooks_json_path = os.path.join(hooks_dir, "hooks.json")
            hooks_config = load_json(hooks_json_path, {})
            hooks_config["description"] = "Cortex Memory Lifecycle hooks"
            hooks_config.setdefault("hooks", {})
            hooks_config["hooks"].setdefault("SessionStart", [])
            hooks_config["hooks"].setdefault("UserPromptSubmit", [])

            # Use relative path to hook.py from hooks directory
            hook_command_base = f"{python_path} {hook_symlink_path}"

            upsert_named_hook(
                hooks_config["hooks"]["SessionStart"],
                "cortex-memory-session-start",
                f"{hook_command_base} SessionStart",
            )
            upsert_named_hook(
                hooks_config["hooks"]["UserPromptSubmit"],
                "cortex-memory-user-prompt",
                f"{hook_command_base} UserPromptSubmit",
            )

            save_json(hooks_json_path, hooks_config)
            print(f"Configured hooks.json for {agent}")

        # Update hooks.json (for Gemini - uses same format as Claude/Codex)
        if agent == ".gemini":
            hooks_json_path = os.path.join(hooks_dir, "hooks.json")
            hooks_config = load_json(hooks_json_path, {})
            hooks_config["description"] = "Cortex Memory Lifecycle hooks"
            hooks_config.setdefault("hooks", {})
            hooks_config["hooks"].setdefault("SessionStart", [])
            hooks_config["hooks"].setdefault("UserPromptSubmit", [])

            hook_command_base = f"{python_path} {hook_symlink_path}"

            upsert_named_hook(
                hooks_config["hooks"]["SessionStart"],
                "cortex-memory-session-start",
                f"{hook_command_base} SessionStart",
            )
            upsert_named_hook(
                hooks_config["hooks"]["UserPromptSubmit"],
                "cortex-memory-user-prompt",
                f"{hook_command_base} UserPromptSubmit",
            )

            save_json(hooks_json_path, hooks_config)
            print(f"Configured hooks.json for {agent}")

    # 4. Global Skill Linking for all supported agents
    for agent_home in ["~/.gemini", "~/.codex", "~/.claude"]:
        agent_path = os.path.expanduser(agent_home)
        if os.path.exists(agent_path):
            global_skills_dir = os.path.join(agent_path, "skills")
            os.makedirs(global_skills_dir, exist_ok=True)
            global_skill_link = os.path.join(global_skills_dir, "cortex-memory")
            
            # Avoid linking a directory to itself
            if os.path.realpath(skill_dir) == os.path.realpath(global_skill_link):
                print(f"Skill is already located at {global_skill_link}, skipping link.")
                continue
                
            try:
                if os.path.islink(global_skill_link):
                    os.remove(global_skill_link)
                elif os.path.exists(global_skill_link):
                    shutil.rmtree(global_skill_link)

                os.symlink(skill_dir, global_skill_link)
                print(f"Linked skill globally for {agent_home} to {global_skill_link}")
            except OSError as e:
                print(f"Warning: Could not update global skill link for {agent_home}: {e}")

    print("✅ cortex-memory skill installed successfully with all artifacts.")

if __name__ == "__main__":
    main()
