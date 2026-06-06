# Cortex Memory Skill Makefile

SKILL_NAME := cortex-memory
PYTHON := python3
SKILL_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
TARGET_PROJECT ?= $(shell pwd)

.PHONY: install
install:
	$(PYTHON) $(SKILL_DIR)/install.py $(TARGET_PROJECT)

.PHONY: link-gemini
link-gemini: install

.PHONY: help
help:
	@echo "Cortex Memory Skill"
	@echo "Usage:"
	@echo "  make install      - Install the skill and configure hooks"
	@echo "  make link-gemini  - Alias for install"
