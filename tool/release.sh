#!/usr/bin/env bash
# 一条命令走完发版：版本号 → CHANGELOG → 构建打包 → 门禁 → 提交 → 推 develop →
# 合 master + tag → 推三端 → 三端 release → 同步 wiki → purge CDN → 本机升级 → 清理。
#
#   ./tool/release.sh                         # 自动 +1 patch，自动从提交生成说明
#   ./tool/release.sh --version 1.40.0        # 指定版本
#   ./tool/release.sh --notes-file /tmp/notes.md
#   ./tool/release.sh --dry-run               # 只打印要做什么，不改任何文件
#   ./tool/release.sh --no-push               # 构建、门禁、提交、打 tag，不碰远端（本地演练）
#
# 脚本在 origin/develop 上新建隔离 worktree 干活，成功后退掉；失败时保留现场并打印路径。
# 前置条件：改动已经提交进 origin/develop；lib/l10n 的生成物已提交（check.sh 会核对）。
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

VERSION=""
BASE=origin/develop
WORKTREE=""
NOTES=""
NOTES_FILE=""
DRY_RUN=0
NO_PUSH=0
SKIP_BUILD=0
SKIP_GATE=0
SKIP_PUBLISH=0
SKIP_WIKI=0
SKIP_UPGRADE=0
KEEP_WORKTREE=0
RESTART=1
INSTALL_DIR="$HOME/.local/opt/tune"

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="${2:?}"; shift 2 ;;
    --base) BASE="${2:?}"; shift 2 ;;
    --worktree) WORKTREE="${2:?}"; shift 2 ;;
    --notes) NOTES="${2:?}"; shift 2 ;;
    --notes-file) NOTES_FILE="${2:?}"; shift 2 ;;
    --install-dir) INSTALL_DIR="${2:?}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --no-push) NO_PUSH=1; shift ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --skip-gate) SKIP_GATE=1; shift ;;
    --skip-publish) SKIP_PUBLISH=1; shift ;;
    --skip-wiki) SKIP_WIKI=1; shift ;;
    --skip-upgrade) SKIP_UPGRADE=1; shift ;;
    --keep-worktree) KEEP_WORKTREE=1; shift ;;
    --no-restart) RESTART=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'release: 未知参数 %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

log() { printf '\n== %s\n' "$*"; }
die() { printf '\nrelease: %s\n' "$*" >&2; exit 1; }

FLUTTER="${FLUTTER:-flutter}"
DART="${DART:-dart}"
command -v "$FLUTTER" >/dev/null 2>&1 || FLUTTER=/opt/flutter/bin/flutter
command -v "$DART" >/dev/null 2>&1 || DART=/opt/flutter/bin/dart
for tool in "$FLUTTER" "$DART" git curl python3 tar sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || die "缺少命令：$tool"
done
# check.sh 用 FLUTTER=${FLUTTER:-flutter}，必须把解析后的路径传下去。
export FLUTTER DART

git rev-parse --git-dir >/dev/null 2>&1 || die "不在 git 仓库里"
git remote get-url origin >/dev/null 2>&1 || die "没有 origin 远程"
git remote get-url github >/dev/null 2>&1 || die "没有 github 远程"
git remote get-url gitee >/dev/null 2>&1 || die "没有 gitee 远程"

log "同步远端"
git fetch --all --tags --prune -q

BASE_SHA="$(git rev-parse "$BASE")" || die "找不到基线 $BASE"
CURRENT_RAW="$(git show "$BASE:pubspec.yaml" | sed -n 's/^version: //p')"
CURRENT_VERSION="${CURRENT_RAW%%+*}"
CURRENT_BUILD="${CURRENT_RAW#*+}"
[[ "$CURRENT_BUILD" == "$CURRENT_RAW" ]] && CURRENT_BUILD=0

