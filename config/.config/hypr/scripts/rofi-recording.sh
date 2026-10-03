#!/usr/bin/env bash
# Screen-recording menu, opened from the Print menu's "Record…" entry.
# Records with gpu-screen-recorder into ~/Videos/Recordings.
#
#   Start recording   record with the settings below
#   Area: ...         the focused monitor (default), a named monitor, or a
#                     dragged region
#   Audio: ...        the default output (default), None, or a specific output
#   Mic: ...          the default input (default), None, or a specific input
#
# Area / Audio / Mic each open a list and come back here; the choices are
# remembered between recordings. Escape returns to the Print menu.
#
#   rofi-recording.sh          the menu; while a recording runs, it shows
#                              Stop recording and that recording's settings
#   rofi-recording.sh stop     stop a running recording
#   rofi-recording.sh status   exit 0 if a recording is running
#
# Exits 1 when the menu is closed with Escape, so the Print menu can reopen;
# 2 when a recording failed to start (already reported in a notification).
set -euo pipefail
# shellcheck source=../../../../lib/mars.sh
. "$(dirname "$(readlink -f "$0")")/../../../../lib/mars.sh"

readonly SETTINGS_FILE="$MARS_STATE_DIR/recorder.env"
readonly PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/screen-recorder.pid"
readonly LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/screen-recorder.log"
# Same pidfile as the Print menu: that rofi has exited by the time this runs,
# and sharing it keeps this menu from colliding with another open rofi.
readonly ROFI_PID="${XDG_RUNTIME_DIR:-/tmp}/rofi-screenshot.pid"

# Prints the chosen row's index (-format i), nothing on Escape.
menu() {
  local prompt=$1; shift
  rofi -dmenu -i -p "$prompt" -format i -pid "$ROFI_PID" "$@"
}

# ---- settings ---------------------------------------------------------------
#
# recorder.env holds only the settings that were changed from their default;
# a missing key means "default". Values:
#   AREA   focused | monitor:<name> | region:<W>x<H>+<X>+<Y>
#   AUDIO  default | none | <sink name>     (recorded through its .monitor)
#   MIC    default | none | <source name>
#
# A saved monitor or device that isn't there right now (unplugged, renamed)
# falls back to the default for this recording, but stays saved -- plug it
# back in and it's used again.

readonly DEFAULT_AREA=focused DEFAULT_AUDIO=default DEFAULT_MIC=default
AREA=$DEFAULT_AREA AUDIO=$DEFAULT_AUDIO MIC=$DEFAULT_MIC

settings_load() {
  [[ -r "$SETTINGS_FILE" ]] || return 0
  local key value
  while IFS='=' read -r key value; do
    case "$key" in
      AREA)  AREA=$value ;;
      AUDIO) AUDIO=$value ;;
      MIC)   MIC=$value ;;
    esac
  done < "$SETTINGS_FILE"
}

settings_save() {
  local lines=()
  [[ "$AREA"  == "$DEFAULT_AREA"  ]] || lines+=("AREA=$AREA")
  [[ "$AUDIO" == "$DEFAULT_AUDIO" ]] || lines+=("AUDIO=$AUDIO")
  [[ "$MIC"   == "$DEFAULT_MIC"   ]] || lines+=("MIC=$MIC")
  if (( ${#lines[@]} )); then
    printf '%s\n' "${lines[@]}" > "$SETTINGS_FILE"
  else
    rm -f "$SETTINGS_FILE"
  fi
}

# "name<TAB>description" for every sink (Audio) or real input (Mic) -- the
# sinks' own .monitor sources are left out of the Mic list.
list_sinks() {
  pactl -f json list sinks | jq -r '.[] | "\(.name)\t\(.description)"'
}
list_mics() {
  pactl -f json list sources \
    | jq -r '.[] | select(.name | endswith(".monitor") | not) | "\(.name)\t\(.description)"'
}

# Description of device <name> in a list_* function's output; empty and
# non-zero when it isn't there.
#   device_desc <name> <list-function>
device_desc() {
  local desc
  desc=$("$2" | awk -F'\t' -v n="$1" '$1 == n { print $2; exit }')
  [[ -n "$desc" ]] && echo "$desc"
}

# Whether a saved area still exists: the monitor is connected, or the
# region's top-left corner lies on some connected monitor.
area_available() {
  case "$AREA" in
    monitor:*)
      hyprctl monitors -j | jq -e --arg n "${AREA#monitor:}" 'any(.[]; .name == $n)' >/dev/null ;;
    region:*)
      local g=${AREA#region:} x y
      IFS=+ read -r _ x y <<< "$g"
      hyprctl monitors -j | jq -e --argjson x "$x" --argjson y "$y" \
        'any(.[]; $x >= .x and $x < .x + (.width / .scale) and $y >= .y and $y < .y + (.height / .scale))' >/dev/null ;;
    *) return 0 ;;
  esac
}

# The values a recording uses right now: the saved ones, with anything
# unavailable replaced by its default. Sets USE_AREA / USE_AUDIO / USE_MIC.
resolve() {
  USE_AREA=$AREA USE_AUDIO=$AUDIO USE_MIC=$MIC
  area_available || USE_AREA=$DEFAULT_AREA
  case "$AUDIO" in default|none) ;; *) device_desc "$AUDIO" list_sinks >/dev/null || USE_AUDIO=$DEFAULT_AUDIO ;; esac
  case "$MIC"   in default|none) ;; *) device_desc "$MIC"   list_mics  >/dev/null || USE_MIC=$DEFAULT_MIC ;; esac
}

