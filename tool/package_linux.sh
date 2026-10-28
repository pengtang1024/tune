#!/usr/bin/env bash
# 把 Linux 发布构建打成自动更新用的归档。
#
#   ./tool/package_linux.sh                 # 用 pubspec 的版本号
#   ./tool/package_linux.sh 1.4.0           # 指定版本号
#
# 产物写到 dist/tune-linux-x64-<version>.tar.gz，根目录就是 bundle 的内容，
# 与 UpdateService.installLinux 读取的形状一致。把产物上传到同版本的
# GitHub Release，应用就能自己发现并安装。
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"

version="${1:-}"
if [[ -z "$version" ]]; then
  version="$(grep -E '^version:' "$root/pubspec.yaml" | sed 's/^version: *//' | cut -d'+' -f1)"
fi

bundle="$root/build/linux/x64/release/bundle"
if [[ ! -d "$bundle" ]]; then
  echo "找不到发布构建，先跑 flutter build linux --release" >&2
  exit 1
fi

if [[ ! -x "$bundle/tune" ]]; then
  echo "构建产物里没有 tune 可执行文件：$bundle" >&2
  exit 1
fi

mkdir -p "$root/dist"
out="$root/dist/tune-linux-x64-$version.tar.gz"
rm -f "$out"
tar -czf "$out" -C "$bundle" .
echo "$out"
