.PHONY: dist clean

# Build a minimal skill folder for ClawHub upload
# Upload the generated dist/buildwright/ folder to https://clawhub.ai/upload
dist:
	mkdir -p dist/buildwright
	cp SKILL.md dist/buildwright/
	@echo "✅ dist/buildwright/ ready — upload this folder to ClawHub"

clean:
	rm -rf dist/
