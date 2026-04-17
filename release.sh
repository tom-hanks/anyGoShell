#!/bin/bash
# anyGoShell 自动发布脚本
# 用法: ./release.sh <版本号>
# 例如: ./release.sh 1.0.1

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "❌ 请提供版本号"
    echo "用法: ./release.sh <版本号>"
    echo "例如: ./release.sh 1.0.1"
    exit 1
fi

# 验证版本号格式
if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ 版本号格式错误，应为 x.x.x 格式（如 1.0.1）"
    exit 1
fi

echo "🚀 开始发布 v$VERSION..."
echo ""

# 1. 更新 Info.plist 版本号
echo "📝 更新 Info.plist 版本号..."
sed -i '' "s/<string>[0-9]*\.[0-9]*\.[0-9]*<\/string>/<string>$VERSION<\/string>/" Resources/Info.plist
echo "✅ Info.plist 已更新为 $VERSION"

# 2. 构建 Release 版本
echo ""
echo "🔨 构建 Release 版本..."
make build
echo "✅ 构建完成"

# 3. 打包 zip
echo ""
echo "📦 打包应用..."
rm -rf build
mkdir -p build
cd .build && zip -r ../build/anyGoShell.zip anyGoShell.app
cd ..
echo "✅ 已打包: build/anyGoShell.zip"

# 4. 计算 SHA256
echo ""
echo "🔐 计算 SHA256..."
shasum -a 256 build/anyGoShell.zip
echo ""

# 5. Git 提交
echo ""
echo "📋 Git 提交..."
git add Resources/Info.plist
git commit -m "release: v$VERSION" || echo "⚠️  没有变更需要提交"
git tag -a "v$VERSION" -m "Release v$VERSION" || echo "⚠️  tag v$VERSION 已存在"
echo "✅ Git 提交和 tag 完成"

# 6. 提示 GitHub Release 操作
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 准备工作完成！"
echo ""
echo "接下来请手动完成 GitHub Release："
echo ""
echo "1. 推送代码和 tag:"
echo "   git push origin main"
echo "   git push origin v$VERSION"
echo ""
echo "2. 在 GitHub 创建 Release:"
echo "   https://github.com/tom-hanks/anyGoShell/releases/new"
echo ""
echo "   - Tag: v$VERSION"
echo "   - Title: v$VERSION"
echo "   - 上传文件: build/anyGoShell.zip"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"