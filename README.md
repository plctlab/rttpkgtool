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
$ git clone git@github.com:unicornx/rttpkgtool.git
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
$ DPT_PATH_KERNEL=/home/u/rt-thread DPT_BOARD_TYPE=duo256m DPT_PATH_OUTPUT=/home/u/rttokgtool/output ./mkpkg.sh -a
```

或者

``` shell
$ DPT_PATH_KERNEL=/home/u/rt-thread ./mkpkg.sh
```

