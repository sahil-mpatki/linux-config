#!/bin/bash
# setup-macos-look.sh — macOS-style dock (Plank) + top panel for XFCE with Gruvbox

set -e

echo "==> Setting up macOS-style dock and top panel..."

# ── 1. Install Plank if not present ─────────────────────────────────
if ! command -v plank &>/dev/null; then
    echo "Installing Plank..."
    sudo apt install -y plank
fi

# ── 2. Configure Plank dock ──────────────────────────────────────────
PLANK_CFG="$HOME/.config/plank/dock1"
mkdir -p "$PLANK_CFG/launchers"

cat > "$PLANK_CFG/settings" << 'EOF'
[PlankDockPreferences]
Alignment=3
AutoPinning=true
CurrentWorkspaceOnly=false
DockItems=firefox.dockitem;thunar.dockitem;xfce4-terminal.dockitem;
FadeOpacity=1
FadeTime=250
HideDelay=0
HideMode=1
IconSize=48
IndicatorStyle=1
ItemMoveTime=450
LockItems=false
Monitor=
Offset=0
PinningMode=1
Position=3
PressureReveal=false
ShowDockItem=false
Theme=Transparent
TooltipTime=500
ZoomEnabled=true
ZoomPercent=130
EOF

# Default launchers
for app in firefox thunar xfce4-terminal; do
    desktop="/usr/share/applications/${app}.desktop"
    [ -f "$desktop" ] || desktop="/usr/share/applications/${app}-esr.desktop"
    cat > "$PLANK_CFG/launchers/${app}.dockitem" << DOCKEOF
[PlankDockItemPreferences]
Launcher=file://${desktop}
DOCKEOF
done

# ── 3. Autostart Plank on login ──────────────────────────────────────
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/plank.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Comment=macOS-style dock
Exec=plank
Icon=plank
X-GNOME-Autostart-enabled=true
EOF

# ── 4. XFCE panel already updated to top bar via xfce4-panel.xml ────
echo "Panel config already applied in xfce4-panel.xml"

# ── 5. Reload XFCE panel ────────────────────────────────────────────
if pgrep -x xfce4-panel &>/dev/null; then
    xfce4-panel --restart &
    echo "Panel restarted."
fi

# ── 6. Launch Plank (if not already running) ─────────────────────────
if ! pgrep -x plank &>/dev/null; then
    plank &
    echo "Plank launched."
fi

echo "Done! macOS-style look applied."
echo "Note: If the panel layout looks off, log out and back in."
