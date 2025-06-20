#!/bin/bash

# 华为云DNS定时更新器 - M4芯片跨平台高性能编译脚本
# 压榨苹果M4芯片性能，一次性编译所有平台

set -e

APP_NAME="dns-updater"
VERSION="1.0.0"
BUILD_TIME=$(date +%Y%m%d%H%M%S)
OUTPUT_DIR="releases"

echo "🚀 启动M4芯片跨平台高性能编译..."
echo "📦 应用名称: $APP_NAME"
echo "🔖 版本号: $VERSION"
echo "⏰ 编译时间: $BUILD_TIME"

# 检测CPU信息
CPU_INFO=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown CPU")
CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo "4")

echo "💻 CPU: $CPU_INFO"
echo "🔥 核心数: $CPU_CORES"

# 设置Go环境变量 - 继续刚才的优化配置
export GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
export GOSUMDB=sum.golang.google.cn
export GOMAXPROCS=$CPU_CORES
export CGO_ENABLED=0

echo ""
echo "⚡ M4芯片性能压榨配置:"
echo "   GOPROXY: $GOPROXY"
echo "   GOMAXPROCS: $GOMAXPROCS"
echo "   CGO_ENABLED: $CGO_ENABLED"
echo ""

# 创建输出目录
mkdir -p $OUTPUT_DIR
rm -rf $OUTPUT_DIR/*

# 编译目标平台和架构
TARGETS=(
    "linux/amd64"
    "linux/arm64"
    "linux/386"
    "windows/amd64"
    "windows/arm64"
    "windows/386"
    "darwin/amd64"
    "darwin/arm64"
    "freebsd/amd64"
    "freebsd/arm64"
    "openbsd/amd64"
    "openbsd/arm64"
    "netbsd/amd64"
    "netbsd/arm64"
)

# 通用编译参数
LDFLAGS="-s -w -X main.Version=$VERSION -X main.BuildTime=$BUILD_TIME"
GCFLAGS="all=-N -l"

echo "🔨 开始跨平台极速编译..."
echo "📋 编译目标: ${#TARGETS[@]} 个平台"
echo ""

# 并行编译函数
compile_target() {
    local target=$1
    local goos=$(echo $target | cut -d'/' -f1)
    local goarch=$(echo $target | cut -d'/' -f2)
    
    # 设置输出文件名
    local output_name="${APP_NAME}_${VERSION}_${goos}_${goarch}"
    if [ "$goos" = "windows" ]; then
        output_name="${output_name}.exe"
    fi
    
    local output_path="$OUTPUT_DIR/$output_name"
    
    echo "🏗️  编译 $goos/$goarch..."
    
    # 记录编译时间
    local start_time=$(date +%s.%N)
    
    # 执行编译
    GOOS=$goos GOARCH=$goarch go build \
        -o "$output_path" \
        -ldflags="$LDFLAGS" \
        -gcflags="$GCFLAGS" \
        -trimpath \
        . 2>/dev/null
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
    
    if [ -f "$output_path" ]; then
        local file_size=$(ls -lh "$output_path" | awk '{print $5}')
        echo "✅ $goos/$goarch 编译成功 (${duration}s, ${file_size})"
    else
        echo "❌ $goos/$goarch 编译失败"
        return 1
    fi
}

# 导出函数以供并行执行
export -f compile_target
export APP_NAME VERSION BUILD_TIME OUTPUT_DIR LDFLAGS GCFLAGS

# 并行编译所有目标（压榨M4芯片所有核心）
printf '%s\n' "${TARGETS[@]}" | xargs -n 1 -P $CPU_CORES -I {} bash -c 'compile_target "{}"'

echo ""
echo "📊 编译结果统计:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "平台/架构           文件名                           大小"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

total_files=0
total_size=0

for target in "${TARGETS[@]}"; do
    goos=$(echo $target | cut -d'/' -f1)
    goarch=$(echo $target | cut -d'/' -f2)
    
    output_name="${APP_NAME}_${VERSION}_${goos}_${goarch}"
    if [ "$goos" = "windows" ]; then
        output_name="${output_name}.exe"
    fi
    
    output_path="$OUTPUT_DIR/$output_name"
    
    if [ -f "$output_path" ]; then
        file_size=$(ls -lh "$output_path" | awk '{print $5}')
        file_size_bytes=$(ls -l "$output_path" | awk '{print $5}')
        printf "%-18s %-32s %s\n" "$goos/$goarch" "$output_name" "$file_size"
        total_files=$((total_files + 1))
        total_size=$((total_size + file_size_bytes))
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 统计: $total_files 个文件，总大小: $(numfmt --to=iec $total_size 2>/dev/null || echo "${total_size} bytes")"

echo ""
echo "🎯 使用方法:"
echo "   # Linux/macOS/FreeBSD:"
echo "   chmod +x $OUTPUT_DIR/${APP_NAME}_${VERSION}_linux_amd64"
echo "   ./$OUTPUT_DIR/${APP_NAME}_${VERSION}_linux_amd64 -version"
echo ""
echo "   # Windows:"
echo "   $OUTPUT_DIR\\${APP_NAME}_${VERSION}_windows_amd64.exe -version"
echo ""
echo "   # 推荐版本："
echo "   Linux x64:   $OUTPUT_DIR/${APP_NAME}_${VERSION}_linux_amd64"
echo "   Linux ARM:   $OUTPUT_DIR/${APP_NAME}_${VERSION}_linux_arm64"  
echo "   Windows x64: $OUTPUT_DIR/${APP_NAME}_${VERSION}_windows_amd64.exe"
echo "   macOS Intel: $OUTPUT_DIR/${APP_NAME}_${VERSION}_darwin_amd64"
echo "   macOS ARM:   $OUTPUT_DIR/${APP_NAME}_${VERSION}_darwin_arm64"

echo ""
echo "🔒 注意: 所有编译产物已添加到 .gitignore，不会被提交到git仓库"
echo "✨ M4芯片性能压榨完成！" 