# Changelog

## 0.0.13

- Breaking change: simplified Buildwright to five public commands:
  `/bw-plan`, `/bw-work`, `/bw-verify`, `/bw-ship`, and `/bw-analyse`.
- Replaced `/bw-new-feature`, `/bw-quick`, and `/bw-claw` with `/bw-work`.
- Removed claws, worktree skills, task templates, requirements templates, and
  placeholder steering docs.
- Added `.buildwright/steering/philosophy.md` as the default steering source
  for KISS, YAGNI, DRY, Red-Green-Refactor, and documentation discipline.
- Made steering discovery recursive so nested steering docs are picked up.
- Stopped installing Buildwright's own GitHub Actions workflow into downstream
  projects.