if [[ -z "$VERSION" ]]; then
  major="${CURRENT_VERSION%%.*}"; rest="${CURRENT_VERSION#*.}"
  minor="${rest%%.*}"; patch="${rest#*.}"
  VERSION="$major.$minor.$((patch + 1))"
fi
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "版本号必须是 X.Y.Z：$VERSION"
if [[ "$(printf '%s\n%s\n' "$CURRENT_VERSION" "$VERSION" | sort -V | head -1)" != "$CURRENT_VERSION" || "$VERSION" == "$CURRENT_VERSION" ]]; then
  die "新版本 $VERSION 必须大于当前 $CURRENT_VERSION"
fi
BUILD="$((CURRENT_BUILD + 1))"
TAG="v$VERSION"
DATE="$(date +%F)"
ARCHIVE="dist/tune-linux-x64-$VERSION.tar.gz"
WT="${WORKTREE:-$ROOT/../tune-release-$VERSION}"

if [[ -f "$NOTES_FILE" ]]; then
  NOTES="$(cat "$NOTES_FILE")"
elif [[ -z "$NOTES" ]]; then
  LAST_TAG="$(git describe --tags --abbrev=0 "$BASE" 2>/dev/null || true)"
  if [[ -n "$LAST_TAG" ]]; then
    NOTES="$(git log --no-merges --pretty='- %s' "$LAST_TAG..$BASE" \
      | grep -Ev '^- (chore\(release\)|docs\(wiki\))' || true)"
  fi
  [[ -n "$NOTES" ]] || NOTES="- 维护性更新。"
  NOTES="### 变更

$NOTES"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  cat <<EOF
release 计划（dry-run，不改文件）
  基线      $BASE @ ${BASE_SHA:0:9}
  版本      $VERSION+$BUILD（当前 $CURRENT_VERSION+$CURRENT_BUILD）
  标签      $TAG
  worktree  $WT
  归档      $ARCHIVE
  说明      $(printf '%s' "$NOTES" | head -1)
  推送      $([[ $NO_PUSH -eq 1 ]] && echo 否 || echo "origin / github / gitee")
  发布      $([[ $SKIP_PUBLISH -eq 1 || $NO_PUSH -eq 1 ]] && echo 否 || echo "三端 release + 归档")
  后续      wiki=$([[ $SKIP_WIKI -eq 1 || $NO_PUSH -eq 1 ]] && echo 否 || echo 是) \
upgrade=$([[ $SKIP_UPGRADE -eq 1 ]] && echo 否 || echo 是)
EOF
  exit 0
fi

[[ -e "$WT" ]] && die "目标 worktree 已存在：$WT（先确认是否需要清理）"

