# dotfiles

Bash with history-based suggestions for any Linux or WSL machine. Works over SSH, because everything runs in the remote shell.

- **[ble.sh](https://github.com/akinomyoga/ble.sh)**: fish-style gray inline suggestions from your history. Press `→` or `End` to accept the whole suggestion, `Ctrl-F` to accept one word.
- **[fzf](https://github.com/junegunn/fzf)**: `Ctrl-R` fuzzy history search, `Ctrl-T` file picker, `Alt-C` to jump into a folder.
- **History**: 100k entries with timestamps, shared across sessions.
- **`↑`/`↓`**: search history for commands that start with what you've typed.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Arskan17/dotfiles/main/install.sh | bash
```

Then open a new shell. You can run the installer again at any time to update ble.sh and the config.

The installer needs `curl`, `tar`, `xz` and `awk`, and no sudo. If fzf is missing or older than 0.48, it installs fzf to `~/.local/bin`.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/Arskan17/dotfiles/main/install.sh | bash -s -- --uninstall
```

## What it touches

- `~/.bashrc`: two marked blocks (`# >>> dotfiles … >>>`), one at the top and one at the bottom. A timestamped backup is written as `~/.bashrc.bak.*` first.
- `~/.inputrc`: one marked block.
- `~/.local/share/blesh`, `~/.config/dotfiles/suggest.bash`, and `~/.local/bin/fzf` (only if fzf had to be installed).
