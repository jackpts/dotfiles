# AGENTS Configuration for Zed Editor

This file documents the configuration and keybindings related to the Zed Editor's built-in agent/assistant features within this dotfiles setup.

## 1. Agent Keybindings (`keymap.json`)

The primary keybinding for interacting with the Zed Agent is configured in `/home/jacky/dotfiles/.config/zed/keymap.json`.

| Action | Keybinding | Command | Notes |
| :--- | :--- | :--- | :--- |
| Toggle Agent Chat Focus | `space a c` | `agent::ToggleFocus` | Opens/closes the agent panel. (Replaced deprecated `assistant::ToggleFocus`) |
| Select All (Vim equivalent `ggVG`) | `ctrl-a` | `editor::SelectAll` | Added for convenience in normal/visual mode. |
| Close Inactive Panes | `space b o` | `pane::CloseOtherItems` | Replaced deprecated `pane::CloseInactiveItems`. |

## 2. API Key Management (`settings.json`)

**SECURITY WARNING:** Any API keys (e.g., Context7) must **NEVER** be committed to public repositories.

*   **Location:** Secrets are stored in `/home/jacky/dotfiles/.config/zed/settings.json`.
*   **Best Practice:** Sensitive strings like API keys should be managed via environment variables or a dedicated secrets manager.
*   **Path Hardcoding:** Absolute paths revealing usernames (like `/home/jacky/`) in configuration files that might be shared have been replaced with `$HOME` references where applicable in tool permissions patterns.


# Propose a commit message after every task

When a task is finished (code and/or docs changed), **always propose a commit message** that matches the actual file changes.

**Propose a commit (only after 1–5)** — end the answer with a **Suggested commit** line:

- Use advanced Conventional Commits format: `type(scope): subject` when a scope adds clarity, otherwise `type: subject`.
- Prefer standard types such as `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, and `revert`.
- Keep the subject imperative, lowercase, and concise (~50–72 chars), e.g. `feat(auth): add organisation role guard` or `chore: align suggested commit format`.
- Optional second line only if the “why” is not obvious from the subject.
- Match recent `git log` style on this repo where possible, but keep the suggested format Conventional Commits; do **not** run `git commit` unless the user asks.