TMP="$(mktemp -d)"
cleanup() {
  local status=$?
  cd "$ROOT" 2>/dev/null || true
  if [[ -d "$WT" ]]; then
    if [[ $status -eq 0 && $KEEP_WORKTREE -eq 0 ]]; then
      git worktree remove --force "$WT" >/dev/null 2>&1 || true
      git branch -D "release/$VERSION" "master-release-$VERSION" >/dev/null 2>&1 || true
      printf '\n== 清理\n已移除 worktree %s 与临时分支\n' "$WT"
    else
      printf '\n== 保留现场\n%s\n' "$WT"
    fi
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

log "创建隔离 worktree"
git worktree add -B "release/$VERSION" "$WT" "$BASE" >/dev/null
cd "$WT"

if grep -q "^## \[$VERSION\]" CHANGELOG.md; then
  log "CHANGELOG 已有 $VERSION 段，沿用"
else
  log "写入 CHANGELOG $VERSION 段"
  printf '%s\n' "$NOTES" > "$TMP/notes.md"
  python3 - "$VERSION" "$DATE" "$TMP/notes.md" <<'PY'
import sys
version, date, notes_path = sys.argv[1], sys.argv[2], sys.argv[3]
lines = open('CHANGELOG.md', encoding='utf-8').read().splitlines()
body = open(notes_path, encoding='utf-8').read().strip().splitlines()
entry = [f'## [{version}] - {date}', ''] + body + ['']
index = next((i for i, line in enumerate(lines) if line.startswith('## [')), None)
if index is None:
    lines.extend([''] + entry)
else:
    lines[index:index] = entry + ['']
open('CHANGELOG.md', 'w', encoding='utf-8').write('\n'.join(lines).rstrip() + '\n')
PY
fi

log "更新版本号"
python3 - "$VERSION" "$BUILD" "$DATE" <<'PY'
import re
import sys
version, build, date = sys.argv[1], int(sys.argv[2]), sys.argv[3]

def sub(path, pattern, repl, required=True):
    text = open(path, encoding='utf-8').read()
    new, count = re.subn(pattern, repl, text, count=1, flags=re.M)
    if required and count != 1:
        sys.exit(f'{path}: 没有可替换的版本标记')
    open(path, 'w', encoding='utf-8').write(new)

sub('pubspec.yaml', r'^version: .*$', f'version: {version}+{build}')
sub('lib/config/app_version.dart', r"static const String version = '[^']*';", f"static const String version = '{version}';")
sub('lib/config/app_version.dart', r'static const int buildNumber = \d+;', f'static const int buildNumber = {build};')
sub('lib/config/app_version.dart', r"static const String buildDate = '[^']*';", f"static const String buildDate = '{date}';")
for path in ('README.md', 'README_en.md', 'wiki/README.md'):
    sub(path, r'\d+\.\d+\.\d+\+\d+', f'{version}+{build}')
sub('CITATION.cff', r'^version: "[^"]*"$', f'version: "{version}"')
PY

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  log "构建 Linux release"
  "$FLUTTER" build linux --release
  log "打包并写清单"
  DART="$DART" ./tool/package_linux.sh
  "$DART" run tool/write_version_manifest.dart --archive "$ARCHIVE" --root >/dev/null
else
  log "跳过构建（--skip-build），归档与清单不更新"
fi
[[ -f "$ARCHIVE" ]] || die "没有生成归档：$ARCHIVE"
[[ -f version.json ]] || die "没有生成根 version.json"

if [[ "$SKIP_GATE" -eq 0 ]]; then
  log "跑门禁 ./tool/check.sh --l10n --tools --docs"
  ./tool/check.sh --l10n --tools --docs 2>&1 | tee "$TMP/gate.log"
else
  log "跳过门禁（--skip-gate）"
fi

log "提交发版改动"
git add -- pubspec.yaml lib/config/app_version.dart CHANGELOG.md README.md README_en.md wiki/README.md CITATION.cff version.json
git commit -q -m "chore(release): $VERSION 更新清单与 Linux 归档"
RELEASE_SHA="$(git rev-parse HEAD)"

if [[ "$NO_PUSH" -eq 1 ]]; then
  log "本地演练完成（--no-push）"
  git tag -a "$TAG" -m "$VERSION" "$RELEASE_SHA"
  printf '提交 %s\n标签 %s（未推送）\n' "$RELEASE_SHA" "$TAG"
else
  log "推送 develop"
  [[ "$(git rev-parse "$BASE")" == "$BASE_SHA" ]] || die "$BASE 在构建期间前进了（$BASE_SHA → $(git rev-parse "$BASE")），归档已过期；保留现场请重跑"
  git push origin "$RELEASE_SHA:refs/heads/develop"

  log "合并 master 并打 tag"
  git fetch origin --tags -q
  git checkout -B "master-release-$VERSION" origin/master >/dev/null 2>&1
  git merge --no-ff "$RELEASE_SHA" -m "Merge branch 'develop' for $TAG" >/dev/null
  MERGE_SHA="$(git rev-parse HEAD)"
  git tag -a "$TAG" -m "$TAG" "$MERGE_SHA"

  log "推送三端（master + tag）"
  for remote in origin github gitee; do
    git fetch "$remote" --tags -q
    git merge-base --is-ancestor "$remote/develop" "$RELEASE_SHA" \
      || die "$remote/develop 有本地没有的提交，先同步再发"
    git merge-base --is-ancestor "$remote/master" "$MERGE_SHA" \
      || die "$remote/master 与本地分叉，先同步再发"
    git push "$remote" "$RELEASE_SHA:refs/heads/develop" >/dev/null
    git push "$remote" "$MERGE_SHA:refs/heads/master" >/dev/null
    git push "$remote" "refs/tags/$TAG" >/dev/null
    printf '  %-7s develop=%s master=%s tag=%s\n' "$remote" "${RELEASE_SHA:0:9}" "${MERGE_SHA:0:9}" "$TAG"
  done
  for remote in origin github gitee; do
    remote_sha="$(git ls-remote --tags "$remote" "refs/tags/$TAG^{}" | cut -f1)"
    [[ "$remote_sha" == "$MERGE_SHA" ]] || die "$remote 的 $TAG 指向 $remote_sha，不是 $MERGE_SHA"
  done

  if [[ "$SKIP_PUBLISH" -eq 0 ]]; then
    log "创建三端 release 并上传归档"
    python3 tool/release_publish.py --version "$VERSION" --tag "$TAG" \
      --commit "$MERGE_SHA" --archive "$ARCHIVE" --manifest version.json
  fi

  if [[ "$SKIP_WIKI" -eq 0 ]]; then
    log "同步三端 wiki"
    ./tool/release_wiki.sh "$WT" "$MERGE_SHA" "$VERSION"
  fi

  log "purge CDN 并复核"
  curl -fsS "https://purge.jsdelivr.net/gh/pengtang1024/tune@master/version.json" >/dev/null || true
  sleep 5
  curl -fsS "https://purge.jsdelivr.net/gh/pengtang1024/tune@master/version.json" >/dev/null || true
  for attempt in 1 2 3 4 5 6; do
    raw="$(curl -fsS "https://raw.githubusercontent.com/pengtang1024/tune/master/version.json" 2>/dev/null || true)"
    cdn="$(curl -fsS "https://cdn.jsdelivr.net/gh/pengtang1024/tune@master/version.json?ts=$(date +%s)" 2>/dev/null || true)"
    raw_v="$(printf '%s' "$raw" | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])' 2>/dev/null || true)"
    cdn_v="$(printf '%s' "$cdn" | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])' 2>/dev/null || true)"
    printf '  第 %s 次：raw=%s cdn=%s\n' "$attempt" "${raw_v:-?}" "${cdn_v:-?}"
    [[ "$raw_v" == "$VERSION" && "$cdn_v" == "$VERSION" ]] && break
    sleep 15
  done
  [[ "$raw_v" == "$VERSION" ]] || printf '\n警告：raw.githubusercontent.com 仍是 %s；清单可能还在传播，稍后用 docs/updates.md 的自检清单复核\n' "${raw_v:-空}"
  [[ "$cdn_v" == "$VERSION" ]] || printf '\n警告：jsDelivr 仍是 %s（purge finished 不等于边缘已更新）；raw 正确即可，客户端 raw 优先\n' "${cdn_v:-空}"

  if [[ "$SKIP_UPGRADE" -eq 0 ]]; then
    log "升级本机安装"
    args=("$INSTALL_DIR")
    [[ "$RESTART" -eq 1 ]] && args+=(--restart)
    ./tool/upgrade_local.sh "${args[@]}" || printf '\n警告：本机升级失败，发布已完成，可稍后手动跑 tool/upgrade_local.sh\n' 
  fi
fi

log "完成"
printf '版本 %s+%s  提交 %s  标签 %s\n' "$VERSION" "$BUILD" "${RELEASE_SHA:0:9}" "$TAG"
