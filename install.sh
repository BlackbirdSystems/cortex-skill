#!/bin/bash

# Cortex Memory Skill - One-shot Installer
# This script downloads and installs the cortex-memory skill globally and configures it for the current workspace.

set -e

SKILL_REPO="https://github.com/BlackbirdSystems/cortex-skill.git"
SKILL_HOME="$HOME/.gemini/skills/cortex-memory"

echo "--- 🧠 Cortex Memory Skill Installer ---"

# 1. Check prerequisites
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git and try again."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed. Please install python3 and try again."
    exit 1
fi

# 2. Download/Update the skill globally
if [ -d "$SKILL_HOME" ]; then
    echo "Updating existing skill in $SKILL_HOME..."
    cd "$SKILL_HOME"
    git pull origin main
else
    echo "Cloning skill to $SKILL_HOME..."
    mkdir -p "$(dirname "$SKILL_HOME")"
    git clone "$SKILL_REPO" "$SKILL_HOME"
fi

# 3. Run the internal installer
echo "Configuring skill for the current workspace: $PWD"
python3 "$SKILL_HOME/install.py" "$PWD"

echo "--- ✅ Installation Complete ---"
echo "The cortex-memory skill is now active in this workspace."
