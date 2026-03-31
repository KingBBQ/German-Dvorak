#!/bin/bash
#
# Install script for German Dvorak keyboard layout on Arch/Manjaro Linux
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XKB_DIR="/usr/share/X11/xkb"
SYMBOLS_SRC="${SCRIPT_DIR}/symbols/de_Dvorak"
SYMBOLS_DST="${XKB_DIR}/symbols/de_Dvorak"
EVDEV_XML="${XKB_DIR}/rules/evdev.xml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Checks ---

if [[ $EUID -ne 0 ]]; then
    error "Dieses Script muss als root ausgefuehrt werden (sudo ./install-arch.sh)"
fi

if [[ ! -f "$SYMBOLS_SRC" ]]; then
    error "Symbol-Datei nicht gefunden: ${SYMBOLS_SRC}"
fi

if [[ ! -f "$EVDEV_XML" ]]; then
    error "evdev.xml nicht gefunden: ${EVDEV_XML}"
fi

# --- Install symbols file ---

info "Kopiere Symbol-Datei nach ${SYMBOLS_DST} ..."
cp "$SYMBOLS_SRC" "$SYMBOLS_DST"
chmod 644 "$SYMBOLS_DST"

# --- Patch evdev.xml ---

if grep -q '<name>de_Dvorak</name>' "$EVDEV_XML"; then
    info "de_Dvorak Eintrag existiert bereits in evdev.xml, ueberspringe."
else
    info "Erstelle Backup: ${EVDEV_XML}.bak"
    cp "$EVDEV_XML" "${EVDEV_XML}.bak"

    info "Fuege de_Dvorak Layout in evdev.xml ein ..."

    LAYOUT_ENTRY='    <layout>\
      <configItem>\
        <name>de_Dvorak</name>\
        <!-- Keyboard indicator for German layouts -->\
        <shortDescription>de_Dvorak</shortDescription>\
        <description>German Dvorak KingBBQ</description>\
        <languageList>\
          <iso639Id>deu</iso639Id>\
        </languageList>\
      </configItem>\
      <variantList />\
    </layout>\
'

    # Insert before </layoutList>
    sed -i "/<\/layoutList>/i\\${LAYOUT_ENTRY}" "$EVDEV_XML"

    if grep -q '<name>de_Dvorak</name>' "$EVDEV_XML"; then
        info "evdev.xml erfolgreich aktualisiert."
    else
        error "evdev.xml konnte nicht aktualisiert werden!"
    fi
fi

# --- Summary ---

echo ""
info "Installation abgeschlossen!"
echo ""
echo "Naechste Schritte:"
echo ""
echo "  Wayland (GNOME):"
echo "    1) Layout aktivieren:"
echo "       gsettings set org.gnome.desktop.input-sources sources \"[('xkb', 'de_Dvorak')]\""
echo ""
echo "    2) Oder als zusaetzliches Layout (mit Umschaltung):"
echo "       gsettings set org.gnome.desktop.input-sources sources \"[('xkb', 'de_Dvorak'), ('xkb', 'de')]\""
echo ""
echo "    3) Alternativ ueber GNOME Einstellungen -> Tastatur -> Eingabequellen"
echo "       (suche nach 'German Dvorak KingBBQ')"
echo ""
echo "  X11:"
echo "    1) Layout aktivieren:"
echo "       localectl set-x11-keymap de_Dvorak"
echo ""
echo "    2) Zum Testen ohne Neustart:"
echo "       setxkbmap de_Dvorak"
echo ""
