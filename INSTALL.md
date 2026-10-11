# Installing FluxMedia

Upstream version packaged: **1.18.0**.

Prebuilt packages for every release live under
[Releases](https://github.com/pdev-labs/fluxmedia-packages/releases/latest).
Pick your distro below. After installing, verify with:

```bash
fluxmedia --doctor   # environment / dependency report
fluxmedia            # interactive console portal
```

## Arch Linux

**Recommended — prebuilt package (works right now):**

```bash
sudo pacman -U https://github.com/pdev-labs/fluxmedia-packages/releases/download/v1.18.0-1/fluxmedia-1.18.0-1-any.pkg.tar.zst
```

Dependencies (`python-rich`, `yt-dlp`, `ffmpeg`, …) are resolved
automatically from the official repos. To update later, re-run the
command with the new release URL, or check the
[latest release](https://github.com/pdev-labs/fluxmedia-packages/releases/latest).

**Alternative — build it yourself (same result, no download trust needed):**

```bash
sudo pacman -S --needed base-devel git
git clone https://github.com/pdev-labs/fluxmedia-packages.git
cd fluxmedia-packages
makepkg -si
```

### Why can't I just `yay -S fluxmedia` / `paru -S fluxmedia`?

Those helpers install from the **AUR** (Arch User Repository), and this
package hasn't been submitted there yet — **not because we don't want
to, but because AUR is currently not accepting new accounts.**

Since 2025, new account registration on
[aur.archlinux.org/register](https://aur.archlinux.org/register) returns
`HTTP 503 — New account registration is temporarily closed` while the
Arch team deals with a wave of automated (bot) account creation. Only
existing AUR account holders can submit new packages, and there is no
manual registration queue.

What this means for you:

- `yay -S fluxmedia` / `paru -S fluxmedia` will report "package not
  found" until the freeze lifts and we submit. This is expected.
- The prebuilt `.pkg.tar.zst` above is byte-for-byte what the AUR
  package would build (`makepkg` from the same `PKGBUILD`), so you lose
  nothing except automatic `yay -Syu` updates.
- Track the freeze status via
  [aur-general](https://lists.archlinux.org/hyperkitty/list/aur-general@lists.archlinux.org/)
  or the [Arch news feed](https://archlinux.org/news/). The day it
  reopens, `yay -S fluxmedia` will start working — no reinstall needed,
  `pacman` treats them as the same package.

## Debian / Ubuntu

Requires Debian 13 (`trixie`) or newer / Ubuntu 25.04 or newer
(older releases lack `python3-textual`).

```bash
# download fluxmedia_1.18.0-1_all.deb from the link at the top,
# then:
sudo apt install ./fluxmedia_1.18.0-1_all.deb
```

`apt` resolves the dependencies (`python3-rich`, `yt-dlp`, `ffmpeg`,
…) automatically.

## Fedora / RHEL

```bash
# download the .rpm from the link at the top, then:
sudo dnf install ./fluxmedia-1.18.0-1*.noarch.rpm
```

`dnf` resolves the dependencies (`python3-rich`, `yt-dlp`, `ffmpeg`,
…) automatically.

## Updating & uninstalling

- **Updating:** install the newer file the same way you installed the
  old one (`pacman -U`, `apt install`, `dnf install`). Your data in
  `~/.local/share/FluxMedia/` (config, history, logs) is preserved.
- **Uninstalling:**
  ```bash
  sudo pacman -R fluxmedia        # Arch
  sudo apt remove fluxmedia       # Debian/Ubuntu
  sudo dnf remove fluxmedia       # Fedora
  ```

## Troubleshooting

- **`fluxmedia: command not found`** — close and reopen the terminal
  (PATH refresh), or check `pacman -Ql fluxmedia | grep /usr/bin/`.
- **Missing optional features** — the Instagram downloader needs
  `instaloader` (`sudo pacman -S` needs AUR / `pipx` / `apt install
  instaloader` per distro); YouTube JS challenges work best with
  `nodejs` installed. Both are optional — everything else runs without
  them.
- **Old distro release** (e.g. Debian 12, Ubuntu 24.04) — the `.deb`
  requires newer Python packages; either upgrade the distro or fall
  back to `pipx install fluxmedia`.
- **Still stuck?** Open an issue at
  [pdev-labs/fluxmedia-packages](https://github.com/pdev-labs/fluxmedia-packages/issues)
  with your distro, version, and the full error output.
