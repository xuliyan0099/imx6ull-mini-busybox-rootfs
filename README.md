# imx6ull-mini-busybox-rootfs

正点原子 **i.MX6ULL Mini** 的 **BusyBox 1.38.0** 静态 initramfs rootfs，连同 `/init`、`rcS`、`inittab`
一起打包成 U-Boot 能直接 `bootz` 的 `rootfs-mini.uimg`。

## 快速开始

```bash
sudo apt install build-essential cpio gzip u-boot-tools gcc-arm-linux-gnueabihf
git clone https://github.com/xuliyan0099/imx6ull-mini-busybox-rootfs.git
cd imx6ull-mini-busybox-rootfs
bash tools/build.sh                                   # 纯 shell rootfs
LVGL_DEMO=/path/to/lvgl_demo bash tools/build.sh        # 带仪表盘
```

产物：`out/rootfs-mini.uimg`（1.6 MB 级）、`out/busybox`（静态 ARM，1.56 MB）。

## rootfs 设计

| 文件 | 作用 |
| --- | --- |
| `rootfs/init` | PID 1，挂 `/proc /sys`，跑 `rcS`，打印 `imx6ull-mini: rootfs ready`，再 `exec` shell |
| `rootfs/etc/init.d/rcS` | 设 PATH/HOME、`mdev -s` 建 `/dev`、可选后台拉起 `/usr/bin/lvgl_demo`（日志 `/var/log/lvgl.log`） |
| `rootfs/etc/inittab` | `::console::askfirst:-/bin/sh`（`ttymxc0`） |
| `rootfs/etc/fstab` | `proc` / `sysfs` / `tmpfs /tmp` / `devtmpfs /dev` |
| `rootfs/etc/profile` | `PS1`、`PATH`、`export TZ=CST-8` |

`busybox/busybox.config` 是静态链接、ASH、mdev、`ip`/`ifconfig` 齐全、去掉 NFS/无线/大体积 applet 的配置。

## 与内核/引导的衔接

U-Boot 里：

```text
fatload mmc 0:1 0x84000000 rootfs-mini.uimg
setenv bootargs console=ttymxc0,115200 root=/dev/ram0 rw
bootz 0x80800000 0x84000000 0x83000000
```

内核需要 `CONFIG_BLK_DEV_INITRD=y` 和 `CONFIG_RD_GZIP=y`（本仓库配套的内核配置已开）。

## 环境变量

| 变量 | 默认 | 用途 |
| --- | --- | --- |
| `IM6_SRC` | `./src` | BusyBox 源码目录 |
| `IM6_BB_URL` / `IM6_BB_FILE` | busybox.net / — | 镜像地址 / 本地 tar.bz2 |
| `LVGL_DEMO` | 空 | 要放进 `/usr/bin` 的仪表盘二进制 |
| `IM6_CROSS` / `IM6_JOBS` | `arm-linux-gnueabihf-` / `nproc` | 交叉前缀 / 并行度 |

许可：rootfs 脚本与配置 MIT；BusyBox 本体 GPL-2.0。
