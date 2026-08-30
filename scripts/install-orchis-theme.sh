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

echo "==> Downloading and building Orchis GTK theme..."
git clone --depth 1 https://github.com/vinceliuice/Orchis-theme.git "$TEMP_DIR/orchis-theme"
"$TEMP_DIR/orchis-theme/install.sh" -d "$HOME/.themes" -c dark -t default --round 4px
"$TEMP_DIR/orchis-theme/install.sh" -d "$HOME/.local/share/themes" -c dark -t default --round 4px

echo "==> Downloading and installing Tela Circle icon theme..."
git clone --depth 1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$TEMP_DIR/tela-circle"
"$TEMP_DIR/tela-circle/install.sh" -d "$HOME/.icons" standard
"$TEMP_DIR/tela-circle/install.sh" -d "$HOME/.local/share/icons" standard

echo "==> Writing GTK 3 & 4 settings..."
cat << 'GTK3_EOF' > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=Orchis-Dark
gtk-icon-theme-name=Tela-circle-dark
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
gtk-theme-name=Orchis-Dark
gtk-icon-theme-name=Tela-circle-dark
gtk-font-name=Noto Sans 10.5
gtk-application-prefer-dark-theme=1
GTK4_EOF

if command -v xfconf-query >/dev/null 2>&1; then
  echo "==> Applying XFCE settings via xfconf-query..."
  xfconf-query -c xsettings -p /Net/ThemeName -s "Orchis-Dark" || true
  xfconf-query -c xsettings -p /Net/IconThemeName -s "Tela-circle-dark" || true
  xfconf-query -c xfwm4 -p /general/theme -s "Orchis-Dark" || true
fi

echo "==> Orchis theme successfully installed and applied!"
