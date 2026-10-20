#!/usr/bin/env bash
# 把构建产物里的桌面项与图标装进本机的 XDG 目录，
# 让 dock 与任务栏显示 Tune 的图标。
#
#   ./linux/install-desktop-entry.sh                 # 用最近一次构建
#   ./linux/install-desktop-entry.sh <bundle 目录>   # 指定构建产物
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"

bundle="${1:-}"
if [[ -z "$bundle" ]]; then
  for candidate in "$root"/build/linux/x64/*/bundle; do
    if [[ -d "$candidate/share/applications" ]]; then
      bundle="$candidate"
    fi
  done
fi

if [[ ! -d "$bundle/share/applications" ]]; then
  echo "找不到构建产物里的桌面项，先跑 flutter build linux --debug" >&2
  exit 1
fi

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
cp -r "$bundle/share/." "$data_home/"

if command -v update-desktop-database >/dev/null; then
  update-desktop-database "$data_home/applications"
fi
if command -v gtk-update-icon-cache >/dev/null; then
  gtk-update-icon-cache -f -t "$data_home/icons/hicolor"
fi

for entry in "$data_home"/applications/*.desktop; do
  case "$(basename "$entry")" in
    *iouf.tune*) echo "装好了：$entry" ;;
  esac
done
