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
    # TODO: Cross compilation
    # "x86_64-pc-windows-gnu",
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

our_repo = gh.get_repo(OUR_PROJECT)
upstream_repo = gh.get_repo(UPSTREAM_PROJECT)
latest_upstream_release = upstream_repo.get_latest_release()

matrix = []

if latest_upstream_release.draft or latest_upstream_release.prerelease:
    print_err("Latest upstream release is a draft or a pre-release, skipping...")
else:
    upstream_tag = latest_upstream_release.tag_name
    upstream_tarball = latest_upstream_release.tarball_url

    our_release_build_tag = f"release-{upstream_tag}"

    build_upstream_release = True

    for release in our_repo.get_releases():
        if release.tag_name == our_release_build_tag and not release.draft:
            print_err("Upstream release already built & published.")
            build_upstream_release = False
            break

    if build_upstream_release:
        print_err(f"Adding upstream release to matrix: {upstream_tarball}")
        matrix.extend(
            [
                {
                    "target": target,
                    "tarball": upstream_tarball,
                    "ref": upstream_tag,
                    "short_ref": upstream_tag,
                    "our_tag": our_release_build_tag,
                }
                for target in TARGETS
            ]
        )


latest_upstream_commit = upstream_repo.get_git_ref("heads/main").object
our_main_branch_build_tag = f"prerelease-{latest_upstream_commit.sha}"
build_upstream_commit = True

for release in our_repo.get_releases():
    if release.tag_name == our_main_branch_build_tag and not release.draft:
        print_err("Upstream main branch already built & published.")
        build_upstream_commit = False
        break


if build_upstream_commit:
    upstream_tarball = f"https://github.com/{UPSTREAM_PROJECT}/archive/{latest_upstream_commit.sha}.tar.gz"
    print_err(f"Adding upstream main branch to matrix: {upstream_tarball}")

    matrix.extend(
        [
            {
                "target": target,
                "tarball": upstream_tarball,
                "ref": latest_upstream_commit.sha,
                "short_ref": latest_upstream_commit.sha[0:8],
                "our_tag": our_main_branch_build_tag,
            }
            for target in TARGETS
        ]
    )

output = {
    "matrix": {
        "include": matrix,
    },
    "skip_build": len(matrix) == 0,
}

print(json.dumps(output))
