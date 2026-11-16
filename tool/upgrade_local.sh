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
# 未鉴权的 api.github.com 是 60 次/小时、按 IP 计，共享出口很容易 403；
# 有 token 就带上，没有就退回不鉴权（错误信息里会说明）。
token="${GITHUB_TOKEN:-}"
if [[ -z "$token" ]] && command -v gh >/dev/null 2>&1; then
  token="$(gh auth token 2>/dev/null || true)"
fi
auth=()
[[ -n "$token" ]] && auth=(-H "Authorization: token $token")
if ! release="$(curl -fsSL "${auth[@]}" https://api.github.com/repos/pengtang1024/tune/releases/latest)"; then
  echo "读不到 GitHub 的发布信息（未鉴权时限额 60 次/小时）。" >&2
  echo "设一个 token 再试：GITHUB_TOKEN=… $0 $*" >&2
  exit 1
fi
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

# 先把清单落盘再校验：tar | grep -q 会让 grep 提前退出、tar 死于 SIGPIPE，
# 在 pipefail 下被当成校验失败，脚本就无声死在这里。
if ! tar -tzf "$tmp/tune.tar.gz" > "$tmp/listing.txt"; then
  echo "下载的归档损坏，重试一次" >&2
  exit 1
fi
if ! grep -qx './tune' "$tmp/listing.txt"; then
  echo "归档不是 bundle 形状（根上没有 ./tune），拒绝安装" >&2
  exit 1
fi

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
  # 发版脚本在自己的 worktree 里跑，然后又把这个目录删掉：直接 nohup 拉起，
  # 应用会继承一个已被删除的当前目录，读配置、读密钥全报 PathNotFound，
  # 启动失败只剩一个空窗口。家目录稳定，先切过去再拉起。
  ( cd "$HOME" && nohup "$install_dir/tune" >/tmp/tune-launch.log 2>&1 & )
  echo "已重启"
fi