# Menu label for a device setting: what will be used, plus a note when a
# saved device is being stood in for.
#   device_label <saved> <in-use> <list-function> <default-label>
device_label() {
  local saved=$1 use=$2 list=$3 default_label=$4 label
  case "$use" in
    none)    label="None" ;;
    default) label=$default_label ;;
    *)       label=$(device_desc "$use" "$list") ;;
  esac
  [[ "$saved" == "$use" ]] || label+="  (saved device unplugged)"
  echo "$label"
}

area_label() {
  local label
  case "$USE_AREA" in
    monitor:*) label=${USE_AREA#monitor:} ;;
    region:*)
      local g=${USE_AREA#region:} size pos
      size=${g%%+*} pos=${g#*+}
      label="Region ${size/x/×} at ${pos/+/,}" ;;
    *) label="Focused monitor" ;;
  esac
  [[ "$AREA" == "$USE_AREA" ]] || label+="  (saved area not found)"
  echo "$label"
}

# Each list sets its setting and saves it; Escape leaves it unchanged.
area_menu() {
  local names=() labels=() i
  mapfile -t names < <(hyprctl monitors -j | jq -r '.[].name')
  labels=("󰍹  Focused monitor")
  for i in "${names[@]}"; do labels+=("󰍹  $i"); done
  labels+=("󰩬  Select region…")
  i=$(printf '%s\n' "${labels[@]}" | menu "Area") || return 0
  [[ -n "$i" ]] || return 0
  if (( i == 0 )); then
    AREA=focused
  elif (( i <= ${#names[@]} )); then
    AREA="monitor:${names[i-1]}"
  else
    local g
    g=$(slurp -f '%wx%h+%x+%y') || return 0
    AREA="region:$g"
  fi
  settings_save
}

# Audio and Mic share one shape: the system default, None, then each device.
#   device_menu <prompt> <list-function> <default-label> <variable-name>
device_menu() {
  local prompt=$1 list=$2 default_label=$3
  local -n target=$4
  local names=() descs=() name desc i
  while IFS=$'\t' read -r name desc; do
    names+=("$name") descs+=("$desc")
  done < <("$list")
  i=$( { printf '%s\n' "$default_label" "None"; printf '%s\n' "${descs[@]}"; } | menu "$prompt") || return 0
  [[ -n "$i" ]] || return 0
  case "$i" in
    0) target=default ;;
    1) target=none ;;
    *) target=${names[i-2]} ;;
  esac
  settings_save
}

# ---- recording --------------------------------------------------------------

recording_pid() {
  local pid
  pid=$(head -n1 "$PID_FILE" 2>/dev/null) || return 1
  # comm is cut to 15 chars; checking it guards against a recycled PID.
  [[ -n "$pid" && "$(cat "/proc/$pid/comm" 2>/dev/null)" == gpu-screen-reco* ]] || return 1
  echo "$pid"
}

