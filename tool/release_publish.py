#!/usr/bin/env python3
"""给三端建 release 并上传 Linux 归档。

由 tool/release.sh 调用，也可单独跑：

    python3 tool/release_publish.py --version 1.40.0 --tag v1.40.0 \
        --commit <sha> --archive dist/tune-linux-x64-1.40.0.tar.gz --manifest version.json

凭据来源：GitHub 用 GITHUB_TOKEN 或 `gh auth token`；Gitea / Gitee 用
`git credential fill`（host 分别是 gitea.iouf.cn 与 gitee.com），也可用
GITEA_TOKEN / GITEE_TOKEN 覆盖。脚本幂等：release 与同名资产已存在就跳过。
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid

REPO = "pengtang1024/tune"
GITHUB = "https://api.github.com"
GITEA = "https://gitea.iouf.cn/api/v1"
GITEE = "https://gitee.com/api/v5"


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout


def git_credential(host):
    text = subprocess.run(
        ["git", "credential", "fill"],
        input=f"protocol=https\nhost={host}\n\n",
        capture_output=True,
        text=True,
        check=True,
        env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
    ).stdout
    values = dict(line.split("=", 1) for line in text.splitlines() if "=" in line)
    return values.get("username", ""), values.get("password", "")


def http(method, url, token="", data=None, headers=None, timeout=180):
    body = data
    request_headers = {"User-Agent": "tune-release", **(headers or {})}
    if isinstance(body, (dict, list)):
        body = json.dumps(body).encode()
        request_headers.setdefault("Content-Type", "application/json")
    if token:
        request_headers.setdefault("Authorization", f"token {token}")
    request = urllib.request.Request(url, data=body, headers=request_headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()


def fail(message):
    print(f"  release: {message}", file=sys.stderr)
    return False


def github_token():
    token = os.environ.get("GITHUB_TOKEN", "")
    if not token:
        try:
            token = run(["gh", "auth", "token"]).strip()
        except (OSError, subprocess.CalledProcessError):
            token = ""
    return token


def publish_asset(platform, token, release_id, archive, asset_name, upload_url=None):
    if platform == "github":
        status, body = http("GET", f"{GITHUB}/repos/{REPO}/releases/{release_id}/assets", token)
        if status == 200 and any(a["name"] == asset_name for a in json.loads(body)):
            print("  github: 归档已存在，跳过上传")
            return True
        base = upload_url or f"https://uploads.github.com/repos/{REPO}/releases/{release_id}/assets"
        url = f"{base.split('{')[0]}?name={urllib.parse.quote(asset_name)}"
        status, body = http(
            "POST", url, token, open(archive, "rb").read(),
            {"Content-Type": "application/octet-stream"},
        )
        return status in (200, 201) or fail(f"github 上传失败 HTTP {status}: {body[:200]!r}")

    if platform == "gitea":
        status, body = http("GET", f"{GITEA}/repos/{REPO}/releases/{release_id}/assets", token)
        if status == 200 and any(a["name"] == asset_name for a in json.loads(body)):
            print("  gitea: 归档已存在，跳过上传")
            return True
        status, body = http(
            "POST",
            f"{GITEA}/repos/{REPO}/releases/{release_id}/assets?name={urllib.parse.quote(asset_name)}",
            token,
            open(archive, "rb").read(),
            {"Content-Type": "application/octet-stream"},
        )
        return status in (200, 201) or fail(f"gitea 上传失败 HTTP {status}: {body[:200]!r}")

    # Gitee：multipart 字段名固定 attach_files；配额满时只警告，不阻塞发版。
    boundary = uuid.uuid4().hex
    payload = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="attach_files"; filename="{asset_name}"\r\n'
        "Content-Type: application/octet-stream\r\n\r\n"
    ).encode() + open(archive, "rb").read() + f"\r\n--{boundary}--\r\n".encode()
    status, body = http(
        "POST",
        f"{GITEE}/repos/{REPO}/releases/{release_id}/attach_files"
        f"?access_token={urllib.parse.quote(token)}",
        "",
        payload,
        {"Content-Type": f"multipart/form-data; boundary={boundary}"},
    )
    if status in (200, 201):
        return True
    if status == 403 and "配额" in body.decode("utf-8", "replace"):
        print("  gitee: 附件配额已满，release 只留正文与源码包（不阻塞）")
        return True
    return fail(f"gitee 上传失败 HTTP {status}: {body[:200]!r}")


def publish_github(version, tag, commit, archive, asset_name, notes, body_text):
    token = github_token()
    if not token:
        return fail("缺少 GitHub token（GITHUB_TOKEN 或 gh auth token）")
    status, raw = http("GET", f"{GITHUB}/repos/{REPO}/releases/tags/{tag}", token)
    if status == 200:
        release = json.loads(raw)
        print("  github: release 已存在")
    elif status == 404:
        status, raw = http("POST", f"{GITHUB}/repos/{REPO}/releases", token, {
            "tag_name": tag, "target_commitish": commit, "name": f"{tag}",
            "body": body_text, "draft": False, "prerelease": False,
        })
        if status not in (200, 201):
            return fail(f"github 建 release 失败 HTTP {status}: {raw[:200]!r}")
        release = json.loads(raw)
        print("  github: release 已创建")
    else:
        return fail(f"github 查 release 失败 HTTP {status}: {raw[:200]!r}")
    return publish_asset("github", token, release["id"], archive, asset_name,
                         release.get("upload_url"))


def publish_gitea(version, tag, commit, archive, asset_name, notes, body_text):
    token = os.environ.get("GITEA_TOKEN") or git_credential("gitea.iouf.cn")[1]
    if not token:
        return fail("缺少 Gitea token（GITEA_TOKEN 或 git credential gitea.iouf.cn）")
    status, raw = http("GET", f"{GITEA}/repos/{REPO}/releases?limit=50", token)
    if status != 200:
        return fail(f"gitea 查 release 失败 HTTP {status}: {raw[:200]!r}")
    release = next((r for r in json.loads(raw) if r.get("tag_name") == tag), None)
    if release:
        print("  gitea: release 已存在")
    else:
        status, raw = http("POST", f"{GITEA}/repos/{REPO}/releases", token, {
            "tag_name": tag, "target_commitish": commit, "name": tag,
            "body": body_text, "draft": False, "prerelease": False,
        })
        if status not in (200, 201):
            return fail(f"gitea 建 release 失败 HTTP {status}: {raw[:200]!r}")
        release = json.loads(raw)
        print("  gitea: release 已创建")
    return publish_asset("gitea", token, release["id"], archive, asset_name)


def publish_gitee(version, tag, commit, archive, asset_name, notes, body_text):
    token = os.environ.get("GITEE_TOKEN") or git_credential("gitee.com")[1]
    if not token:
        return fail("缺少 Gitee token（GITEE_TOKEN 或 git credential gitee.com）")
    query = f"?access_token={urllib.parse.quote(token)}&per_page=50"
    status, raw = http("GET", f"{GITEE}/repos/{REPO}/releases{query}")
    if status != 200:
        return fail(f"gitee 查 release 失败 HTTP {status}: {raw[:200]!r}")
    release = next((r for r in json.loads(raw) if r.get("tag_name") == tag), None)
    if release:
        print("  gitee: release 已存在")
    else:
        status, raw = http("POST", f"{GITEE}/repos/{REPO}/releases{query}", "", {
            "tag_name": tag, "target_commitish": commit, "name": tag,
            "body": body_text, "prerelease": False,
        })
        if status not in (200, 201):
            return fail(f"gitee 建 release 失败 HTTP {status}: {raw[:200]!r}")
        release = json.loads(raw)
        print("  gitee: release 已创建")
    return publish_asset("gitee", token, release["id"], archive, asset_name)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--archive", required=True)
    parser.add_argument("--manifest", default="version.json")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    manifest = json.load(open(args.manifest, encoding="utf-8"))
    asset = manifest["assets"]["linux-x64"]
    archive_size = os.path.getsize(args.archive)
    digest = hashlib.sha256(open(args.archive, "rb").read()).hexdigest()
    if archive_size != asset["size"] or digest != asset["sha256"]:
        print("release: 归档与 version.json 的 size/sha256 不一致，拒绝发布", file=sys.stderr)
        return 1

    asset_name = os.path.basename(args.archive)
    notes = manifest.get("notes", "").strip()
    body_text = (
        f"{notes}\n\n**Linux x64 归档**：`{asset_name}`"
        f"（{archive_size / 1024 / 1024:.1f} MB，sha256 `{digest}`）"
    )
    print(f"发布 {args.tag}：{asset_name}（{archive_size} B）")
    if args.dry_run:
        print(f"  github token: {'有' if github_token() else '缺'}")
        print(f"  gitea token : {'有' if (os.environ.get('GITEA_TOKEN') or git_credential('gitea.iouf.cn')[1]) else '缺'}")
        print(f"  gitee token : {'有' if (os.environ.get('GITEE_TOKEN') or git_credential('gitee.com')[1]) else '缺'}")
        print("  dry-run：不建 release、不上传")
        return 0

    results = []
    for platform, publisher in (
        ("github", publish_github),
        ("gitea", publish_gitea),
        ("gitee", publish_gitee),
    ):
        try:
            results.append(publisher(args.version, args.tag, args.commit,
                                     args.archive, asset_name, notes, body_text))
        except Exception as error:  # noqa: BLE001 - 单个平台失败不掩盖其余平台的结果
            results.append(fail(f"{platform} 发布异常：{error}"))

    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
