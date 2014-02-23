# !/bin/sh

# 目标：
# 1. 把 framework 文件夹下的所有文件名按行输出到 temp 文件
# 2. 按行遍历 temp 文件，同时做以下处理
#   1. 在 project.pbxproj 文件里找到匹配文件名的 `compile flags` 行
#   2. 在 `compile flags` 里加上  `settings = {COMPILER_FLAGS = "-fno-objc-arc"; };`
#   3. 效果如下:
#        E95B5B3118B59E64009491EE /* Bee_Package.m in Sources */ = {isa = PBXBuildFile; fileRef = E95B585918B59E63009491EE /* Bee_Package.m */; };
#        =》
#        E95B5C0D18B59E64009491EE /* Bee_Package.m in Sources */ = {isa = PBXBuildFile; fileRef = E95B5A4118B59E64009491EE /* Bee_Package.m */; settings = {COMPILER_FLAGS = "-fno-objc-arc"; }; };

# 匹配模式
# TARGET_PATTER='/* '.'Bee_Package.mm'.' in Sources */ = '
# TARGET_PATTER="(fileRef = \w+ /* "${name}" \*/;)"

# 声明变量
# SORC_FILENAME_PATH="framework"
SORC_FILENAME_PATH="framework"
TARG_FILENAME_PATH="reew.xcodeproj/project.pbxproj"
TEMP_FILENAME_PATH="temp.txt"
FILE_BLACKLIST='\.h$|\.DS_Store|\.sh$|\.png$|\.svn$'

# STEP 1
> $TEMP_FILENAME_PATH # 清空临时文件

# STEP 2
find $SORC_FILENAME_PATH -type f -print | # 获取所有文件名
grep -E -v $FILE_BLACKLIST > $TEMP_FILENAME_PATH # 根据黑名单过滤文件名并写入文件
# |              
# while read line; do
# name=`basename $line`
# if [ "$name" != "" ]; then
#   echo "$name" >> $TEMP_FILENAME_PATH     # 写入文件
# fi
# done

# # STEP 3.1

# 获取需要处理的总行数，供进度条用
ALL_LINES=$(cat < $TEMP_FILENAME_PATH | wc -l|tr -d " ")
# echo $ALL_LINES
# 保存处理过的数量
PROGRESSED_LINES=0
# # STEP 3.2

# 遍历获取到的文件名
cp $TARG_FILENAME_PATH $TARG_FILENAME_PATH.bak
  # 遍历每一行，文件路径
i=0
while read line; do
  i=$(expr $i + 1)
  # echo $i
  # percent=`awk "BEGIN{ print $i / $ALL_LINES }"`
  percent=$(echo "($i/$ALL_LINES*100)" | bc -l) # 获取当前百分比
  # echo $percent
  # 取文件名
  name=$(basename "$line")
  # 当文件名不为空时处理
  if [ "$name" != "" ]; then
    # echo $name
    excepts="-fno-objc-arc"
    pattern="fileRef = [A-Z0-9]\{1,\} /\* "$name" \*/;"
    # echo $pattern
    target="\("$pattern"\)"
    # echo "$target"
    result="\1 settings = {COMPILER_FLAGS = \"-fno-objc-arc\"; };"
    # echo "$result"
    # 替换并打印，但不写入文件
    # sedcmd="s:"$target":"$result":g" # g 全局替换
    # sedcmd="s:"$target":"$result":p" # p 打印编辑行
    # 带排除的
    sedcmd="/"$excepts"/!s:"$target":"$result":g"
    # sedcmd="/""$name""/"$excepts"/!s:"$target":"$result":g"
    # echo "$sedcmd"
    # -n 不打印 -e 后接脚本 -i 直接替换
    # sed -i.bak -n -e "$sedcmd" $TARG_FILENAME_PATH
    res=$(sed -i "" -e "$sedcmd" $TARG_FILENAME_PATH)
    printf "  Progressing:[%-50s] %.f%%\r" $name $percent
    if [[ $res = 0 ]]; then
      PROGRESSED_LINES=$(expr $PROGRESSED_LINES + 1)
    fi
  fi
done < $TEMP_FILENAME_PATH # 输入文件
printf "\r\n" # 清行
# STEP 4
# 修改 `build setting` 的 `Direct usage of 'isa'` 项为YES // keyword: isa
BUILD_SETTING_TARGET='CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR'
BUILD_SETTING_REPLACE='CLANG_WARN_DIRECT_OBJC_ISA_USAGE = NO'
res=$(sed -i "" 's:'"$BUILD_SETTING_TARGET"':'"$BUILD_SETTING_REPLACE"':g' $TARG_FILENAME_PATH)
if [[ $res = 0 ]]; then
    PROGRESSED_LINES=$(expr $PROGRESSED_LINES + 1)
    printf "changed Direct usage of \'isa\' to \'NO\'\n"
fi

# STEP 5
# 修改 `Enable Module(C and Objective-C)` 项为 NO // keyword: semantic
BUILD_SETTING_TARGET='CLANG_ENABLE_MODULES = YES'
BUILD_SETTING_REPLACE='CLANG_ENABLE_MODULES = NO'
res=$(sed -i "" 's:'"$BUILD_SETTING_TARGET"':'"$BUILD_SETTING_REPLACE"':g' $TARG_FILENAME_PATH)
if [[ $res = 0 ]]; then
    PROGRESSED_LINES=$(expr $PROGRESSED_LINES + 1)
    printf "changed Enable Module(C and Objective-C) to \'NO\'\n"
fi

# 打印结果
printf "\nProgressed %d lines.\n" $PROGRESSED_LINES