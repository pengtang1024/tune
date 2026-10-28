#!/usr/bin/env bash
# 把本地安装升级到最新发布版。
#
# 只对 1.5.0 之前的版本需要：它们还没有「检查更新」入口，只能用这个脚本
# 装一次；1.5.0 之后应用自己会更新。
#
#   ./tool/upgrade_local.sh                       # 升级 ~/.local/opt/tune
#   ./tool/upgrade_local.sh ~/Applications/tune   # 指定安装目录
#   ./tool/upgrade_local.sh <目录> --restart      # 升级后重启应用
set -euo pipefail

install_dir="${1:-$HOME/.local/opt/tune}"
restart="${2:-}"

if [[ ! -x "$install_dir/tune" ]]; then
  echo "找不到安装目录里的 tune：$install_dir" >&2
  exit 1
fi

echo "读取最新发布…"
release="$(curl -fsSL https://api.github.com/repos/pengtang1024/tune/releases/latest)"
url="$(printf '%s' "$release" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(next(a["browser_download_url"] for a in data["assets"] if "linux" in a["name"]))
')"
version="$(printf '%s' "$release" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
echo "下载 $version…"
curl -fsSL "$url" -o "$tmp/tune.tar.gz"
tar -tzf "$tmp/tune.tar.gz" | grep -qx './tune'

backup="${install_dir}.previous"
echo "备份到 $backup"
rm -rf "$backup"
mv "$install_dir" "$backup"
mkdir -p "$install_dir"
tar -xzf "$tmp/tune.tar.gz" -C "$install_dir"

if [[ ! -x "$install_dir/tune" ]]; then
  echo "新包解压失败，恢复旧版本" >&2
  rm -rf "$install_dir"
  mv "$backup" "$install_dir"
  exit 1
fi
echo "已升级到 $version，旧版本留在 $backup"

if [[ "$restart" == "--restart" ]]; then
  pid="$(pgrep -f "$install_dir/tune" | head -1 || true)"
  if [[ -n "$pid" ]]; then kill "$pid"; sleep 2; fi
  nohup "$install_dir/tune" >/tmp/tune-launch.log 2>&1 &
  echo "已重启"
fi
