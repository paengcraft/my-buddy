# Repository Instructions

## Scope

- These instructions apply to the entire `buddy-noti` repository.
- Follow these repository instructions before any global/default agent preference when working in this repository.

## Communication

- Use polite Korean when replying to the user.
- Do not make unsupported conclusions. State the reason, evidence, or assumption behind technical claims.
- If requirements are ambiguous, ask a concise question before implementation.
- When options matter, present the recommendation, reason, and tradeoff.
- For numbers such as cost, performance, or timing, state the assumptions used.

## Engineering Rules

- Check repository structure, existing patterns, lint/format/test commands, and local instructions before implementation.
- Prefer practical, focused changes over broad refactors.
- Fix the root cause first. Avoid temporary patches unless explicitly requested.
- Avoid unnecessary abstraction and unclear naming.
- Keep commits reviewable. Do not mix feature, fix, refactor, and cleanup work in a single commit.
- Do not leave unrelated generated files or local tool state in commits.

## My Buddy Restart Rule

- After applying code changes to the native app, restart the local My Buddy process before reporting completion.
- If the change affects compiled native code or bundled resources, rebuild first:

```bash
cd native
swift test
./scripts/build_app.sh
```

- Then stop any running local app process and start the rebuilt app:

```bash
pkill -x "My Buddy" || true
pkill -x "MyBuddy" || true
open -n "native/build/My Buddy.app"
```

- If the app cannot be restarted, report the exact command that failed and the observed error.

## Git Policy

- Do not push directly to `dev`, `qa`, or `main`.
- Use a `feature/` branch for implementation work unless the user explicitly requests another non-protected branch.
- Commit one logical change at a time.
- Use this commit message format:

```text
<type> : <title>

<body>

<footer>
```

- Keep `<title>` at 50 characters or less, without a trailing period.
- Use one of these types: `feature`, `fix`, `docs`, `test`, `refactor`, `style`, `chore`.
- Include a related issue number or Notion link in the footer when one exists.
