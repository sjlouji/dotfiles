#!/usr/bin/env bash
# =============================================================================
# move-captures.sh — Move screenshots and recordings from Desktop to Downloads
#
# Called by the LaunchAgent whenever files are added to ~/Desktop.
# Runs silently in the background — no output unless VERBOSE=1.
# =============================================================================

SCREENSHOTS_DIR="$HOME/Downloads/Screenshots"
RECORDINGS_DIR="$HOME/Downloads/Screen Recordings"
DESKTOP="$HOME/Desktop"

mkdir -p "$SCREENSHOTS_DIR" "$RECORDINGS_DIR"

move_file() {
  local file="$1"
  local dest="$2"
  local name
  name=$(basename "$file")

  # Avoid collision — append timestamp if file already exists
  if [[ -e "$dest/$name" ]]; then
    local base="${name%.*}"
    local ext="${name##*.}"
    name="${base}_$(date +%H%M%S).${ext}"
  fi

  mv "$file" "$dest/$name"
  [[ "${VERBOSE:-0}" == "1" ]] && echo "  Moved: $name → $dest"
}

# ── Screenshots (PNG files matching macOS naming pattern) ─────────────────────
# macOS names them: "Screenshot 2024-01-15 at 10.30.45.png"
while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  move_file "$file" "$SCREENSHOTS_DIR"
done < <(find "$DESKTOP" -maxdepth 1 \
  \( -name "Screenshot*.png" -o -name "Screen Shot*.png" \) \
  -newer "$DESKTOP" -print0 2>/dev/null)

# ── Screen recordings (MOV/MP4 from Screenshot app or QuickTime) ──────────────
# macOS names them: "Screen Recording 2024-01-15 at 10.30.45.mov"
while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  move_file "$file" "$RECORDINGS_DIR"
done < <(find "$DESKTOP" -maxdepth 1 \
  \( -name "Screen Recording*.mov" \
    -o -name "Screen Recording*.mp4" \
    -o -name "Recording*.mov" \
    -o -name "Capture*.mov" \) \
  -newer "$DESKTOP" -print0 2>/dev/null)

# ── Loom downloads (if saved to Desktop) ─────────────────────────────────────
while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  move_file "$file" "$RECORDINGS_DIR"
done < <(find "$DESKTOP" -maxdepth 1 \
  -name "Loom*.mp4" \
  -newer "$DESKTOP" -print0 2>/dev/null)
