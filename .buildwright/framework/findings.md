# Deferred Findings

While working, two kinds of finding recur and tend to scatter across PR
descriptions, chat threads, and `// TODO` comments. Capture them **when they
arise**, in the same format, in one place per class that people can find. Do not
leave them for the next project to find again.

This is a convention; there is no dedicated command. `/bw-work` and `/bw-ship`
record findings into the project's known location for each class (create the
file on first use if it doesn't exist — never discard a finding).

## Two classes

### report-upstream
An issue that is better fixed at its source (a shared template, library, or
upstream project), so everyone gains, rather than only being patched locally.

```
## [ ] <title>
- Symptom: <what goes wrong>
- Context: <where it arose — file:line, command, decision>
- Upstream fix: <hypothesised fix at the source>
```

### before-production
A decision that is acceptable for staging/demo but **must** be resolved before a
production release.

```
## <area / topic>
- Ships now (staging/demo): <what v1 does>
- Before production: <what must change>
- Why staging is OK: <the reasoning>
```

## Rules

- Record the finding at the moment it is made, in the format for its class.
- Keep each class in one known location per project (e.g. an upstream-issues doc
  and a before-production doc); if the file is missing, create it.
- Mark items resolved and move them out (to history / the plan) once handled.
- This convention is Buildwright's; it does **not** seed files into any specific
  service template.
