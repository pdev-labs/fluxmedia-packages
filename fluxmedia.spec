Name:           fluxmedia
Version:        1.18.0
Release:        1%{?dist}
Summary:        Cross-platform media portal and processing toolkit
License:        GPL-3.0-or-later
URL:            https://github.com/pdev-labs/FluxMedia
Source0:        https://github.com/pdev-labs/FluxMedia/archive/refs/tags/v%{version}.tar.gz
# SHA256: ce8eff0176422afbd0cd71feb32ad292f3a062b4c304a56a195ca9ad9f623284

BuildArch:      noarch
BuildRequires:  python3-devel
BuildRequires:  pyproject-rpm-macros
BuildRequires:  python3-build
BuildRequires:  python3-installer
BuildRequires:  python3-setuptools
BuildRequires:  python3-wheel

Requires:       python3-rich >= 13.7.0
Requires:       python3-requests >= 2.31.0
Requires:       yt-dlp >= 2025.2.18
Requires:       python3-textual >= 0.50.0
Requires:       python3-mutagen >= 1.47.0
Requires:       python3-fastapi >= 0.100.0
Requires:       python3-uvicorn >= 0.23.0
Requires:       ffmpeg
# Optional at runtime (lazy-imported by FluxMedia, or JS runtimes for yt-dlp)
Recommends:     nodejs
# NOTE: no `instaloader` weak dep here — it is not in Fedora (checked
# 2026-10). FluxMedia imports it lazily (Instagram [beta] only) and it is
# dropped from the build requirements in %prep, so the RPM stays
# installable; install it via pip if you need that feature.
Suggests:       python3-curl_cffi
Suggests:       python3-quickjs

%description
FluxMedia is a production-ready media manager, automated downloader and
local streaming gateway with a terminal application and web interface.
It downloads video/audio/playlists/subtitles via yt-dlp, post-processes
with FFmpeg, and shares files over the LAN with a password-protected
HTTP server and QR-code access.

%prep
%autosetup -n FluxMedia-%{version}
# Downstream-only pyproject adjustments (mirrored in debian/rules):
# 1. Upstream's legacy `license = "GPL-3.0"` string is rejected by strict
#    setuptools validation; use the valid PEP 621 table form.
sed -i 's/^license = "GPL-3.0"/license = {text = "GPL-3.0"}/' pyproject.toml
# 2. instaloader is not in Fedora and FluxMedia imports it lazily
#    (Instagram [beta] only), so drop it from the hard requirements rather
#    than emitting unsatisfiable python3dist() BuildRequires/Requires.
sed -i '/^    "instaloader>=4.11.0",/d' pyproject.toml

%generate_buildrequires
%pyproject_buildrequires

%build
%pyproject_wheel

%install
%pyproject_install
%pyproject_save_files fluxmedia

# Desktop entry, icon and man page (shipped alongside the spec)
install -Dm644 %{_sourcedir}/fluxmedia.desktop %{buildroot}%{_datadir}/applications/fluxmedia.desktop
if [ -f logo/logo.png ]; then
  install -Dm644 logo/logo.png %{buildroot}%{_datadir}/pixmaps/fluxmedia.png
elif [ -f website/logo.png ]; then
  install -Dm644 website/logo.png %{buildroot}%{_datadir}/pixmaps/fluxmedia.png
fi
install -Dm644 %{_sourcedir}/fluxmedia.1 %{buildroot}%{_mandir}/man1/fluxmedia.1

%files -f %{pyproject_files}
%{_bindir}/fluxmedia
%doc README.md ROADMAP.md
%license LICENSE
%{_datadir}/applications/fluxmedia.desktop
%{_datadir}/pixmaps/fluxmedia.png
%{_mandir}/man1/fluxmedia.1*

%changelog
* Wed Oct 07 2026 pdev-labs <https://github.com/pdev-labs> - 1.18.0-1
- Initial Fedora/RHEL RPM packaging.
