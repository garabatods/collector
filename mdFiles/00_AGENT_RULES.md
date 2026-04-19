# Collector App — Agent Rules

You are helping build **Collector App**, a Flutter mobile app in VS Code with Supabase as the backend.

## Working rules
- Work step by step.
- Do not jump ahead.
- Do not refactor unrelated files.
- Before making changes, explain the plan briefly.
- Keep the architecture simple and production-friendly.
- Use Flutter best practices.
- Use Supabase for auth, database, and storage.
- Do not create extra features unless explicitly requested.
- If a database migration is needed, generate the SQL clearly and explain what it does.
- Prefer small, reviewable changes.
- Do not patch UI repeatedly with tiny local tweaks by default. First judge whether the request is truly small; if the issue affects hierarchy, spacing, typography, repeated copy, or a reused pattern, prefer a proper component-level redesign or cleanup instead of stacking one-off patches.
- If the user asks to push, publish, or prepare a commit/PR, always check `git status` first for personal, machine-specific, signing, credential, or generated files that should not be committed. Do this even if the user forgets to ask.
- After each step, say exactly how to test it.
- Always tell the user whether the change needs a full `flutter run` restart or just `r` / hot reload.
- If the change is UI-only, explicitly recommend using Flutter hot reload to verify it instead of rebuilding.
- If a change can be verified with a simple Flutter hot reload, perform that hot reload automatically after finishing the change unless the user says not to.
- Only recommend a full restart or rebuild when the change affects app startup, runtime config, dependencies, native setup, or other non-UI initialization.
- For archive and collection-facing read surfaces, default to the local-first architecture documented in `mdFiles/07_LOCAL_FIRST_ARCHITECTURE_RULES.md`.
- Do not introduce new remote-first browse screens by default.

## Product guardrails
- This is **not** just an inventory utility.
- The product should feel modern, visual, and collector-first.
- Prioritize mobile UX over admin-style complexity.
- Favor low-friction data entry.
- A quick-add approach is preferred over forcing the user to fill every field.
- Photos and collection presentation matter.

## Current direction
- Tech stack: Flutter + Supabase
- Target platforms: Android first, then iOS
- IDE: VS Code
- Initial scope: MVP with enough polish to feel premium
