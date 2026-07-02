.PHONY: sync sync-check install-hooks uninstall-hooks bump release test-cli

# ============================================================================
# Sync — Generate .claude/, .opencode/, .cursor/rules/ from .buildwright/ (canonical)
# Source of truth: .buildwright/ → .claude/ + .opencode/ + .cursor/rules/ + skills/
# ============================================================================

sync:
	@chmod +x .buildwright/scripts/sync-agents.sh
	@.buildwright/scripts/sync-agents.sh

sync-check:
	@chmod +x .buildwright/scripts/sync-agents.sh
	@.buildwright/scripts/sync-agents.sh --check

# ============================================================================
# Git Hooks — keep .buildwright/ ↔ generated files in sync automatically
# ============================================================================

install-hooks:
	@chmod +x .buildwright/scripts/install-hooks.sh
	@.buildwright/scripts/install-hooks.sh

uninstall-hooks:
	@rm -f .git/hooks/pre-commit .git/hooks/post-merge .git/hooks/post-checkout
	@echo "Buildwright hooks removed."

# ============================================================================
# Release
# ============================================================================

bump: ## Bump version files only (no git ops): make bump [BUMP=patch|minor|major]
	@chmod +x cli/scripts/bump-version.sh
	@cli/scripts/bump-version.sh $(or $(BUMP),patch)

release: ## Full release: bump, commit, tag, push, GitHub release, npm publish: make release [BUMP=patch|minor|major]
	@chmod +x cli/scripts/release.sh
	@cli/scripts/release.sh $(or $(BUMP),patch)

test-cli: ## Pack and install CLI globally for local testing
	@echo "Packing cli/..."
	@cd cli && npm pack
	@TARBALL=$$(ls cli/buildwright-*.tgz | tail -1) && \
	  npm install -g "./$$TARBALL" && \
	  rm -f "$$TARBALL"
	@echo ""
	@echo "✓ buildwright installed globally from local pack"
	@echo "  Test it: cd /tmp && mkdir test-bw && cd test-bw && buildwright init"
	@echo "  Uninstall: npm uninstall -g buildwright"
