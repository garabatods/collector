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
- After each step, say exactly how to test it.
- Always tell the user whether the change needs a full `flutter run` restart or just `r` / hot reload.
- If the change is UI-only, explicitly recommend using Flutter hot reload to verify it instead of rebuilding.
- Only recommend a full restart or rebuild when the change affects app startup, runtime config, dependencies, native setup, or other non-UI initialization.

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
