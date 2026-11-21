#!/bin/bash
set -euo pipefail
command_name="${1:-status}"
case "$command_name" in launch|settings|show|hide|quit|status) ;; *) echo 'Usage: control.sh launch|settings|show|hide|quit|status [app-path]' >&2; exit 2;; esac
app_path="${2:-$HOME/Applications/Salary Kkukku.app}"
if [[ ! -d "$app_path" ]]; then echo 'Salary Kkukku is not installed at the specified path.' >&2; exit 1; fi
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist")"
if [[ "$bundle_id" != app.salary.kkukku ]]; then echo 'Unexpected app bundle; refusing to operate.' >&2; exit 1; fi
running=false
if [[ "$command_name" == status || "$command_name" == quit || "$command_name" == hide ]]; then
if pgrep -x SalaryKkukku >/dev/null; then
  running=true
else
  process_status=$?
  if [[ "$process_status" -ne 1 ]]; then
    echo 'Unable to inspect app process state in this environment.' >&2
    exit "$process_status"
  fi
fi
fi
case "$command_name" in
  status) printf 'Installed: %s\n' "$app_path"; if [[ "$running" == true ]]; then echo 'Process: running (window visibility not verified)'; else echo 'Process: stopped'; fi ;;
  launch) open "$app_path" ;;
  quit|hide)
    if [[ "$running" == true ]]; then open -a "$app_path" "salary-kkukku://$command_name"; else echo 'Already stopped.'; fi ;;
  settings|show) open -a "$app_path" "salary-kkukku://$command_name" ;;
esac
