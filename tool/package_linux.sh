#!/usr/bin/env bash
# 把 Linux 发布构建打成归档。
#
#   ./tool/package_linux.sh                    # 默认：只打应用 bundle，用 pubspec 的版本号
#   ./tool/package_linux.sh 1.4.0              # 指定版本号
#   ./tool/package_linux.sh --offline          # 维护者本地：额外带上本地翻译组件
#   ./tool/package_linux.sh --offline 1.4.0
#   ./tool/package_linux.sh --dry-run          # 只打印会打包的内容，不写文件
#
# 默认产物写到 dist/tune-linux-x64-<version>.tar.gz，根目录就是 bundle 的内容，
# 与 UpdateService.installLinux 读取的形状一致。它不含本地翻译模型：翻译默认走
# 设置页配置的厂商 API，模型是设置页按需下载的可选组件。
# 把产物上传到同版本的 GitHub Release，应用就能自己发现并安装。
#
# --offline 会先跑 tool/prepare_translation.sh，再追加
# translation/models/<model>.gguf、translation/bin/llama-b12274 与 translation/licenses，
# 产物是 dist/tune-linux-x64-<version>-offline.tar.gz，只给没有网络的机器做本地/内网
# 分发。离线包不作为更新附件发布：`-offline` 后缀会让自动更新跳过它。
set -euo pipefail

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
}

here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"

offline=0
dry_run=0
version=""

for arg in "$@"; do
  case "$arg" in
    --offline) offline=1 ;;
    --dry-run) dry_run=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "未知选项：$arg" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$version" ]]; then
        echo "多余的参数：$arg" >&2
        usage >&2
        exit 2
      fi
      version="$arg"
      ;;
  esac
done

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

suffix=""
if [[ "$offline" == 1 ]]; then
  suffix="-offline"
fi
out="$root/dist/tune-linux-x64-$version$suffix.tar.gz"

if [[ "$dry_run" == 1 ]]; then
  echo "bundle：$bundle"
  echo "产物：$out"
  if [[ "$offline" == 1 ]]; then
    for extra in \
      translation/models/qwen2.5-0.5b-instruct-q4_k_m.gguf \
      translation/bin/llama-b12274 \
      translation/licenses; do
      if [[ ! -e "$root/$extra" ]]; then
        echo "缺少离线组件：$extra（先从 Release 下载组件包并解压到 translation/）" >&2
        exit 1
      fi
      echo "追加：$extra"
    done
  fi
  exit 0
fi

if [[ "$offline" == 1 ]]; then
  "$here/prepare_translation.sh"
fi

mkdir -p "$root/dist"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

tar -cf "$tmp/bundle.tar" -C "$bundle" .

if [[ "$offline" == 1 ]]; then
  tar -rf "$tmp/bundle.tar" -C "$root" \
    translation/models/qwen2.5-0.5b-instruct-q4_k_m.gguf \
    translation/bin/llama-b12274 \
    translation/licenses
fi

gzip -c "$tmp/bundle.tar" > "$out"

echo "$out"
echo "归档体积：$(stat -c%s "$out") B"
