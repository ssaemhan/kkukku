# Kkukku Payday (꾸꾸 페이데이)

A small, free macOS desktop widget: an animated pigeon with a laptop sits under a two-line bubble showing your estimated earnings so far this month, based on your monthly salary, workdays and working hours. The interface is Korean and amounts are in KRW.

Estimates are for fun only. They are not actual payroll or tax advice, and no holiday or break deductions are modeled.

## What the plugin does

The plugin contains one skill, `kkukku-payday`, which lets Claude install, launch, show, hide, quit, or open the settings of the widget on your Mac. Supports overnight shifts, comma-formatted salary input, weekday selection and `HH:mm` times. New installs default to a monthly salary of KRW 3,000,000; values you save are preserved.

Example prompts:

- "Install and launch Kkukku Payday on my Mac."
- "Open my Kkukku Payday salary and schedule settings."
- "Hide my Kkukku Payday widget."

## Requirements

- macOS 14 or newer (Apple Silicon or Intel)
- Apple Command Line Tools (`xcode-select --install`), needed once to compile the app
- A Claude surface that can run shell commands on your Mac (for example Claude Code or Claude desktop with local access). A cloud-only session cannot show a widget on your desktop.

## Everything the plugin runs

All code is readable source in this folder. Nothing is downloaded and no package manager is used.

- `scripts/install.sh` compiles `src/*.swift` with `swiftc` for both Apple Silicon and Intel, and installs only `~/Applications/Kkukku Payday.app`. It stops instead of overwriting an existing app.
- `scripts/control.sh launch|show|settings|hide|quit|status` controls the installed app.
- `scripts/build.sh` and `scripts/test.sh` build the app and run the salary-calculation tests.

The plugin does not start automatically at login, change security settings, remove quarantine flags, or modify any other application.

## Privacy

Salary, schedule and position settings are stored only on your Mac. The app makes no network requests and contains no analytics. It does not read other applications' windows, images or text. The app is free, with no purchases.

Support: whosemi@gmail.com

## License

MIT. See `LICENSE`.
