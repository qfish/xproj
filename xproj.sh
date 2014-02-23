# !/bin/sh

# 定义返回变量
SUCCESS=0
ERROR=1

# 声明变量
SOURCE_PATH="test/a"
TARGET_PATH="test/project.txt"
TEMPFILE_PATH="temp.txt"
FILE_BLACKLIST='\.h$|\.DS_Store|\.sh$|\.png$|\.svn$'
BUILD_SETTING_TARGET=""
BUILD_SETTING_REPLACE=""

# 如果输入为空，则打印帮助
# if [ "$1" == "" ]; then
#   # printHelp
#   exit $ERROR
# fi

process

# process $1 $2
process()
{
  # # STEP 1
  > $TEMPFILE_PATH # 清空临时文件

  # # STEP 2
  find $SOURCE_PATH -type f -print | # 获取所有文件名
  grep -E -v $FILE_BLACKLIST > $TEMPFILE_PATH # 根据黑名单过滤文件名并写入文件

  # # STEP 3
  # ## STEP 3.1

  # 获取需要处理的总行数，供进度条用
  local totals=$(cat < $TEMPFILE_PATH | wc -l|tr -d " ")
  # echo $totals
  # 保存处理过的数量
  local counts=0

  # ## STEP 3.2

  # 备份
  cp $TARGET_PATH $TARGET_PATH.bak
  # 遍历每一行，获取文件名
  local i=0
  while read line; do
    i=$(expr $i + 1)
    # echo $i
    # percent=`awk "BEGIN{ print $i / $totals }"`
    local percent=$(echo "($i/$totals*100)" | bc -l) # 获取当前百分比
    # echo $percent
    # 取文件名
    local name=$(basename "$line")
    # 当文件名不为空时处理
    if [ "$name" != "" ]; then
      # echo $name
      local excepts="-fno-objc-arc"
      local pattern="fileRef = [A-Z0-9]\{1,\} /\* "$name" \*/;"
      # echo $pattern
      local target="\("$pattern"\)"
      # echo "$target"
      local result="\1 settings = {COMPILER_FLAGS = \"-fno-objc-arc\"; };"
      # echo "$result"
      # 替换并打印，但不写入文件
      # sedcmd="s:"$target":"$result":g" # g 全局替换
      # sedcmd="s:"$target":"$result":p" # p 打印编辑行
      # 带排除的
      local sedcmd="/"$excepts"/!s:"$target":"$result":g"
      # sedcmd="/""$name""/"$excepts"/!s:"$target":"$result":g"
      # echo "$sedcmd"
      # -n 不打印 -e 后接脚本 -i 直接替换
      # sed -i.bak -n -e "$sedcmd" $TARGET_PATH
      local res=$(sed -i "" -e "$sedcmd" $TARGET_PATH)
      printf "  Progressing:[%-50s] %.f%%\r" $name $percent
      if [[ $res = 0 ]]; then
        counts=$(expr $counts + 1)
      fi
    fi
  done < $TEMPFILE_PATH # 输入文件
  printf "\r\n" # 清行
  # STEP 4
  # 修改 `build setting` 的 `Direct usage of 'isa'` 项为YES // keyword: isa
  BUILD_SETTING_TARGET='CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR'
  BUILD_SETTING_REPLACE='CLANG_WARN_DIRECT_OBJC_ISA_USAGE = NO'
  res=$(sed -i "" 's:'"$BUILD_SETTING_TARGET"':'"$BUILD_SETTING_REPLACE"':g' $TARGET_PATH)
  if [[ $res = 0 ]]; then
      counts=$(expr $counts + 1)
      printf "changed Direct usage of \'isa\' to \'NO\'\n"
  fi

  # STEP 5
  # 修改 `Enable Module(C and Objective-C)` 项为 NO // keyword: semantic
  BUILD_SETTING_TARGET='CLANG_ENABLE_MODULES = YES'
  BUILD_SETTING_REPLACE='CLANG_ENABLE_MODULES = NO'
  res=$(sed -i "" 's:'"$BUILD_SETTING_TARGET"':'"$BUILD_SETTING_REPLACE"':g' $TARGET_PATH)
  if [[ $res = 0 ]]; then
      counts=$(expr $counts + 1)
      printf "changed Enable Module(C and Objective-C) to \'NO\'\n"
  fi

  # 打印结果
  printf "\nProgressed %d lines.\n" $counts
}