# AGENTS.md

## Project

Sanecode is a native macOS SwiftUI app for controlling local coding agents inside developer repositories.

It is a local-first command center for:
- opening repos
- running agent tasks
- streaming command output
- reviewing changes
- running checks
- previewing local apps
- using a terminal
- keeping or undoing changes

Sanecode is not a full IDE, not a cloud product, and not an Electron app.

## Core principles

- Mac-native first
- Local-first
- Safe by default
- Intuitive UI
- Minimal dependencies
- Small, focused diffs
- Clear separation between UI and core logic
- No cloud, accounts, payments, collaboration, or marketplace in v1

## Architecture

Use SwiftUI for the app UI.

Keep logic separated:
- Views: UI only
- ViewModels: state and user actions
- Core: shell, git, repo scanning, safety, preview, persistence
- Models: simple data types

Avoid putting shell/git/process logic directly inside SwiftUI views.

## Code style

- Prefer small files
- Prefer clear names
- Avoid clever abstractions
- Keep code readable for a solo developer
- Use async/await where appropriate
- Make UI updates on the main actor
- Handle errors clearly

## UX language

Use plain labels:
- Work
- Code
- Changes
- Preview
- Terminal
- Run Checks
- Undo Changes
- Keep Changes

Avoid exposing internal enum names or overly technical terms in the main UI.

## Safety

Do not run destructive commands without explicit user approval.

Blocked or approval-required commands include:
- rm -rf
- sudo
- chmod -R
- chown -R
- git reset --hard
- git clean -fd
- git push --force
- curl | bash
- wget | bash
- deploy commands
- production database migrations
- dependency installation
- file deletion

## Verification

Before claiming success, run the most relevant available build/test/lint command.

If verification cannot be run, say so honestly.

## Product direction

Do not add these unless explicitly requested:
- Electron version
- Windows app
- cloud sync
- accounts
- real-time collaboration
- plugin marketplace
- payments
- remote sandboxes

Focus on making the local Mac agent workflow excellent first.
