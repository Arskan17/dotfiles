#!/usr/bin/env bash
# Shell suggestions setup: ble.sh (fish-style autosuggestions), fzf (Ctrl-R),
# large shared history, prefix history search on Up/Down.
#
#   curl -fsSL https://raw.githubusercontent.com/Arskan17/dotfiles/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/Arskan17/dotfiles/main/install.sh | bash -s -- --uninstall
#
# Idempotent: safe to re-run; it refreshes its own marked blocks in ~/.bashrc and ~/.inputrc.
# Everything is wrapped in main() so a partially downloaded script never runs.

set -euo pipefail

main() {
  local REPO_RAW="${DOTFILES_RAW:-https://raw.githubusercontent.com/Arskan17/dotfiles/main}"
  local BLESH_URL="${BLESH_URL:-https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz}"
  local BLESH_DIR="$HOME/.local/share/blesh"
  local CONF_DIR="$HOME/.config/dotfiles"
  local BIN_DIR="$HOME/.local/bin"
  local BASHRC="$HOME/.bashrc"
  local INPUTRC="$HOME/.inputrc"

  info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
  warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
  die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

  # Remove a "# >>> dotfiles NAME >>>" ... "# <<< dotfiles NAME <<<" block from a file
  strip_block() {
    local file="$1" name="$2"
    [ -f "$file" ] || return 0
    awk -v s="# >>> dotfiles $name >>>" -v e="# <<< dotfiles $name <<<" '
      $0 == s { skip = 1; next }
      $0 == e { skip = 0; next }
      !skip' "$file" > "$file.tmp.$$" && cat "$file.tmp.$$" > "$file" && rm -f "$file.tmp.$$"
  }

  pkg_hint() {
    if   command -v apt-get >/dev/null; then echo "sudo apt-get install -y $*"
    elif command -v dnf     >/dev/null; then echo "sudo dnf install -y $*"
    elif command -v pacman  >/dev/null; then echo "sudo pacman -S --needed $*"
    elif command -v zypper  >/dev/null; then echo "sudo zypper install -y $*"
    elif command -v apk     >/dev/null; then echo "sudo apk add $*"
    else echo "install: $*"; fi
  }

  # ---------- uninstall ----------
  if [ "${1-}" = "--uninstall" ]; then
    info "Removing managed blocks from $BASHRC and $INPUTRC"
    strip_block "$BASHRC" "ble.sh"
    strip_block "$BASHRC" "main"
    strip_block "$INPUTRC" "inputrc"
    rm -rf "$BLESH_DIR" "$CONF_DIR"
    info "Uninstalled (fzf left in place). Open a new shell."
    return 0
  fi

  # ---------- preflight ----------
  local missing=() c
  for c in curl tar xz awk; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
  if [ "${#missing[@]}" -gt 0 ]; then
    # xz is packaged as xz-utils on Debian/Ubuntu
    local pkgs="${missing[*]}"
    command -v apt-get >/dev/null && pkgs="${pkgs/xz/xz-utils}"
    die "missing: ${missing[*]}. Install with: $(pkg_hint "$pkgs")"
  fi

  TMP="$(mktemp -d)"  # global: the EXIT trap runs after main returns
  trap 'rm -rf "${TMP-}"' EXIT

  # Use local files when run from a clone, otherwise download from GitHub
  local SRC_DIR=""
  if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    local d; d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [ -f "$d/bash/suggest.bash" ] && [ -f "$d/inputrc" ] && SRC_DIR="$d"
  fi
  fetch() { # fetch REL_PATH DEST
    if [ -n "$SRC_DIR" ]; then cp "$SRC_DIR/$1" "$2"
    else curl -fsSL "$REPO_RAW/$1" -o "$2"; fi
  }

  # ---------- fzf ----------
  local need_fzf=1 ver
  if command -v fzf >/dev/null 2>&1; then
    ver="$(fzf --version 2>/dev/null | awk '{print $1}')"
    # fzf --bash needs >= 0.48
    if [ "$(printf '%s\n' 0.48 "$ver" | sort -V | head -1)" = "0.48" ]; then need_fzf=0; fi
  fi
  if [ "$need_fzf" = 1 ]; then
    local arch tag
    case "$(uname -m)" in
      x86_64|amd64)  arch=amd64 ;;
      aarch64|arm64) arch=arm64 ;;
      armv7l)        arch=armv7 ;;
      *) arch="" ;;
    esac
    if [ -z "$arch" ]; then
      warn "unknown arch $(uname -m); install fzf yourself: $(pkg_hint fzf)"
    else
      tag="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
              | awk -F'"' '/"tag_name"/ {print $4; exit}')"
      if [ -z "$tag" ]; then
        warn "could not determine latest fzf release; install it yourself: $(pkg_hint fzf)"
      else
        info "Installing fzf ${tag} to $BIN_DIR"
        mkdir -p "$BIN_DIR"
        curl -fsSL "https://github.com/junegunn/fzf/releases/download/${tag}/fzf-${tag#v}-linux_${arch}.tar.gz" \
          | tar xzf - -C "$TMP"
        install -m 755 "$TMP/fzf" "$BIN_DIR/fzf"
      fi
    fi
  else
    info "fzf $ver already installed"
  fi

  # ---------- ble.sh ----------
  info "Installing ble.sh to $BLESH_DIR"
  mkdir -p "$TMP/blesh" "$(dirname "$BLESH_DIR")"
  curl -fsSL "$BLESH_URL" | tar xJf - -C "$TMP/blesh" --strip-components=1
  [ -f "$TMP/blesh/ble.sh" ] || die "ble.sh archive did not contain ble.sh"
  rm -rf "$BLESH_DIR.old"
  [ -d "$BLESH_DIR" ] && mv "$BLESH_DIR" "$BLESH_DIR.old"
  mv "$TMP/blesh" "$BLESH_DIR"
  rm -rf "$BLESH_DIR.old"

  # ---------- config files ----------
  mkdir -p "$CONF_DIR"
  fetch bash/suggest.bash "$CONF_DIR/suggest.bash"
  fetch inputrc "$TMP/inputrc"

  # ---------- ~/.bashrc ----------
  touch "$BASHRC"
  cp "$BASHRC" "$BASHRC.bak.$(date +%Y%m%d-%H%M%S)"
  strip_block "$BASHRC" "ble.sh"
  strip_block "$BASHRC" "main"
  {
    echo '# >>> dotfiles ble.sh >>>'
    echo '[[ $- == *i* ]] && [ -f ~/.local/share/blesh/ble.sh ] && source ~/.local/share/blesh/ble.sh --attach=none'
    echo '# <<< dotfiles ble.sh <<<'
    cat "$BASHRC"
  } > "$TMP/bashrc"
  cat "$TMP/bashrc" > "$BASHRC"
  cat >> "$BASHRC" <<'EOF'
# >>> dotfiles main >>>
[ -f ~/.config/dotfiles/suggest.bash ] && . ~/.config/dotfiles/suggest.bash
# ble-attach must stay the last line of ~/.bashrc
[[ ${BLE_VERSION-} ]] && ble-attach
# <<< dotfiles main <<<
EOF
  bash -n "$BASHRC" || die "syntax error in $BASHRC; restore from $BASHRC.bak.*"

  # ---------- ~/.inputrc ----------
  [ -f "$INPUTRC" ] || { [ -f /etc/inputrc ] && echo '$include /etc/inputrc' > "$INPUTRC" || : > "$INPUTRC"; }
  strip_block "$INPUTRC" "inputrc"
  {
    echo '# >>> dotfiles inputrc >>>'
    cat "$TMP/inputrc"
    echo '# <<< dotfiles inputrc <<<'
  } >> "$INPUTRC"

  info "Done. Open a new shell: type a previous command for gray suggestions (Right/End to accept),"
  info "Ctrl-R for fuzzy history, Up/Down for prefix search. Backup: $BASHRC.bak.*"
}

main "$@"
