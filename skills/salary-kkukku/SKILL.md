---
name: salary-kkukku
description: Install, launch, hide, quit, or open salary and schedule settings for the Salary Kkukku macOS earnings widget. Use when the user requests this widget or its setup; not for payroll or taxes.
---

# Salary Kkukku

A standalone Korean-language, KRW earnings widget for macOS 14+. Requires local shell execution on the user's Mac. A cloud shell cannot display this widget on their desktop. First installation compiles bundled Swift source using Apple's Command Line Tools; the app does not modify any other application. No account, API key, MCP server, or network service is needed.

Resolve the plugin root as two directories above this skill folder. Quote all paths; never embed an author-specific path. Run helpers with `bash` and an absolute script path.

## Install and start

1. Check `uname -s`, `sw_vers -productVersion`, and `xcrun --find swiftc` on the local Mac. If incompatible or unavailable, explain the exact missing requirement. If Apple's tools are missing, explain `xcode-select --install`; do not claim the widget is installed or install other software without authorization.
2. For an explicit setup/install request, run `bash "<plugin-root>/scripts/install.sh"`. It compiles both Apple Silicon and Intel slices, installs only `~/Applications/Salary Kkukku.app`, and preserves an existing app by stopping rather than overwriting it. Follow the host's normal filesystem approval rules.
3. Run `bash "<plugin-root>/scripts/control.sh" launch` when the user asks to use/start the widget or as part of requested setup. On first launch the salary form opens. New installations default to a monthly salary of KRW 3,000,000 as requested by the publisher. Saved user values, including zero, take precedence. Users can change the default in settings; never copy the author's personal settings.
4. `control.sh status` confirms process state, not visibility. Say what was actually verified. When UI tools are unavailable, ask the user to check the window instead of claiming a screenshot check.

## Existing widget

Use `bash "<plugin-root>/scripts/control.sh" ACTION`:

- `launch` / `show`: display the widget.
- `settings`: open the salary, workdays, and start/end time form.
- `hide`: hide the window without quitting.
- `quit`: quit only Salary Kkukku.
- `status`: check installation and process state without reading salary values.

The optional second argument is an explicit app path for a nonstandard installation. Do not operate on a different bundle ID. Reinstall only if requested; if an app exists, ask the user to move that specific app to Trash first. Preferences remain available to a new installation.

For a requested salary/schedule edit, open settings. If authorized UI tools are available, enter only the values the user supplied and verify saving; otherwise explain the form fields and let the user enter them. Do not fabricate completion. The form supports automatic thousands separators, weekday selection, and `HH:mm` times. A lower end time means next-day finish; `00:00–24:00` means all day. Saving recalculates the current month. No holiday or break deductions are modeled.

Right-click (or Control-click) anywhere on the widget to access the same settings and quit commands. The menu bar also has `₩`.

This is a standalone widget with its own small pigeon icon. It does not inspect other apps' windows. Users can drag it to their preferred position.

No automatic startup, login-item changes, security bypass, certificate changes, or publishing is part of installation. If macOS blocks downloaded files, report the exact block; do not remove quarantine or disable Gatekeeper. 
