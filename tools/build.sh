#!/usr/bin/env bash
# 编 BusyBox 并打 initramfs，产物 out/rootfs-mini.uimg（U-Boot 可直接 fatload + bootz）。
#   bash tools/build.sh
#   LVGL_DEMO=/path/to/lvgl_demo bash tools/build.sh    # 把仪表盘塞进 /usr/bin
# 环境变量：IM6_SRC / IM6_CROSS / IM6_JOBS / LVGL_DEMO
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC=${IM6_SRC:-$ROOT/src}
CROSS=${IM6_CROSS:-arm-linux-gnueabihf-}
JOBS=${IM6_JOBS:-$(nproc)}
OUT=$ROOT/out
LVGL_DEMO=${LVGL_DEMO:-}

for tool in make cpio gzip mkimage "${CROSS}gcc"; do
  command -v "$tool" >/dev/null || { echo "缺少工具：$tool（apt install build-essential cpio gzip u-boot-tools gcc-arm-linux-gnueabihf）" >&2; exit 1; }
done
[ -f "$SRC/busybox/Makefile" ] || bash "$ROOT/tools/fetch.sh"
mkdir -p "$OUT"

echo "== BusyBox =="
make -C "$SRC/busybox" ARCH=arm CROSS_COMPILE="$CROSS" -j"$JOBS"

R=$(mktemp -d "${TMPDIR:-/tmp}/im6-rootfs.XXXX")
trap 'rm -rf "$R"' EXIT
make -C "$SRC/busybox" ARCH=arm CROSS_COMPILE="$CROSS" install CONFIG_PREFIX="$R" >/dev/null
cp "$R/bin/busybox" "$OUT/busybox" 2>/dev/null || true

mkdir -p "$R"/{dev,proc,sys,tmp,run,var/log,root,etc/init.d,usr/bin}
chmod 1777 "$R/tmp"
cp "$ROOT/rootfs/init" "$R/init"
cp "$ROOT/rootfs/etc/init.d/rcS" "$R/etc/init.d/rcS"
cp "$ROOT/rootfs/etc/inittab" "$ROOT/rootfs/etc/fstab" "$ROOT/rootfs/etc/profile" "$R/etc/"
chmod 755 "$R/init" "$R/etc/init.d/rcS"

if [ -n "$LVGL_DEMO" ]; then
  [ -f "$LVGL_DEMO" ] || { echo "LVGL_DEMO 指向的文件不存在：$LVGL_DEMO" >&2; exit 1; }
  cp "$LVGL_DEMO" "$R/usr/bin/lvgl_demo"
  echo "   已放入 LVGL 仪表盘"
fi

echo "== 打 initramfs =="
(cd "$R" && find . -print0 | cpio --null -o --format=newc --owner=0:0 2>/dev/null | gzip -9) > "$OUT/rootfs-mini.cpio.gz"
mkimage -A arm -O linux -T ramdisk -C gzip -n 'imx6ull mini initramfs' \
        -d "$OUT/rootfs-mini.cpio.gz" "$OUT/rootfs-mini.uimg" >/dev/null

echo
ls -l "$OUT"
sha256sum "$OUT"/*
