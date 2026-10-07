# FluxMedia packages

Native OS packages for [FluxMedia](https://github.com/pdev-labs/FluxMedia)
(`fluxmedia` — media portal, downloader, LAN QR share gateway).
Upstream version packaged: **1.18.0**.

This repo holds distro-native packaging tracks that all build from
the same upstream release tarball — no `pip install` at install time,
no vendored wheels. `scripts/sync-upstream.sh` + the
`Sync upstream release` workflow keep everything bumped automatically
(see "Auto-sync" below).

| OS / Distro | Files | Installs via |
|---|---|---|
| Arch Linux (AUR) | `PKGBUILD`, `.SRCINFO`, `fluxmedia.desktop`, `fluxmedia.1` | `yay` / `paru` / `makepkg` |
| Debian / Ubuntu | `debian/` | `dpkg-buildpackage` / `apt` |
| Fedora / RHEL | `fluxmedia.spec` | `rpmbuild` / `dnf` / COPR |
| Windows | `windows/` (planned: winget, chocolatey, scoop) | — |

System Python dependencies are used on all three (e.g. `python-rich`,
`yt-dlp`, `python-textual`, `ffmpeg`). Optional extras (`nodejs`,
`instaloader`, `fluxmedia[js]` / `fluxmedia[impersonate]`) are
`optdepends` / `Recommends`, because FluxMedia lazy-imports them only
when the feature is used.

## Prebuilt binaries (no build needed)

Every push/PR runs the [`Build packages`](../../actions/workflows/build-packages.yml)
workflow, which compiles the Arch (`.pkg.tar.zst`), Debian (`.deb`) and
Fedora (`.rpm`) files — download them from the workflow run's
**Artifacts** section. When a GitHub Release is published here, the same
files are attached to the release automatically.

To cut a release: merge the auto-sync PR, then
`gh release create "v$(grep -E '^pkgver=' PKGBUILD | cut -d= -f2)-1" --generate-notes`
(or use the web UI) — the workflow handles the rest.

## 1. Arch Linux (AUR)

```bash
# with an AUR helper
yay -S fluxmedia
# or paru
paru -S fluxmedia

# manual
git clone <aur-url-for-fluxmedia> && cd fluxmedia
makepkg -si
```

Run:

```bash
fluxmedia            # interactive console portal
fluxmedia --web      # web UI dashboard
fluxmedia --tui      # Textual TUI dashboard
man fluxmedia
```

To publish/update the AUR package, copy `PKGBUILD`, `.SRCINFO`,
`fluxmedia.desktop`, `fluxmedia.1` into your `fluxmedia` AUR clone and:

```bash
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO fluxmedia.desktop fluxmedia.1
git commit -m "Update to 1.18.0-1" && git push
```

## 2. Debian / Ubuntu (`.deb`)

Requires Debian 13 (`trixie`) or newer / Ubuntu 25.04+ — older releases
lack `python3-textual`.

```bash
sudo apt install debhelper pybuild-plugin-pyproject \
  python3-build python3-installer python3-setuptools python3-wheel

# from an upstream tarball + this debian/ dir:
#   mkdir build && cd build
#   tar xzf ../FluxMedia-1.18.0.tar.gz
#   cp -r ../debian FluxMedia-1.18.0/debian
#   cd FluxMedia-1.18.0 && dpkg-buildpackage -us -uc
sudo apt install ../fluxmedia_1.18.0-1_all.deb

fluxmedia --web
```

## 3. Fedora / RHEL (`.rpm`)

```bash
sudo dnf install rpm-build python3-devel pyproject-rpm-macros \
  python3-build python3-installer python3-setuptools python3-wheel

# build
mkdir -p ~/rpmbuild/{SOURCES,SPECS}
cp fluxmedia.spec ~/rpmbuild/SPECS/
cp fluxmedia.desktop fluxmedia.1 ~/rpmbuild/SOURCES/
spectool -g -R ~/rpmbuild/SPECS/fluxmedia.spec
rpmbuild -ba ~/rpmbuild/SPECS/fluxmedia.spec
sudo dnf install ~/rpmbuild/RPMS/noarch/fluxmedia-1.18.0-1*.noarch.rpm

fluxmedia --tui
```

For one-command installs for end users, publish the resulting
`.deb` / `.rpm` as GitHub Release assets, or submit the spec to a
[COPR](https://copr.fedorainfracloud.org/) project and point users at
`sudo dnf copr enable <you>/fluxmedia && sudo dnf install fluxmedia`.

## Version bumps (automatic + manual)

**Automatic (default):** the `Sync upstream release` workflow polls
`pdev-labs/FluxMedia` every 6h (plus manual dispatch with an optional
pinned version, plus `repository_dispatch: upstream-release` for
instant triggers). On a new release it bumps `PKGBUILD` + `.SRCINFO` +
`fluxmedia.spec` + `debian/changelog` + `README.md` and opens a PR
labeled `automated, packaging`. Local equivalent:

```bash
scripts/sync-upstream.sh --check     # 0 = current, 1 = update available
scripts/sync-upstream.sh             # bump to latest upstream release
scripts/sync-upstream.sh --version 1.19.0  # bump to an explicit version
```

**Manual:**

1. Update `pkgver` in `PKGBUILD`, `Version:` in `fluxmedia.spec`,
   and the top entry in `debian/changelog` (or just run the script above).
2. Refresh the GitHub tarball hash:
   `curl -sL https://github.com/pdev-labs/FluxMedia/archive/refs/tags/vX.Y.Z.tar.gz | sha256sum`
   and put it in `PKGBUILD` (`sha256sums`) and the `fluxmedia.spec` comment.
3. Regenerate: `makepkg --printsrcinfo > .SRCINFO`.
4. Test: `makepkg -s` (Arch), `dpkg-buildpackage -us -uc` (Debian),
   `rpmbuild -ba fluxmedia.spec` (Fedora).

## Notes

- License: upstream is GPL-3.0-or-later (`LICENSE` installed to
  `/usr/share/licenses/fluxmedia/` on Arch, standard doc dirs elsewhere).
- `fluxmedia.desktop` is a `Terminal=true` launcher; the icon comes from
  upstream `logo/logo.png` (fallback: `website/logo.png`).
- Upstream PyPI remain the fallback: `pipx install fluxmedia`.
