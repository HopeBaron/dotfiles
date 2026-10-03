// Firefox's system-colour overrides for ${THEME_LABEL}. Firefox takes its
// chrome colours from the GTK theme, but its accent (buttons, checkboxes,
// focus rings, drop indicators) and selection colours from the desktop
// portal, which has no accent to give here -- so it falls back to its own
// blue. A `ui.<system colour>` pref overrides that colour outright.
user_pref("ui.accentcolor", "#${ACCENT}");
user_pref("ui.accentcolortext", "#${ACCENT_FG}");
user_pref("ui.highlight", "#${ACCENT}");
user_pref("ui.highlighttext", "#${ACCENT_FG}");
user_pref("ui.selecteditem", "#${ACCENT}");
user_pref("ui.selecteditemtext", "#${ACCENT_FG}");
