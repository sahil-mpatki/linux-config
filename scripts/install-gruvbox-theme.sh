#!/usr/bin/env bash
set -euo pipefail

# Ensure target directories exist
mkdir -p "$HOME/.themes" "$HOME/.icons" "$HOME/.local/share/themes" "$HOME/.local/share/icons" \
         "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.local/bin"

echo "==> Setting up Sass compiler..."
if ! command -v sassc >/dev/null 2>&1; then
  if ! command -v sass >/dev/null 2>&1; then
    if command -v npm >/dev/null 2>&1; then
      echo "Installing sass via npm..."
      npm install -g sass
    else
      echo "Error: sassc or npm/sass is required to compile GTK theme." >&2
      exit 1
    fi
  fi

  # Create sassc wrapper in ~/.local/bin if needed
  cat << 'WRAPPER_EOF' > "$HOME/.local/bin/sassc"
#!/usr/bin/env bash
input=""
output=""
skip_next=false
for arg in "$@"; do
  if [ "$skip_next" = true ]; then
    skip_next=false
    continue
  fi
  case "$arg" in
    -t) skip_next=true ;;
    -M) ;;
    *)
      if [ -z "$input" ]; then
        input="$arg"
      elif [ -z "$output" ]; then
        output="$arg"
      fi
      ;;
  esac
done
if [ -n "$input" ] && [ -n "$output" ]; then
  exec sass --no-source-map --style=expanded "$input" "$output"
elif [ -n "$input" ]; then
  exec sass --no-source-map --style=expanded "$input"
else
  exec sass "$@"
fi
WRAPPER_EOF
  chmod +x "$HOME/.local/bin/sassc"
fi

export PATH="$HOME/.local/bin:$PATH"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "==> Downloading and building Gruvbox GTK theme..."
git clone --depth 1 https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git "$TEMP_DIR/gruvbox-gtk"
"$TEMP_DIR/gruvbox-gtk/themes/install.sh" -d "$HOME/.themes" -t default -c dark
"$TEMP_DIR/gruvbox-gtk/themes/install.sh" -d "$HOME/.local/share/themes" -t default -c dark

echo "==> Downloading and installing Gruvbox Plus icon pack..."
LATEST_ICON_ZIP_URL=$(curl -s https://api.github.com/repos/SylEleuth/gruvbox-plus-icon-pack/releases/latest | grep "browser_download_url.*zip" | cut -d '"' -f 4)
if [ -n "$LATEST_ICON_ZIP_URL" ]; then
  curl -L -o "$TEMP_DIR/gruvbox-plus.zip" "$LATEST_ICON_ZIP_URL"
  unzip -qo "$TEMP_DIR/gruvbox-plus.zip" -d "$HOME/.icons/"
  if [ -d "$HOME/.icons/Gruvbox-Plus-Dark" ]; then
    cp -r "$HOME/.icons/Gruvbox-Plus-Dark" "$HOME/.local/share/icons/"
  fi
fi

echo "==> Writing GTK 3 & 4 settings..."
cat << 'GTK3_EOF' > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=Gruvbox-Dark
gtk-icon-theme-name=Gruvbox-Plus-Dark
gtk-font-name=Noto Sans 10.5
gtk-cursor-theme-name=
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
GTK3_EOF

cat << 'GTK4_EOF' > "$HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-theme-name=Gruvbox-Dark
gtk-icon-theme-name=Gruvbox-Plus-Dark
gtk-font-name=Noto Sans 10.5
gtk-application-prefer-dark-theme=1
GTK4_EOF

if command -v xfconf-query >/dev/null 2>&1; then
  echo "==> Applying XFCE settings via xfconf-query..."
  xfconf-query -c xsettings -p /Net/ThemeName -s "Gruvbox-Dark" || true
  xfconf-query -c xsettings -p /Net/IconThemeName -s "Gruvbox-Plus-Dark" || true
  xfconf-query -c xfwm4 -p /general/theme -s "Gruvbox-Dark" || true
fi

echo "==> Gruvbox theme successfully installed and applied!"
