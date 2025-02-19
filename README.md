# rttpkgtool

A simple package tool to pack RT-Thread kenrel into bootable images for duo family.

# 操作步骤

## 安装一些额外的外部依赖

``` shell
$ sudo apt update
$ sudo apt install u-boot-tools xz-utils
```

u-boot-tools 包含了打包需要的 mkimage, xz-utils 包含了打包需要的 lzma。

## 拉取 `rttpkgtool` 工具到本地

``` shell 
$ git clone git@github.com:plctlab/rttpkgtool.git
```

进入 rttpkgtool 目录，后面的操作都在该目录下进行。

```shell
$ cd rttpkgtool                   
```

## 执行打包

命令的格式为:

`DPT_PATH_KERNEL=<path_kernel> [DPT_BOARD_TYPE=<board_type>] [DPT_PATH_OUTPUT=<path_output>] ./mkpkg.sh  [-h/-l/-b/-a]`                                              

- 含有 `[]` 的项是可以省略的 
- 环境变量 `DPT_PATH_KERNEL`(必选): rt-thread 仓库的绝对路径（路径名包括 `rt-thread`），通过该路径，package tool 才可以找到 RT-Thread 的 kernel image，即 `rtthread.bin`。
- 环境变量 `DPT_BOARD_TYPE`（可选）: 开发板的类型，目前支持 `duo`，`duo256m`, `duos` 三种开发板类型。不指定该选项，默认采用 `duo256m`。
- 环境变量 `DPT_PATH_OUTPUT`（可选）: 输出的绝对路径。各个板子的输出再按照子目录存放在 `DPT_PATH_OUTPUT` 下。不指定该选项，默认输出在 `rttpkgtool/output` 下。
- 命令行选项 `-h`/`-l`/`-b`/`-a`: 
  - `-h`: 打印帮助信息后直接退出。
  - `-l`：只对小核进行打包，即只生成 `fip.bin`。
  - `-b`：只对大核进行打包，即只生成 `boot.sd`。
  - `-a`：对大核和小核都进行打包，即同时生成 `fip.bin` 和 `boot.sd`。
  如果出现多个命令行选项，优先级 `-h` > `-a` > `-b` > `-l`。如果不指定命令行选项，则等同于 `-a`。

示例如下:

``` shell
$ DPT_PATH_KERNEL=/home/u/rt-thread DPT_BOARD_TYPE=duo256m DPT_PATH_OUTPUT=/home/u/rttokgtool/output ./script/mkpkg.sh -a
```

或者

``` shell
$ DPT_PATH_KERNEL=/home/u/rt-thread ./script/mkpkg.sh
```

如需使用 Cortex-A53 作为大核，请添加 arm 参数，如下
``` shell
$ DPT_PATH_KERNEL=/home/u/rt-thread ./script/mkpkg.sh arm
```
## 更新 prebuild 文件

rttpkgtool 使用预制的 prebuild 二进制固件文件构建 duo 的 `fip.bin` 和 `boot.sd`。这些 prebuild 文件基于 duo-buildroot-sdk (<https://github.com/milkv-duo/duo-buildroot-sdk.git>) 构建得到，存放在 rttpkgtool 仓库的 `prebuilt` 目录下。

如果 duo-buildroot-sdk 升级了，则也有可能需要同步升级这些 perbuild 文件。rttpkgtool 软件包提供了一个制作 prebuild 文件的脚本工具 `./script/prebuild.sh`。

可以通过运行如下命令制作 prebuild 文件：

```shell
PATH_DUO_SDK=<path_duo_sdk> ./prebuild.sh
```

`PATH_DUO_SDK` 用于指定 duo-buildroot-sdk 的文件系统路径。注意 `prebuild.sh` 本身不负责下载 duo-buildroot-sdk 以及切换分支等操作，使用者需要自行下载该仓库并将其路径并在运行 `prebuild.sh` 脚本时通过 `PATH_DUO_SDK` 传入。

`prebuild.sh` 会在构建成功后更新 rttpkgtool 仓库的 `prebuilt` 目录，并将构建 duo-buildroot-sdk 对应的 commit hash 值记录在 `prebuilt/commit_hash.txt` 下，方便以后回溯。

