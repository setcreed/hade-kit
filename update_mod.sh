#!/bin/bash
# 跨平台Go依赖更新脚本，Windows(Git Bash)/Mac/Linux 通用
export GOPROXY=https://goproxy.cn,direct
echo "[环境] GOPROXY=$GOPROXY"

# 识别系统
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "[系统] Windows(Git Bash)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "[系统] macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "[系统] Linux"
fi

# 校验go.mod存在
if [ ! -f "./go.mod" ]; then
    echo "ERROR: 当前目录无 go.mod 文件"
    exit 1
fi

# 【修复核心】精准过滤，只提取合法依赖，过滤掉 `(` / `)`
# 匹配规则：行首空格 + 模块地址 + 版本号，排除括号
DEPS=$(awk '/^\s+[a-zA-Z0-9]+\.[a-zA-Z]+\/[a-zA-Z0-9]/ {print $1}' go.mod)

echo "[读取依赖列表]"
echo "$DEPS"

# 更新模式参数
GET_ARG="-u=patch"
if [ "$1" = "--full" ]; then
    GET_ARG="-u"
    echo "[更新模式] 全量升级(包含大版本，谨慎使用)"
else
    echo "[更新模式] 仅补丁升级(稳定无破坏性)"
fi

# 循环更新依赖
for dep in $DEPS; do
    echo "==== 更新 $dep ===="
    go get $GET_ARG "$dep"
    if [ $? -ne 0 ]; then
        echo "⚠️ 警告：$dep 更新失败，跳过继续下一个依赖"
    fi
done

# 清理+校验
echo "==== 执行 go mod tidy ===="
go mod tidy

echo "==== 执行 go mod verify ===="
go mod verify

echo "✅ 全部依赖更新流程执行完成"