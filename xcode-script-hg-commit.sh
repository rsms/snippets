#!/bin/sh
path="%%%{PBXFilePath}%%%"
dir="$(dirname "$path")"
filename="$(basename "$path")"
TM_SUPPORT_PATH="$(echo 'POSIX path of (path to application "TextMate")'|osascript)Contents/SharedSupport/Support"

cd "$dir"

r=$(TM_SUPPORT_PATH="$TM_SUPPORT_PATH" "$TM_SUPPORT_PATH/bin/CommitWindow.app/Contents/MacOS/CommitWindow" --diff-cmd "/usr/local/bin/hg,diff" "$filename")

if (echo "$r" | grep 'commit window: cancel' >/dev/null); then
  exit 0
else
  sh -c "hg --verbose commit $r"
  exit $?
fi