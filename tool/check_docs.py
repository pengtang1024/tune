#!/usr/bin/env python3
"""Markdown style checker for this repository.

The rules live in docs/document-style.md. Run without arguments to check the whole
repository, or pass file paths to check a subset:

    python3 tool/check_docs.py
    python3 tool/check_docs.py docs/architecture.md

Exit code 0 means every checked page is structurally sound; 1 lists what to fix.
Checks are mechanical on purpose: anything subjective belongs to review, not here.
"""

from __future__ import annotations

import re
import sys
import urllib.parse
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Third-party and dated artifacts keep their own conventions; do not rewrite them.
EXEMPT_PREFIXES = ("vendor/", "2026-11-04/", ".lingma/", ".trae/")
# Release log and license have their own fixed shape.
EXEMPT_FILES = ("CHANGELOG.md", "LICENSE", ".github/PULL_REQUEST_TEMPLATE.md")
# Generated or platform-project trees never hold authored documentation.
SKIP_PARTS = {
    ".git",
    "build",
    ".dart_tool",
    "node_modules",
    "dist",
    "android",
    "ios",
    "linux",
    "windows",
    "web",
    "macos",
}
# History pages carry an intent from a past version; they get a banner, not a rewrite.
HISTORY_PREFIX = "需求/历史/"
# Index pages list links instead of pointing at related documents.
INDEX_PAGES = ("docs/README.md", "需求/README.md", "wiki/README.md", "需求/历史/README.md")

VALID_STATUS = re.compile(
    r"^>\s*状态：(契约|规范|设计（已实施）|方案（未实施）|"
    r"快照（\d{4}-\d{2}-\d{2}）|历史（不具约束力）|索引|入口)"
)
LONG_PAGE_LINES = 120
LONG_PAGE_H2 = 8
MAX_PLAIN_RUN = 7  # 8 consecutive wrapped plain lines is a wall of text


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def slugify(heading: str) -> str:
    text = re.sub(r"`([^`]*)`", r"\1", heading)
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"[\*~]", "", text)
    text = text.strip().lower()
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


def strip_fenced(lines: list[str]) -> list[str]:
    """Blank out fenced code so rules never read code as prose."""
    out: list[str] = []
    fence = False
    for line in lines:
        if line.lstrip().startswith("```"):
            fence = not fence
            out.append("")
        else:
            out.append("" if fence else line)
    return out


def split_row(line: str) -> list[str]:
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|") and not body.endswith("\\|"):
        body = body[:-1]
    return re.split(r"(?<!\\)\|", body)


