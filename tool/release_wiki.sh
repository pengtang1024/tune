#!/usr/bin/env bash
# 把发布提交里的 wiki/*.md 同步到三端 wiki。
#
#   ./tool/release_wiki.sh <仓库路径> <提交> <版本>
#
# 只改 wiki 仓库根目录的 Markdown；Home.md 原样保留，跨目录相对链接改写成
# GitHub develop 分支的绝对链接（wiki 仓库里没有 docs/ 那些文件）。
# 凭据走 git credential fill，不落盘。
set -euo pipefail

repo="${1:?用法：release_wiki.sh <仓库路径> <提交> <版本>}"
sha="${2:?}"
version="${3:?}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git -C "$repo" archive "$sha" wiki | tar -x -C "$tmp"
src="$tmp/wiki"
[[ -d "$src" ]] || { echo "提交 $sha 里没有 wiki/ 目录" >&2; exit 1; }

credential() {
  printf 'protocol=https\nhost=%s\n\n' "$1" | git credential fill
}
password_of() { credential "$1" | sed -n 's/^password=//p'; }
user_of() { credential "$1" | sed -n 's/^username=//p'; }

askpass="$tmp/askpass.sh"
cat > "$askpass" <<'EOF'
#!/bin/sh
case "$1" in
  *Username*) printf '%s\n' "${WIKI_USER:-oauth2}" ;;
  *) printf '%s\n' "$WIKI_TOKEN" ;;
esac
EOF
chmod +x "$askpass"

sync_one() {
  local name="$1" url="$2" user="$3" token="$4" dir="$tmp/$1"
  echo "== $name"
  WIKI_USER="$user" WIKI_TOKEN="$token" GIT_ASKPASS="$askpass" GIT_TERMINAL_PROMPT=0 \
    git clone -q "$url" "$dir"
  cp "$src"/*.md "$dir"/
  find "$dir" -maxdepth 1 -type f -name '*.md' ! -name 'Home.md' -print0 \
    | xargs -0 -r sed -i 's#](\.\./#](https://github.com/pengtang1024/tune/blob/develop/#g'
  git -C "$dir" add -A
  if git -C "$dir" diff --cached --quiet; then
    echo "  无变化"
    return 0
  fi
  if [[ "${WIKI_DRY_RUN:-0}" == "1" ]]; then
    echo "  待提交：$(git -C "$dir" diff --cached --name-only | tr '\n' ' ')"
    return 0
  fi
  git -C "$dir" -c user.name="pengtang1024" -c user.email="pengtang1024@users.noreply.github.com" \
    commit -q -m "docs(wiki): 同步 $version 文档更新"
  WIKI_USER="$user" WIKI_TOKEN="$token" GIT_ASKPASS="$askpass" GIT_TERMINAL_PROMPT=0 \
    git -C "$dir" push -q origin HEAD
  echo "  已推送 $(git -C "$dir" rev-parse --short HEAD)"
}

sync_one gitea "https://gitea.iouf.cn/pengtang1024/tune.wiki.git" \
  "$(user_of gitea.iouf.cn)" "$(password_of gitea.iouf.cn)"
sync_one gitee "https://gitee.com/pengtang1024/tune.wiki.git" \
  "$(user_of gitee.com)" "$(password_of gitee.com)"
sync_one github "git@github.com:pengtang1024/tune.wiki.git" "" ""
