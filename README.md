**rttpkgtool**

A simple package tool to pack RT-Thread kenrel into bootable images for canmv-k230 family.
Currently only support "k230_rtos_01studio_defconfig".

<!-- TOC -->

- [打包步骤](#打包步骤)
	- [安装一些额外的外部依赖](#安装一些额外的外部依赖)
	- [安装交叉工具链](#安装交叉工具链)
	- [拉取 `rttpkgtool` 工具到本地](#拉取-rttpkgtool-工具到本地)
	- [执行打包](#执行打包)
- [烧录 SD 卡](#烧录-sd-卡)
- [更新 prebuild 文件](#更新-prebuild-文件)

<!-- /TOC -->

# 打包步骤

## 安装一些额外的外部依赖

``` shell
$ sudo apt update
$ sudo apt install u-boot-tools patch
```

u-boot-tools 包含了打包需要的 mkimage, patch 包含了 prebuild 需要的 patch。

## 安装交叉工具链

打包过程中需要编译 opensbi，所以需要安装交叉工具链。安装方法：

- 方法一：随 K230 RTOS Only SDK 一同安装，参考 <https://developer.canaan-creative.com/k230_rtos/zh/dev/userguide/how_to_build.html>。其中 “4.3 初始化工具链” 会下载安装交叉工具链。

- 方法二：如果不想安装 K230 RTOS Only SDK，也可以自己手动独立安装工具链。

```shell
$ sudo mkdir -p /opt/toolchain
$ cd /opt/toolchain
$ sudo wget https://kendryte-download.canaan-creative.com/k230/toolchain/Xuantie-900-gcc-linux-6.6.0-glibc-x86_64-V2.10.1-20240712.tar.gz
$ sudo tar xzf Xuantie-900-gcc-linux-6.6.0-glibc-x86_64-V2.10.1-20240712.tar.gz
```

## 拉取 `rttpkgtool` 工具到本地

``` shell 
$ git clone -b for-k230 git@github.com:plctlab/rttpkgtool.git
```

进入 rttpkgtool 目录，后面的操作都在该目录下进行。

```shell
$ cd rttpkgtool                   
```

## 执行打包

命令的格式为:

```shell
DPT_PATH_KERNEL=<path_kernel> [DPT_PATH_OUTPUT=<path_output>] [DPT_CROSS_COMPILE=<path_toolchain>] ./mkpkg.sh [-h] [-f]
```

- 含有 `[]` 的项是可以省略的 
- 环境变量 `DPT_PATH_KERNEL`(必选): `rtthread.bin` 文件所在的绝对路径。
- 环境变量 `DPT_PATH_OUTPUT`（可选）: 输出的绝对路径。不指定该选项，默认输出在 `rttpkgtool/output` 下。
- 环境变量 `DPT_CROSS_COMPILE`（可选）: 打包过程中会编译 opensbi，这里指定交叉编译的工具链前缀（含路径）。不指定该选项，默认路径是 `/opt/toolchain/Xuantie-900-gcc-linux-6.6.0-glibc-x86_64-V2.10.1/bin/riscv64-unknown-linux-gnu-`。
- 命令行选项 `-h`/`-f`: 
  - `-h`: 打印帮助信息后直接退出。
  - `-f`：会清理输出（删除 `DPT_PATH_OUTPUT`）后重新编译。
  如果出现多个命令行选项，优先级 `-h` > `-f`。如果不指定命令行选项，则不清理输出，直接重新打包。

示例如下:

``` shell
$ DPT_PATH_KERNEL=/home/u/ws/canaan/rt-thread/bsp/k230 ./script/mkpkg.sh -f
```

或者

``` shell
$ DPT_PATH_KERNEL=/home/u/ws/canaan/rt-thread/bsp/k230 ./script/mkpkg.sh
```

打包完成后，生成的包含 RT-Thread 内核的 opensbi 二进制文件位置在：`${DPT_PATH_OUTPUT}/k230_rtos_01studio_defconfig/images/opensbi/opensbi_rtt_system.bin`。我们可以拿它来单独更新内核。

# 烧录 SD 卡

参考 K230 RTOS Only SDK 用户指南中的 “如何编译固件”：<https://developer.canaan-creative.com/k230_rtos/zh/dev/userguide/how_to_build.html> 生成一个完整的 image。然后参考 K230 RTOS Only SDK 用户指南中的 “如何烧录固件”：<https://developer.canaan-creative.com/k230_rtos/zh/dev/userguide/how_to_flash.html>, 通过 SD 卡烧录。熟悉 Windows 平台的可以使用 balenaEtcher。烧录后，SD 卡上会自动分区和格式化。**注意以上操作只要做一次**。

后面就可以单独更新内核固件了。

为方便使用，本仓库提供了一个快速烧录 SD 卡的脚本 `./script/sdcard.sh`。

有关如何使用，执行：

```shell
$ ./script/sdcard.sh -h
Usage:
  [SRC=<path_src>] [DEST=<path_dest>] ./mksd.sh [-h]
  - SRC: path of input file, default as
         '${SDK_BUILD_IMAGES_DIR}/opensbi/opensbi_rtt_system.bin' if not provided
  - DEST: path of output file, default as '/dev/sdb' if not provided
  - -h: display usage, other options are ignored
```

以 01Studio CanMV-K230 开发板为例，插入 SD 卡烧录器后，可以直接执行该脚本：

```shell
$ ./script/sdcard.sh
SRC:  /home/u/ws/rttpkgtool/output/k230_rtos_01studio_defconfig/images/opensbi/opensbi_rtt_system.bin
DEST: /dev/sdb
[sudo] password for u: 
767+1 records in
767+1 records out
393140 bytes (393 kB, 384 KiB) copied, 0.101348 s, 3.9 MB/s
Done!
```

# 更新 prebuild 文件

rttpkgtool 直接引用了 K230 RTOS Only SDK 中的脚本和工具程序（我们称这些 SDK 提供的脚本和工具程序为 prebuild 文件）进行打包。如果 K230 RTOS Only SDK 升级了，则也有可能需要同步升级这些 prebuild 文件。rttpkgtool 软件包提供了一个更新 prebuild 文件的脚本工具 `./script/prebuild.sh`。

可以通过运行如下命令更新 prebuild 文件：

```shell
PATH_K230_RTT_SDK=<path_to_k230_rtos_sdk> ./script/prebuild.sh
```

`PATH_K230_RTT_SDK` 用于指定 K230 RTOS Only SDK 的文件系统路径。注意 `prebuild.sh` 本身不负责下载 K230 RTOS Only SDK 以及切换分支等操作，使用者需要自行下载该仓库并将其路径并在运行 `prebuild.sh` 脚本时通过 `PATH_K230_RTT_SDK` 传入。

`prebuild.sh` 会在构建成功后更新 rttpkgtool 仓库的相关目录和文件，并将构建 K230 RTOS Only SDK 对应的 commit hash 值记录在 `scropt/commit_hash.txt` 下，方便以后回溯。
