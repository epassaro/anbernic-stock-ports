#!/bin/bash
set -euo pipefail

VERSION=3.1.1
BUILD_DIR=/tmp/build
GIT_REPO=https://github.com/chocolate-doom/chocolate-doom.git
DATA_URL=https://github.com/epassaro/anbernic-stock-ports/releases/download/data-1.0.0
PREFIX=${BUILD_DIR}/installdir
HOST=aarch64-linux-gnu

create_launcher() {
  local game="$1"
  local destdir="${2:-.}"

  mkdir -p "$destdir"
  local launcher="${destdir}/${game^}.sh"

  cat > "$launcher" <<EOF
#!/bin/sh
progdir=\$(dirname "\$0")/${game^}
cd "\$progdir" || exit 1
HOME="\$progdir"

LD_DEBUG=libs ./chocolate-${game} -iwad ${game^^}1.WAD -window 0 > log.txt 2>&1
sync
EOF

  chmod +x "$launcher"
}

mkdir -p ${BUILD_DIR}
git clone --depth 1 --branch chocolate-doom-${VERSION} ${GIT_REPO} ${BUILD_DIR}/sources
cd ${BUILD_DIR}/sources
./autogen.sh --host=${HOST} --prefix=${PREFIX}
make install -j$(nproc)

for game in doom heretic; do
    cd ${PREFIX}
    mkdir -p dist/${game^}
    cp bin/chocolate-${game} dist/${game^}
    curl -sL ${DATA_URL}/${game^^}1.WAD -o dist/${game^}/${game^^}1.WAD

    cd dist/
    create_launcher ${game}
    zip -r ${game^}.zip ${game^} ${game^}.sh
    rm -rf ${game^} ${game^}.sh
done

cp -r ${PREFIX}/dist /workdir

exit 0
