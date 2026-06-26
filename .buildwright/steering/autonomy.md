# Autonomy

Buildwright commands follow **one** autonomy behaviour. There is no
environment-variable mode flag; behaviour is inferred from context, never
configured by the caller.

## The single behaviour

- **Proceed** — Execute autonomously. When a sequence of ready, question-free
  items exists (e.g. unchecked plan items), advance through them without waiting
  for a manual re-invocation per item.
- **Pause** — Stop and ask only when a decision is genuinely the human's to make,
  or when an input is ambiguous and confidence is low. These pause points are the
  human-in-the-loop control; the developer can also interrupt at any time to
  pause or stop the sequence.
- **Stop** — When genuinely blocked (a required input is missing, or a gate keeps
  failing after retries), stop and report the blocker clearly.

Verify your own work through tests and checks; commit only after verification
passes.

## Failure handling (context-inferred)

When a step fails after retries, infer the execution context from the
environment rather than a flag:

- **Interactive** (a TTY is attached and no CI signal is set): pause and report
  the blocker — the failed step, the specific reason, and the remediation — then
  wait for the human.
- **Unattended** (`CI` / `GITHUB_ACTIONS` set, or no TTY): preserve completed
  work — commit to the feature branch, push, open a `[FAILED]`-prefixed PR with
  the failure summary — and exit non-zero so CI registers the failure.
- **Indeterminate**: default to the unattended behaviour; never hang waiting for
  input that may never come.

Detect interactivity with a standard shell check (e.g. `[ -t 0 ]` / `[ -t 1 ]`)
and common CI variables; do not rely on any Buildwright-specific configuration.
