#!/usr/bin/env bash
set -euo pipefail

set -x

export DOCKER_BUILDKIT=1

SCRIPT_DIR="$(readlink -f "$(dirname "${BASH_SOURCE}")")"
cd "${SCRIPT_DIR}"

NUMPROC="$(nproc)"

UQM_VERSION="$(grep '^[0-9][0-9]*\(\.[0-9][0-9]*\)*:$' uqm/sc2/ChangeLog | head -n1 | cut -d: -f1)"
UQM_DEB_VERSION="${UQM_VERSION}-dev1"
DEB_FILE="uqm_${UQM_DEB_VERSION}_amd64.deb"
docker build \
  --build-arg NUMPROCS="${NUMPROC}" \
  -t "uqm-build" \
  .
COMMIT="$(git -C uqm rev-parse --short HEAD)"
WORKDIR="$(mktemp -d)"
pushd "${WORKDIR}"
mkdir -p usr
pushd usr
docker run uqm-build cat /root/uqm.tgz | tar -xz
popd
strip usr/lib/uqm/uqm
mkdir -p usr/share/doc/uqm
cp "${SCRIPT_DIR}/uqm/sc2/COPYING" usr/share/doc/uqm/copyright

# changelog
pushd usr/share/doc/uqm
cat > changelog <<EOF
uqm (${UQM_DEB_VERSION}) unstable; urgency=medium

  * Check repo for changes, using commit ${COMMIT}
    from https://git.code.sf.net/p/sc2/uqm

 -- Ari Fogel <ari@fogelti.me>  $(date -R)

EOF
gzip --best < changelog >> changelog.Debian.gz
rm changelog
popd

cat > control <<EOF
Package: uqm
Version: ${UQM_DEB_VERSION}
Architecture: amd64
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Original-Maintainer: Dmitry E. Oboukhov <unera@debian.org>
Installed-Size: 1403
Depends: libc6 (>= 2.15), libgl1-mesa-glx | libgl1, libmikmod3 (>= 3.3.3), libsdl2-2.0-0, libvorbisfile3 (>= 1.1.2), zlib1g (>= 1:1.1.4), libogg0
Section: contrib/games
Priority: optional
Homepage: http://sc2.sourceforge.net/
Description: The Ur-Quan Masters - An inter-galactic adventure game
 You return to Earth with a vessel built from technology discovered from an
 ancient race called the Precursors only to find it enslaved. Gather allies
 from a wide variety of races, engage in space combat with various foes, and
 save the galaxy from the Ur-Quan!
 .
 The Ur-Quan Masters is derived from the classic game Star Control II.
 It includes both the adventure game described above and a fast-paced
 Super Melee.
 .
 See the README.Debian once you have installed this package for information
 about where to get the uqm-music and uqm-voice packages.
EOF

echo 2.0 > debian-binary

find usr -type f -exec md5sum {} \; | sort -k2 > md5sums

# permissions
find usr control md5sums -type f -exec chmod 0644 {} \;
find usr -type d -exec chmod 0755 {} \;
chmod 0755 \
  usr/bin/uqm \
  usr/lib/uqm/uqm

tar --owner=root:0 --group=root:0 -cJf control.tar.xz \
  control \
  md5sums

tar --owner=root:0 --group=root:0 -cJf data.tar.xz \
  usr

ar q "${DEB_FILE}" \
  debian-binary \
  control.tar.xz \
  data.tar.xz

cp "${DEB_FILE}" "${SCRIPT_DIR}/"

popd

rm -rf "${WORKDIR}"
