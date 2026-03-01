#!/usr/bin/env bash
# =============================================================================
# defaults.sh — macOS system preferences via `defaults write`
# Run: bash ~/.dotfiles/macos/defaults.sh
# Changes take effect after logging out / restarting apps
# =============================================================================

set -euo pipefail

echo "▶ Applying macOS defaults..."

# Close System Preferences to prevent overrides
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

# ── Finder ───────────────────────────────────────────────────────────────────
echo "  › Finder"

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show path bar at bottom
defaults write com.apple.finder ShowPathbar -bool true
# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true
# Show full POSIX path in window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Keep folders on top when sorting
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
# Disable .DS_Store on network and USB
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# Show ~/Library folder
chflags nohidden ~/Library

# ── Dock ─────────────────────────────────────────────────────────────────────
echo "  › Dock"

# Auto-hide dock
defaults write com.apple.dock autohide -bool true
# Fast dock show/hide animation
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
# Icon size
defaults write com.apple.dock tilesize -int 48
# Show indicators for open apps
defaults write com.apple.dock show-process-indicators -bool true
# Don't show recent apps in Dock
defaults write com.apple.dock show-recents -bool false
# Minimize to application
defaults write com.apple.dock minimize-to-application -bool true
# Don't rearrange Spaces based on usage
defaults write com.apple.dock mru-spaces -bool false

# ── Keyboard ─────────────────────────────────────────────────────────────────
echo "  › Keyboard"

# Fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
# Disable auto-capitalize
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
# Disable period with double space
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
# Full keyboard access (tab through all controls)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# ── Trackpad ─────────────────────────────────────────────────────────────────
echo "  › Trackpad"

# Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# Tracking speed (0-3, higher = faster)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 1.5
# Natural scrolling (off = traditional)
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

# ── Screen ───────────────────────────────────────────────────────────────────
echo "  › Screen"

# Save screenshots and recordings to Downloads/Screenshots
# (run setup-captures for full setup including the Desktop watcher)
mkdir -p ~/Downloads/Screenshots
mkdir -p ~/Downloads/Screen\ Recordings
defaults write com.apple.screencapture location -string "$HOME/Downloads/Screenshots"
# Save screenshots as PNG
defaults write com.apple.screencapture type -string "png"
# Disable screenshot shadow
defaults write com.apple.screencapture disable-shadow -bool true
# Subpixel font rendering on non-Apple LCDs
defaults write NSGlobalDomain AppleFontSmoothing -int 1
# Enable HiDPI display modes
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true 2>/dev/null || true

# ── Menu Bar ─────────────────────────────────────────────────────────────────
echo "  › Menu Bar"

# Show clock with seconds
defaults write com.apple.menuextra.clock ShowSeconds -bool true
# Show battery percentage
defaults write com.apple.menuextra.battery ShowPercent -bool true

# ── Activity Monitor ──────────────────────────────────────────────────────────
echo "  › Activity Monitor"

defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor ShowCategory -int 0     # all processes
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# ── Safari ────────────────────────────────────────────────────────────────────
echo "  › Safari"

# Show full URL in address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
# Enable developer menu
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# ── TextEdit ─────────────────────────────────────────────────────────────────
echo "  › TextEdit"

# Use plain text by default
defaults write com.apple.TextEdit RichText -bool false
# Open/save files in UTF-8
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# ── App Store ─────────────────────────────────────────────────────────────────
echo "  › App Store"

# Auto-update apps
defaults write com.apple.commerce AutoUpdate -bool true

# ── Restart affected apps ─────────────────────────────────────────────────────
echo "  › Restarting affected apps..."

for app in "Finder" "Dock" "SystemUIServer" "Safari" "Activity Monitor"; do
  killall "$app" &>/dev/null || true
done

echo "✓ macOS defaults applied. Some changes require logout/restart."
