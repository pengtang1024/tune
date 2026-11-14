#!/usr/bin/env bash
# 准备离线包（tool/package_linux.sh --offline）使用的本地翻译资产。
#
#   ./tool/prepare_translation.sh
#
# 默认发布包不再包含这些资产：模型与运行时作为可选组件包单独发布，由应用在设置页
# 按需下载。本脚本只给维护者本地打离线包时调用。
#
# 模型与 llama.cpp 运行时归档不再入库（原先由 Git LFS 管理），改为 Release 上的
# 可选组件包。本脚本只校验、解包，不联网，需要维护者先把组件包里的
# translation/models/ 与 translation/bin/ 放到仓库的 translation/ 下：
#   1. 校验大小与 sha256；
#   2. 把运行时归档解包到 translation/bin/llama-b12274/（幂等）。
# 任何一步失败都直接退出，避免打出缺模型的坏包。
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"
translation="$root/translation"

model="$translation/models/qwen2.5-0.5b-instruct-q4_k_m.gguf"
model_bytes=491400032
model_sha=74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db

archive="$translation/bin/llama-b12274-bin-ubuntu-x64.tar.gz"
archive_bytes=23287295
archive_sha=5f9de4d104502b38fdb1081d00087683ca224ca5c450eaba4eeb436b9a1bcd94
runtime="$translation/bin/llama-b12274"

hint="请先从同版本的 Release 下载组件包（tune-translation-*.zip）并解压到 translation/"

fail() {
  echo "$1" >&2
  exit 1
}

verify() {
  local path="$1" expected_bytes="$2" expected_sha="$3" label="$4"
  [[ -f "$path" ]] || fail "缺少$label：$path。$hint"
  local actual_bytes
  actual_bytes="$(stat -c%s "$path")"
  [[ "$actual_bytes" == "$expected_bytes" ]] ||
    fail "$label 大小不符：$actual_bytes != $expected_bytes。$hint"
  local actual_sha
  actual_sha="$(sha256sum "$path" | cut -d' ' -f1)"
  [[ "$actual_sha" == "$expected_sha" ]] ||
    fail "$label sha256 不符：$actual_sha。$hint"
  echo "$label 校验通过（$actual_bytes B，sha256 $actual_sha）"
}

verify "$model" "$model_bytes" "$model_sha" "离线翻译模型"
verify "$archive" "$archive_bytes" "$archive_sha" "llama.cpp 运行时归档"

if [[ ! -x "$runtime/llama-cli" ]]; then
  echo "解包 llama.cpp 运行时至 $runtime"
  rm -rf "$runtime"
  mkdir -p "$runtime"
  tar -xzf "$archive" -C "$runtime" --strip-components=1
  chmod -R u+rwX,go+rX "$runtime"
fi

[[ -x "$runtime/llama-cli" ]] ||
  fail "解包后找不到可执行的 llama-cli：$runtime/llama-cli"

echo "运行时：$(du -sh "$runtime" | cut -f1)"
echo "模型：$(du -h "$model" | cut -f1)"