def check(path: Path) -> list[str]:
    issues: list[str] = []
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    prose = strip_fenced(lines)
    name = rel(path)

    h1 = [(i, l) for i, l in enumerate(prose) if re.match(r"^# \S", l)]
    if not h1:
        issues.append("缺少 H1 标题")
    elif len(h1) > 1:
        issues.append(
            "H1 重复 %d 次（第 %s 行）" % (len(h1), "、".join(str(i + 1) for i, _ in h1))
        )

    head = [l for l in lines if not l.lstrip().startswith("```")][:8]
    if not any(VALID_STATUS.match(l) for l in head):
        issues.append("H1 下缺状态行（> 状态：契约 · 适用版本 … · 最后核对 …）")
    else:
        status = next(l for l in head if VALID_STATUS.match(l))
        if "适用版本" not in status and "索引" not in status and "入口" not in status:
            issues.append("状态行缺「适用版本」")

    h2_titles = [l[3:].strip() for l in prose if l.startswith("## ")]
    prose_lines = len(lines)
    needs_toc = prose_lines > LONG_PAGE_LINES or len(h2_titles) >= LONG_PAGE_H2
    toc_titles = {l[3:].strip() for l in prose if l.startswith("## ")}
    has_toc = "目录" in toc_titles or "Contents" in toc_titles
    if needs_toc and not has_toc:
        issues.append(
            "长页（%d 行 / %d 个 H2）缺「## 目录」" % (prose_lines, len(h2_titles))
        )
    if has_toc:
        anchors = {slugify(t) for t in h2_titles}
        anchors |= {slugify(t) for t in (l[3:].strip() for l in prose if l.startswith("### "))}
        for m in re.finditer(r"^\s*[-*]\s+\[[^\]]+\]\(#([^)]+)\)", text, re.M):
            if m.group(1) not in anchors:
                issues.append("目录锚点不可达：#%s" % m.group(1))

    level = 0
    for i, line in enumerate(prose):
        m = re.match(r"^(#{1,6})\s+\S", line)
        if not m:
            continue
        cur = len(m.group(1))
        if level and cur > level + 1:
            issues.append("标题跳级：第 %d 行 H%d 紧接在 H%d 之后" % (i + 1, cur, level))
        level = cur

    fence_open = False
    for i, line in enumerate(lines):
        if not line.lstrip().startswith("```"):
            continue
        if not fence_open:
            if not line.strip()[3:].strip():
                issues.append("第 %d 行代码块未标语言（无语言的用 text）" % (i + 1))
            fence_open = True
        else:
            fence_open = False

    for m in re.finditer(r"file:///", text):
        lineno = text[: m.start()].count("\n") + 1
        issues.append("第 %d 行出现绝对路径 file:///" % lineno)

    for m in re.finditer(r"!?\[[^\]]*\]\(([^)\s]+)\)", text):
        target = m.group(1)
        if re.match(r"^(https?:|mailto:|#)", target):
            continue
        target_path = urllib.parse.unquote(target.split("#")[0])
        if not target_path:
            continue
        if not (path.parent / target_path).resolve().exists():
            lineno = text[: m.start()].count("\n") + 1
            issues.append("第 %d 行链接目标不存在：%s" % (lineno, target))

    i = 0
    while i < len(prose):
        if not prose[i].strip().startswith("|"):
            i += 1
            continue
        start = i
        block: list[str] = []
        while i < len(prose) and prose[i].strip().startswith("|"):
            block.append(prose[i])
            i += 1
        if len(block) >= 2:
            width = len(split_row(block[0]))
            for row in block[1:]:
                if len(split_row(row)) != width:
                    issues.append(
                        "第 %d 行起的表格列数不一致（表头 %d 列）" % (start + 1, width)
                    )
                    break

    run = 0
    for i, line in enumerate(prose):
        s = line.strip()
        plain = bool(s) and not s.startswith(
            ("#", "-", "*", "|", ">", "```", "!", "<", "[", "+")
        ) and not re.match(r"^\d+[.)]\s", s)
        run = run + 1 if plain else 0
        if run == MAX_PLAIN_RUN + 1:
            issues.append(
                "第 %d 行起连续 %d 行纯文字，拆成列表或表格" % (i + 1, MAX_PLAIN_RUN + 1)
            )
            run = 0

    is_history = name.startswith(HISTORY_PREFIX) or any(
        "历史（不具约束力）" in l for l in head
    )
    if (
        name not in INDEX_PAGES
        and not is_history
        and "相关文档" not in toc_titles
        and "Related" not in toc_titles
    ):
        issues.append("缺「## 相关文档」收尾")

    return issues


def main(argv: list[str]) -> int:
    if argv:
        targets = [Path(a).resolve() for a in argv]
    else:
        targets = sorted(ROOT.rglob("*.md"))

    checked = 0
    failures = 0
    for path in targets:
        if not path.is_file() or path.suffix != ".md":
            continue
        if not path.is_relative_to(ROOT):
            continue
        parts = path.relative_to(ROOT).parts
        if set(parts) & SKIP_PARTS:
            continue
        name = path.relative_to(ROOT).as_posix()
        if any(name.startswith(p) for p in EXEMPT_PREFIXES) or name in EXEMPT_FILES:
            continue
        checked += 1
        issues = check(path)
        if issues:
            failures += 1
            print("%s" % name)
            for issue in issues:
                print("  - %s" % issue)

    if failures:
        print(
            "\n%d / %d 份文档不符合 docs/document-style.md" % (failures, checked)
        )
        return 1
    print("checked %d documents: all conform to docs/document-style.md" % checked)
    return 0


if __name__ == "__main__":
    if Path.cwd() != ROOT:
        pass
    sys.exit(main(sys.argv[1:]))
