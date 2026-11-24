#!/usr/bin/env bash
# 拉 BusyBox 1.38.0 到 src/busybox，校验 sha256，套上板级 .config。
#   bash tools/fetch.sh
# 环境变量：IM6_SRC / IM6_BB_URL / IM6_BB_FILE / IM6_FORCE=1
# 注：busybox.net 在部分网络下 TLS 会被重置，默认已带 Buildroot / Alpine 镜像回退。
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC=${IM6_SRC:-$ROOT/src}
BB_VER=1.38.0
BB_SHA=34f9ea6ff8636f2c9241153b9114eefa9e65674a45318ae1ef95bb5f31c53bb2
BB_URL=${IM6_BB_URL:-https://busybox.net/downloads/busybox-$BB_VER.tar.bz2}
: "${IM6_FORCE:=0}"

mkdir -p "$SRC"

if [ ! -f "$SRC/busybox/Makefile" ] || [ "$IM6_FORCE" = 1 ]; then
  echo "== 下载 BusyBox $BB_VER =="
  rm -rf "$SRC/busybox" "$SRC/busybox-$BB_VER"
  TMP=$(mktemp -d)
  if [ -n "${IM6_BB_FILE:-}" ]; then
    cp "$IM6_BB_FILE" "$TMP/bb.tar.bz2"
  else
    ok=0
    for u in "$BB_URL" \
             "https://sources.buildroot.net/busybox/busybox-$BB_VER.tar.bz2" \
             "https://distfiles.alpinelinux.org/distfiles/edge/busybox-$BB_VER.tar.bz2"; do
      echo "   下载 $u"
      if curl -fL --retry 3 --connect-timeout 20 -o "$TMP/bb.tar.bz2" "$u"; then ok=1; break; fi
      echo "   失败，换下一个源"
    done
    [ "$ok" = 1 ] || { echo "!! 所有源都失败，手动下载后用 IM6_BB_FILE 指定" >&2; exit 1; }
  fi
  echo "$BB_SHA  $TMP/bb.tar.bz2" | sha256sum -c -
  tar -xjf "$TMP/bb.tar.bz2" -C "$SRC"
  mv "$SRC/busybox-$BB_VER" "$SRC/busybox"
  rm -rf "$TMP"
else
  echo "== 复用已有 BusyBox 源码 =="
fi

cp "$ROOT/busybox/busybox.config" "$SRC/busybox/.config"
echo "源码就绪：$SRC/busybox"
