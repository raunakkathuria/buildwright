.PHONY: dist clean sync sync-check opencode openclaw validate

# ============================================================================
# Sync — Generate .claude/ and .opencode/ from .buildwright/ (canonical)
# Source of truth: .buildwright/ → .claude/ + .opencode/ + AGENTS.md + dist/
# ============================================================================

sync:
	@chmod +x scripts/sync-agents.sh
	@scripts/sync-agents.sh

sync-check:
	@chmod +x scripts/sync-agents.sh
	@scripts/sync-agents.sh --check

# ============================================================================
# Package for distribution
# ============================================================================

# ClawHub — upload dist/buildwright/ folder to https://clawhub.ai/upload
dist: sync
	@echo "dist/buildwright/ ready — upload this folder to ClawHub"

# OpenCode — install skill to user global config
opencode: sync
	@mkdir -p ~/.config/opencode/skills/buildwright
	@cp SKILL.md ~/.config/opencode/skills/buildwright/SKILL.md
	@echo "Installed to ~/.config/opencode/skills/buildwright/"

# OpenClaw — install skill to user skills directory
openclaw: sync
	@mkdir -p ~/.openclaw/skills/buildwright
	@cp SKILL.md ~/.openclaw/skills/buildwright/SKILL.md
	@echo "Installed to ~/.openclaw/skills/buildwright/"

# ============================================================================
# Validate SKILL.md against Agent Skills spec (agentskills.io)
# ============================================================================

validate:
	@chmod +x scripts/validate-skill.sh
	@scripts/validate-skill.sh SKILL.md

# ============================================================================
# Clean
# ============================================================================

clean:
	rm -rf dist/
