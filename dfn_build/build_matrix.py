import os
import json
import sys
from github import Github
from github import Auth

OUR_PROJECT = "recursiveGecko/libdeepfilter-builds"
UPSTREAM_PROJECT = "Rikorose/DeepFilterNet"

# https://doc.rust-lang.org/stable/rustc/platform-support.html
TARGETS = [
    "x86_64-unknown-linux-gnu",
    "x86_64-pc-windows-gnu",
    # "x86_64-unknown-linux-musl",
    # "x86_64-unknown-freebsd",
    # "x86_64-apple-darwin",
    # "aarch64-unknown-linux-musl",
    # "aarch64-unknown-linux-gnu",
    # "aarch64-apple-darwin",
]


def print_err(msg):
    print(msg, file=sys.stderr)


try:
    GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
    auth = Auth.Token(GITHUB_TOKEN)
except KeyError:
    print_err("GITHUB_TOKEN environment variable must be set.")
    exit(1)

gh = Github(auth=auth)

upstream_repo = gh.get_repo(UPSTREAM_PROJECT)
latest_upstream_release = upstream_repo.get_latest_release()

if latest_upstream_release.draft or latest_upstream_release.prerelease:
    exit(0)

upstream_tag = latest_upstream_release.tag_name
upstream_tarball = latest_upstream_release.tarball_url

our_repo = gh.get_repo(OUR_PROJECT)
our_tag_name = f"release-{upstream_tag}"

for release in our_repo.get_releases():
    if release.tag_name == our_tag_name and not release.draft:
        print_err("Upstream release already built & published.")
        exit(0)

matrix_include = []
for target in TARGETS:
    matrix_include.append(
        {
            "target": target,
            "tag": upstream_tag,
        }
    )


output = {
    "matrix": {
        "include": [{"target": target} for target in TARGETS],
    },
    "tag": upstream_tag,
    "tarball": upstream_tarball,
}

print(json.dumps(output))
