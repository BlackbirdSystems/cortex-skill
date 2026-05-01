SHELL := /bin/bash

SKILL_NAME ?= cortex-memory-lifecycle-hooks
SELF_MAKEFILE := $(abspath $(lastword $(MAKEFILE_LIST)))
SKILL_DIR ?= $(abspath $(dir $(SELF_MAKEFILE)))
TARGET_PROJECT ?= $(CURDIR)

CODEX_HOME ?= $(HOME)/.codex
CODEX_SKILL_DIR := $(CODEX_HOME)/skills/$(SKILL_NAME)
CLAUDE_HOME ?= $(HOME)/.claude
CLAUDE_COMMAND_DIR := $(CLAUDE_HOME)/commands
CLAUDE_COMMAND_FILE := $(CLAUDE_COMMAND_DIR)/$(SKILL_NAME).md

.PHONY: install-skill install-agent-hooks uninstall-skill link-codex unlink-codex link-gemini unlink-gemini link-claude unlink-claude

install-skill:
	@$(MAKE) -f "$(SELF_MAKEFILE)" link-codex
	@$(MAKE) -f "$(SELF_MAKEFILE)" install-agent-hooks
	@$(MAKE) -f "$(SELF_MAKEFILE)" link-gemini
	@$(MAKE) -f "$(SELF_MAKEFILE)" link-claude

install-agent-hooks:
	@cd "$(TARGET_PROJECT)" && bash "$(SKILL_DIR)/install/install-agent-hooks.sh"

uninstall-agent-hooks:
	@cd "$(TARGET_PROJECT)" && bash "$(SKILL_DIR)/install/uninstall-agent-hooks.sh"

uninstall-skill:
	@$(MAKE) -f "$(SELF_MAKEFILE)" unlink-codex
	@$(MAKE) -f "$(SELF_MAKEFILE)" unlink-gemini
	@$(MAKE) -f "$(SELF_MAKEFILE)" unlink-claude
	@$(MAKE) -f "$(SELF_MAKEFILE)" uninstall-agent-hooks

link-codex:
	@test -f "$(SKILL_DIR)/SKILL.md" || (echo "Skill not found at $(SKILL_DIR)" && exit 1)
	@mkdir -p "$(CODEX_HOME)/skills"
	@rm -rf "$(CODEX_SKILL_DIR)"
	@ln -s "$(SKILL_DIR)" "$(CODEX_SKILL_DIR)"
	@echo "Linked Codex skill for $(SKILL_NAME)"
	@echo "Codex -> $(CODEX_SKILL_DIR)"
	@echo "Skill link -> $(SKILL_DIR)"
	@echo "Use this explicitly in prompts for complex tasks."

unlink-codex:
	@rm -rf "$(CODEX_SKILL_DIR)"
	@echo "Unlinked Codex skill for $(SKILL_NAME)"
	@echo "Codex -> $(CODEX_SKILL_DIR)"

link-gemini:
	@test -f "$(SKILL_DIR)/SKILL.md" || (echo "Skill not found at $(SKILL_DIR)" && exit 1)
	@command -v gemini >/dev/null 2>&1 || (echo "gemini CLI is required" && exit 1)
	@mkdir -p "$(HOME)/.gemini"
	@[ -f "$(HOME)/.gemini/projects.json" ] || printf '%s\n' '{"projects":{}}' > "$(HOME)/.gemini/projects.json"
	@cd "$(TARGET_PROJECT)" && gemini skills link "$(SKILL_DIR)" --scope workspace --consent
	@echo "Linked Gemini workspace skill for $(SKILL_NAME)"
	@echo "Workspace -> $(TARGET_PROJECT)"
	@echo "Skill link -> $(SKILL_DIR)"
	@echo "Use this explicitly in prompts for complex tasks."

unlink-gemini:
	@command -v gemini >/dev/null 2>&1 || (echo "gemini CLI is required" && exit 1)
	@cd "$(TARGET_PROJECT)" && gemini skills uninstall "$(SKILL_NAME)" --scope workspace || true
	@echo "Unlinked Gemini workspace skill for $(SKILL_NAME)"
	@echo "Workspace -> $(TARGET_PROJECT)"

link-claude:
	@test -f "$(SKILL_DIR)/SKILL.md" || (echo "Skill not found at $(SKILL_DIR)" && exit 1)
	@mkdir -p "$(CLAUDE_COMMAND_DIR)"
	@printf '%s\n' \
		'# $(SKILL_NAME)' \
		'' \
		'Use the lifecycle policy defined here as the source of truth:' \
		'' \
		'$(SKILL_DIR)/SKILL.md' \
		'' \
		'When the task is complex:' \
		'1. Call `cortex.begin_task` before substantive work.' \
		'2. Use `cortex.search` before each major phase.' \
		'3. Store decisions and evidence with `cortex.store`.' \
		'4. Use graph or extraction tools only when justified.' \
		'5. Call `cortex.finish_task` before ending the task.' \
		'' \
		'Reference tool mapping:' \
		'$(SKILL_DIR)/references/mcp-tool-mapping.md' \
		> "$(CLAUDE_COMMAND_FILE)"
	@echo "Linked Claude command for $(SKILL_NAME)"
	@echo "Claude -> $(CLAUDE_COMMAND_FILE)"
	@echo "Skill link -> $(SKILL_DIR)"

unlink-claude:
	@rm -f "$(CLAUDE_COMMAND_FILE)"
	@echo "Unlinked Claude command for $(SKILL_NAME)"
	@echo "Claude -> $(CLAUDE_COMMAND_FILE)"
