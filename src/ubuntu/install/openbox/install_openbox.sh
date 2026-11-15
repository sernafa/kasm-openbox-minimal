#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

disable_epel_nss_wrapper_that_breaks_firefox() {
  yum-config-manager --setopt=epel.exclude=nss_wrapper --save
}

replace_default_xinit() {

  mkdir -p /etc/X11/xinit
  cat >/etc/X11/xinit/xinitrc <<EOL
#!/bin/sh
for file in /etc/X11/xinit/xinitrc.d/* ; do
        . \$file
done
. /etc/X11/Xsession
EOL

chmod +x /etc/X11/xinit/xinitrc
}

replace_default_99x11_common_start() {
  if [ -f /etc/X11/Xsession.d/99x11-common_start ] ; then
    cat >/etc/X11/Xsession.d/99x11-common_start <<EOL
# This file is sourced by Xsession(5), not executed.
# exec $STARTUP
EOL
  fi
}

echo "Install Openbox UI components"

if [[ "$DISTRO" = @(ubuntu|debian) ]]; then
  apt-get install -y x11-utils
  apt-get install -y --no-install-recommends \
    curl \
    dbus-x11 \
    elementary-xfce-icon-theme \
    fonts-dejavu-core \
    fonts-noto-core \
    gir1.2-keybinder-3.0 \
    gir1.2-notify-0.7 \
    hicolor-icon-theme \
    openbox \
    rofi \
    terminator \
    x11-xserver-utils \
    xclip \
    xterm \
    xfce4-clipman \
    xfconf \
    tint2
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen

  # Make terminator the default terminal emulator; the Openbox root menu's
  # "Terminal emulator" entry executes x-terminal-emulator
  update-alternatives --set x-terminal-emulator /usr/bin/terminator

  # Put xfconfd on PATH so the session autostart can launch it for xfce4-clipman
  ln -sf /usr/lib/*/xfce4/xfconf/xfconfd /usr/local/bin/xfconfd

  # terminator system-wide config: without the file terminator logs a
  # read error on startup; the profile keeps the Noto system font
  mkdir -p /etc/xdg/terminator
  cat >/etc/xdg/terminator/config <<EOL
[global_config]
[keybindings]
[profiles]
  [[default]]
    use_system_font = False
    font = Noto Mono 10
EOL

  # Icon theme for systray apps (xfce4-clipman): without it GTK falls back
  # to a dark glyph invisible on the dark tint2 panel. There is no
  # XSettings manager, so GTK reads this file directly
  mkdir -p /etc/gtk-3.0
  cat >/etc/gtk-3.0/settings.ini <<EOL
[Settings]
gtk-icon-theme-name = elementary-xfce
EOL

  # Prefer Noto for generic font families (system default font).
  # Must load BEFORE Debian's 60-latin.conf: fontconfig honors the first
  # <prefer> rule loaded for a generic family, and 60-latin.conf puts
  # DejaVu Sans Mono first for monospace.
  cat >/etc/fonts/conf.d/59-noto-defaults.conf <<EOL
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>sans-serif</family>
    <prefer><family>Noto Sans</family></prefer>
  </alias>
  <alias>
    <family>serif</family>
    <prefer><family>Noto Serif</family></prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer><family>Noto Mono</family></prefer>
  </alias>
</fontconfig>
EOL
elif [ "$DISTRO" = "alpine" ]; then
  apk add --no-cache \
    curl \
    dbus-x11 \
    font-dejavu \
    gvfs \
    mesa \
    mesa-dri-gallium \
    mesa-gl \
    openbox \
    tint2 \
    xterm
fi

if [ "$DISTRO" != "alpine" ]; then
  replace_default_xinit
fi

cat >/usr/bin/desktop_ready <<EOL
#!/usr/bin/env bash
until pids=\$(pidof \${START_DE}); do sleep .5; done
EOL
chmod +x /usr/bin/desktop_ready

# Support desktop icon trust
cat >>/etc/xdg/autostart/desktop-icons.desktop<<EOL
[Desktop Entry]
Type=Application
Name=Desktop Icon Trust
Exec=/dockerstartup/trustdesktop.sh
EOL
chmod +x /etc/xdg/autostart/desktop-icons.desktop