record_start() {
  local window audio=() audio_args=() outdir file pid
  resolve
  case "$USE_AREA" in
    monitor:*) window=(-w "${USE_AREA#monitor:}") ;;
    region:*)  window=(-w region -region "${USE_AREA#region:}") ;;
    *)         window=(-w "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')") ;;
  esac

  # Desktop audio and mic go into one mixed track: gpu-screen-recorder merges
  # every source given in a single -a, separated by "|".
  case "$USE_AUDIO" in
    none) ;;
    default) audio+=(default_output) ;;
    *) audio+=("device:$USE_AUDIO.monitor") ;;
  esac
  case "$USE_MIC" in
    none) ;;
    default) audio+=(default_input) ;;
    *) audio+=("device:$USE_MIC") ;;
  esac
  (( ${#audio[@]} )) && audio_args=(-a "$(IFS='|'; echo "${audio[*]}")")

  outdir="$(user_dir VIDEOS "$HOME/Videos")/Recordings"
  mkdir -p "$outdir"
  file="$outdir/Recording_$(date +%F_%H-%M-%S).mp4"

  # setsid: the recorder must outlive this script and the Print keypress.
  setsid gpu-screen-recorder "${window[@]}" -f 60 "${audio_args[@]}" -o "$file" \
    > "$LOG_FILE" 2>&1 < /dev/null &
  pid=$!
  # pid, file, start time, then the three menu labels it was started with --
  # the menu shows these while it runs, not whatever is saved now.
  printf '%s\n' "$pid" "$file" "$(date +%s)" \
    "$(area_label)" \
    "$(device_label "$AUDIO" "$USE_AUDIO" list_sinks "Default output")" \
    "$(device_label "$MIC" "$USE_MIC" list_mics "Default input")" > "$PID_FILE"

  # A bad area or device fails within a moment; say so instead of leaving a
  # recording that never started.
  sleep 1
  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PID_FILE"
    notify "Screen recorder" "Recording failed to start" "$(tail -n 3 "$LOG_FILE")"
    return 1
  fi
  notify "Screen recorder" "Recording started" "Press Print to stop"
}

record_stop() {
  local pid file
  pid=$(recording_pid) || return 0
  file=$(sed -n 2p "$PID_FILE")
  # SIGINT, not TERM: gpu-screen-recorder finalizes the file on it.
  kill -INT "$pid"
  for _ in {1..50}; do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1
  done
  rm -f "$PID_FILE"
  notify "Screen recorder" "Recording saved" "$file"
}

# ---- menu -------------------------------------------------------------------

main_menu() {
  settings_load
  local selected=0 labels actions i
  while true; do
    local mesg_args=()
    if recording_pid >/dev/null; then
      # The running recording's own settings, read-only until it stops.
      local info=() elapsed
      mapfile -t info < "$PID_FILE"
      elapsed=$(( $(date +%s) - ${info[2]:-$(date +%s)} ))
      labels=("󰓛  Stop recording"
              "󰍹  Area: ${info[3]:-?}"
              "󰕾  Audio: ${info[4]:-?}"
              "󰍬  Mic: ${info[5]:-?}")
      actions=(stop - - -)
      mesg_args=(-mesg "$(printf 'Recording for <b>%d:%02d</b> -- settings can be changed once it stops' \
        $(( elapsed / 60 )) $(( elapsed % 60 )))")
    else
      resolve
      labels=("󰑊  Start recording"
              "󰍹  Area: $(area_label)"
              "󰕾  Audio: $(device_label "$AUDIO" "$USE_AUDIO" list_sinks "Default output")"
              "󰍬  Mic: $(device_label "$MIC" "$USE_MIC" list_mics "Default input")")
      actions=(start area audio mic)
    fi

    i=$(printf '%s\n' "${labels[@]}" | menu "Record" -selected-row "$selected" \
      "${mesg_args[@]}" \
      -theme-str "window { width: 520px; } listview { lines: ${#labels[@]}; }") || true
    [[ -n "${i:-}" ]] || exit 1

    selected=$i
    case "${actions[i]}" in
      start) record_start || exit 2; exit 0 ;;
      stop)  record_stop; exit 0 ;;
      area)  area_menu ;;
      audio) device_menu "Audio" list_sinks "Default output" AUDIO ;;
      mic)   device_menu "Mic" list_mics "Default input" MIC ;;
      -)     ;;   # a read-only row of the running recording
    esac
  done
}

case "${1:-}" in
  "")     main_menu ;;
  stop)   record_stop ;;
  status) recording_pid >/dev/null ;;
  *) echo "usage: $(basename "$0") [stop|status]" >&2; exit 2 ;;
esac
