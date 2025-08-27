#!/usr/bin/env bash
set -Eeuo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/preflight/lib.sh"

##
# This is script with useful tips taken from:
#   https://github.com/mathiasbynens/dotfiles/blob/master/.osx

info "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
dwrite NSGlobalDomain AppleKeyboardUIMode -int 3

info "Disable the 'Are you sure you want to open this application?' dialog"
dwrite com.apple.LaunchServices LSQuarantine -bool false

info "Automatically illuminate built-in MacBook keyboard in low light"
dwrite com.apple.BezelServices kDim -bool true
info "Turn off keyboard illumination when computer is not used for 5 minutes"
dwrite com.apple.BezelServices kDimTime -int 300

info "Finder: show hidden files by default"
dwrite com.apple.finder AppleShowAllFiles -bool true

info "Disable the warning when changing a file extension"
dwrite com.apple.finder FXEnableExtensionChangeWarning -bool false

info "Finder: Always open everything in column view"
dwrite com.apple.Finder FXPreferredViewStyle clmv

info "Make Dock icons of hidden applications translucent"
dwrite com.apple.dock showhidden -bool true

# Show remaining battery time; hide percentage
dwrite com.apple.menuextra.battery ShowPercent -string "NO"
dwrite com.apple.menuextra.battery ShowTime -string "YES"

info "Show all filename extensions in Finder"
dwrite NSGlobalDomain AppleShowAllExtensions -bool true

info "Use current directory as default search scope in Finder"
dwrite com.apple.finder FXDefaultSearchScope -string "SCcf"

info "Show Path bar in Finder"
dwrite com.apple.finder ShowPathbar -bool true

info "Show Status bar in Finder"
dwrite com.apple.finder ShowStatusBar -bool true

info "Expand save panel by default"
dwrite NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

info "Expand print panel by default"
dwrite NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

info "Disable shadow in screenshots"
dwrite com.apple.screencapture disable-shadow -bool true

info "Save screenshots to ~/Desktop/screenshots"
dwrite com.apple.screencapture location "$HOME/Desktop/screenshots"

info "Enable highlight hover effect for the grid view of a stack (Dock)"
dwrite com.apple.dock mouse-over-hilte-stack -bool true

info "Enable spring loading for all Dock items"
dwrite enable-spring-load-actions-on-all-items -bool true

info "Show indicator lights for open applications in the Dock"
dwrite com.apple.dock show-process-indicators -bool true

# Don’t animate opening applications from the Dock
# defaults write com.apple.dock launchanim -bool false

#info "Display ASCII control characters using caret notation in standard text views"
# Try e.g. `cd /tmp; unidecode "\x{0000}" > cc.txt; open -e cc.txt`
#dwrite NSGlobalDomain NSTextShowsControlCharacters -bool true

info "Disable press-and-hold for keys in favor of key repeat"
dwrite NSGlobalDomain ApplePressAndHoldEnabled -bool false

info "Enable AirDrop over Ethernet and on unsupported Macs running Lion"
dwrite com.apple.NetworkBrowser BrowseAllInterfaces -bool true

info "Display full POSIX path as Finder window title"
dwrite com.apple.finder _FXShowPosixPathInTitle -bool true

info "Avoid creating .DS_Store files on network volumes"
dwrite com.apple.desktopservices DSDontWriteNetworkStores -bool true

info "Disable the warning when changing a file extension"
dwrite com.apple.finder FXEnableExtensionChangeWarning -bool false

info "Show item info below desktop icons"
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" "$HOME/Library/Preferences/com.apple.finder.plist"

info "Enable snap-to-grid for desktop icons"
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" "$HOME/Library/Preferences/com.apple.finder.plist"

info "Enable backspace-as-Back-button in Safari"
dwrite com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool YES

info "Disable Safari's thumbnail cache for History and Top Sites"
dwrite com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

info "Make Safari's search banners default to Contains instead of Starts With"
dwrite com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

info "Add a context menu item for showing the Web Inspector in web views"
dwrite NSGlobalDomain WebKitDeveloperExtras -bool true

info "Disable the Ping sidebar in iTunes"
dwrite com.apple.iTunes disablePingSidebar -bool true

info "Disable all the other Ping stuff in iTunes"
dwrite com.apple.iTunes disablePing -bool true

info "Make ⌘ + F focus the search input in iTunes"
dwrite com.apple.iTunes NSUserKeyEquivalents -dict-add "Target Search Field" "@F"

info "Disable the "reopen windows when logging back in" option"
# This works, although the checkbox will still appear to be checked.
dwrite com.apple.loginwindow TALLogoutSavesState -bool false
dwrite com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false

info "Enable Dashboard dev mode (allows keeping widgets on the desktop)"
dwrite com.apple.dashboard devmode -bool true

info "Show the ~/Library folder"
chflags nohidden "$HOME/Library"

info "Disable smart quotes and smart dashes as they're annoying when typing code"
dwrite NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
dwrite NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

info "Increases the time the menu bar shows when mouse is at the top of the screen"
dwrite com.citrix.receiver.nomas MenuBarAutoShowDelayEnabled -bool YES
dwrite com.citrix.receiver.nomas MenuBarAutoShowDelay -float 3.0

killall Finder Dock SystemUIServer 2>/dev/null || true
