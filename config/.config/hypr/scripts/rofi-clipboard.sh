#!/usr/bin/env bash
# Clipboard history with pins using cliphist, wl-clipboard, and rofi.

set -euo pipefail

# Configuration & Constants
readonly US=$'\x1f' # Field separator (Unit Separator ASCII 0x1F)
readonly PIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cliphist/pins"
readonly FOOTER='<b>Enter</b> copy   <b>Alt+p</b> pin/unpin   <b>Alt+d</b> delete   <b>Alt+w</b> wipe'

mkdir -p "$PIN_DIR"

# Desktop Notification Helper
note() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a clipboard "$1" "${2:-}"
  fi
}

# True when a row's (possibly cliphist-truncated, "…"-suffixed) preview is a
# prefix of the current clipboard, normalized the same way cliphist itself
# does (whitespace/newlines collapsed to single spaces, leading one trimmed).
# A straight equality check doesn't work: cliphist's own preview is cut much
# shorter than our 200-char truncation and ends in "…", so it never equals
# the fuller string outright.
matches_current() {
  local preview=$1
  [[ -n "$current" && "$current" == "${preview%…}"* ]]
}

# Load and merge pinned clips and cliphist items into unified menu rows
collect_rows() {
  local n=0 file id preview line mark
  local current
  # A non-text clipboard (e.g. an image) just never matches.
  current=$(wl-paste 2>/dev/null | tr -s '[:space:]' ' ' | sed 's/^ //' | head -c 200 || true)
  declare -A pinned=()

  # 1. Collect Pinned Clips (Processed first to avoid duplicates)
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    id=$(basename "$file" .txt)
    preview=$(head -c 200 "$file")
    pinned["$preview"]=1

    n=$((n + 1))
    mark=" "; matches_current "$preview" && mark="●"
    printf 'pin%s%s%s%s %d  󰐃 %s\n' "$US" "$id" "$US" "$mark" "$n" "$preview"
  done < <(ls -t "$PIN_DIR"/*.txt 2>/dev/null || true)

  # 2. Collect Regular Clipboard History
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    preview=${line#*	} # Strip cliphist ID before tab
    [[ -n "${pinned["$preview"]:-}" ]] && continue # Skip if already shown as a pin

    n=$((n + 1))
    mark=" "; matches_current "$preview" && mark="●"
    printf 'hist%s%s%s%s %d  %s\n' "$US" "$line" "$US" "$mark" "$n" "$preview"
  done < <(cliphist list 2>/dev/null || true)
}

# Fetch raw payload bytes
payload_of() {
  local kind=$1 key=$2
  if [[ "$kind" == "pin" ]]; then
    cat "$PIN_DIR/$key.bin"
  else
    printf '%s' "$key" | cliphist decode
  fi
}

# Copy entry to clipboard
copy_entry() {
  local kind=$1 key=$2 mime="text/plain"
  if [[ "$kind" == "pin" && -r "$PIN_DIR/$key.mime" ]]; then
    mime=$(cat "$PIN_DIR/$key.mime")
  fi
  payload_of "$kind" "$key" | wl-copy --type "$mime"
}

# Unpin item and preserve in history if missing
unpin() {
  local key=$1 preview
  preview=$(cat "$PIN_DIR/$key.txt" 2>/dev/null || true)
  
  if [[ -n "$preview" ]] && ! cliphist list | grep -qF -- "$preview"; then
    cliphist store < "$PIN_DIR/$key.bin"
  fi
  
  rm -f "$PIN_DIR/$key".{bin,mime,txt}
  note "Unpinned" "Kept in history"
}

# Toggle pin status
toggle_pin() {
  local kind=$1 key=$2 tmp id
  if [[ "$kind" == "pin" ]]; then
    unpin "$key"
    return
  fi

  tmp=$(mktemp)
  trap 'rm -f "$tmp"' RETURN
  
  payload_of "$kind" "$key" > "$tmp"
  id=$(sha256sum "$tmp" | cut -c1-12)

  if [[ -e "$PIN_DIR/$id.bin" ]]; then
    note "Already pinned"
    return
  fi

  cp "$tmp" "$PIN_DIR/$id.bin"
  file -b --mime-type "$tmp" > "$PIN_DIR/$id.mime"
  printf '%s' "${key#*	}" > "$PIN_DIR/$id.txt"
  note "Pinned"
}

# Remove pin or standard history item
delete_entry() {
  local kind=$1 key=$2 preview
  if [[ "$kind" == "pin" ]]; then
    preview=$(cat "$PIN_DIR/$key.txt" 2>/dev/null || true)
    rm -f "$PIN_DIR/$key".{bin,mime,txt}
    if [[ -n "$preview" ]]; then
      cliphist list | grep -F -- "$preview" | cliphist delete 2>/dev/null || true
    fi
  else
    printf '%s' "$key" | cliphist delete
  fi
  note "Deleted"
}

# Wipe history with confirmation dialog
wipe_history() {
  local ans
  ans=$(printf 'No, keep it\nYes, wipe history\n' \
        | rofi -dmenu -i -p "Wipe history?" -mesg "Pins are kept" \
               -theme-str 'window { width: 360px; } listview { lines: 2; }') || return 0
  
  if [[ "$ans" == "Yes, wipe history" ]]; then
    cliphist wipe
    note "History wiped" "Pins kept"
  fi
}

# Main Interactive Loop
main() {
  local rows choice rc row kind key

  while true; do
    rows=$(collect_rows)
    if [[ -z "$rows" ]]; then
      note "Clipboard is empty"
      exit 0
    fi

    # Render Rofi launcher with custom keybindings attached
    set +e
    choice=$(printf '%s\n' "$rows" \
             | cut -d"$US" -f3 \
             | rofi -dmenu -i -p "Clipboard" -mesg "$FOOTER" \
                    -kb-custom-1 "Alt+p" \
                    -kb-custom-2 "Alt+d" \
                    -kb-custom-3 "Alt+w" \
                    -theme-str 'window { width: 650px; } listview { lines: 10; }')
    rc=$?
    set -e

    # Exit if escape pressed or menu closed
    [[ -z "${choice:-}" ]] && exit 0

    # Extract matching row data using native Bash parsing
    row=$(printf '%s\n' "$rows" | grep -F "$US$choice" | head -n1)
    [[ -z "$row" ]] && exit 0

    kind="${row%%"$US"*}"
    key="${row#*"$US"}"
    key="${key%%"$US"*}"

    # Action routing based on Rofi exit status code
    case "$rc" in
      0)  copy_entry "$kind" "$key"; exit 0 ;; # Enter
      10) toggle_pin "$kind" "$key" ;;         # Alt+p
      11) delete_entry "$kind" "$key" ;;       # Alt+d
      12) wipe_history ;;                      # Alt+w
      *)  exit 0 ;;
    esac
  done
}

main "$@"
