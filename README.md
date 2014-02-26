xproj
=====

## What's this

__xproj__ 是一个shell脚本，可以给工程批量添加 `-fno-objc-arc` 和 `-fobjc-arc` 编译参数。

如果你的项目是 `非arc` ，但是用到了 `arc` 的第三方，或者反之，这时候你有两种选择，`cocopods` 或者手动添加。

1. 使用 `cocopods` 当然是推荐方案，但是出于一些原因，你可能不用它。
2. 这时候你只能手动添加，当然在Xcode里可以多选（ `CMD` or `SHIFT` ），然后双击其中一个文件，接着在弹出的对输入框里添加。

**但是**如果文件**巨多**，在 `Build Phases -> Compile Sources` 里既有项目原来的文件，又有你刚刚拉进去的文件，考验你耐心的时候到了~ 肿么办?

算了，还是让这个脚本帮你做点什么吧~

### 准备

第一步需要把用到的文件加到项目里，保证 `Build Phases -> Compile Sources` 里能看到它们

### 加 `-fno-objc-arc`

```sh
sh xproj -s 需要添加编译参数的文件所在的文件夹 -t 目标工程文件

# xproj -s framework -t test.xcodeproj/

```

### 加 `-fobjc-arc`
  
```sh
sh xproj -n -s 需要添加编译参数的文件所在的文件夹 -t 目标工程文件
```
## [EXAMPLE](http://qfi.sh/)

## 提示

当然，这个脚本是直接修改你的工程文件，所以会有风险，不过考虑到这点，脚本在做任何操作之前会先自动备份一份你的工程文件，该文件以.bak结尾，执行完没有问题之后你可以把它删了，当然也可以留作纪念~

## HELP
```
NAME
  xproj - batch adding compile flags like `-fno-objc-arc`or `-fobjc-arc`

SYNOPSIS
  xproj -s dir [-t xcodeproj] [-ne]

DESCRIPTION
  

OPTIONS
  -p, --print-only
    Only prints the .dot file to STDOUT. Mutually exclusive with
    --image-only.

  -i, --image-only
    Only generates an image of the graph, and a .dot file beforehand.
    Mutually exclusive with --print-only.

AUTHOR
  Written by QFish <qfish.cn@gmail.com>

COPYRIGHT
  MIT
```