SKILL_DIR := $(HOME)/.claude/skills/openclaw-bridge

.PHONY: install uninstall

install:
	@mkdir -p $(SKILL_DIR)
	@cp SKILL.md $(SKILL_DIR)/SKILL.md
	@echo "Installed openclaw-bridge skill to $(SKILL_DIR)"

uninstall:
	@rm -rf $(SKILL_DIR)
	@echo "Removed openclaw-bridge skill from $(SKILL_DIR)"
