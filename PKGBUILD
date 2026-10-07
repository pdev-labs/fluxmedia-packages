# Maintainer: pdev-labs <https://github.com/pdev-labs>
pkgname=fluxmedia
pkgver=1.18.0
pkgrel=1
pkgdesc="A powerful, cross-platform media portal and processing toolkit (LAN QR share portal + rich media player)"
arch=('any')
url="https://github.com/pdev-labs/FluxMedia"
license=('GPL-3.0-or-later')
depends=(
  'python'
  'python-rich>=13.7.0'
  'python-requests>=2.31.0'
  'yt-dlp>=2025.2.18'
  'python-textual>=0.50.0'
  'python-mutagen>=1.47.0'
  'python-fastapi>=0.100.0'
  'uvicorn>=0.23.0'
  'ffmpeg'
)
makedepends=(
  'python-build'
  'python-installer'
  'python-setuptools'
  'python-wheel'
)
optdepends=(
  'nodejs: JavaScript runtime for yt-dlp JS challenges (YouTube)'
  'instaloader: Instagram profile downloader [beta] (AUR)'
  'python-websockets: improved portal websocket performance'
)
source=("$pkgname-$pkgver.tar.gz::https://github.com/pdev-labs/FluxMedia/archive/refs/tags/v$pkgver.tar.gz"
        "fluxmedia.desktop"
        "fluxmedia.1")
sha256sums=('ce8eff0176422afbd0cd71feb32ad292f3a062b4c304a56a195ca9ad9f623284'
            'SKIP'
            'SKIP')

build() {
  cd "FluxMedia-$pkgver"
  python -m build --wheel --no-isolation
}

check() {
  cd "FluxMedia-$pkgver"
  # Compile-check only: full suite needs network (sample downloads, web boot).
  python -m compileall -q src || true
}

package() {
  cd "FluxMedia-$pkgver"
  python -m installer --destdir="$pkgdir" dist/*.whl

  # License
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"

  # Desktop entry + icon (CLI/TUI launcher)
  install -Dm644 "$srcdir/fluxmedia.desktop" "$pkgdir/usr/share/applications/fluxmedia.desktop"
  if [ -f logo/logo.png ]; then
    install -Dm644 logo/logo.png "$pkgdir/usr/share/pixmaps/fluxmedia.png"
  elif [ -f website/logo.png ]; then
    install -Dm644 website/logo.png "$pkgdir/usr/share/pixmaps/fluxmedia.png"
  fi

  # Man page (shipped in this packaging repo)
  install -Dm644 "$srcdir/fluxmedia.1" "$pkgdir/usr/share/man/man1/fluxmedia.1"
}
