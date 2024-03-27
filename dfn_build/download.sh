#!/usr/bin/env bash
set -eo pipefail

if [ -z "$BUILD_ROOT_PATH" ]; then
  echo "\$BUILD_ROOT_PATH must be set to project build root"
  exit 1
fi

if [ -z "$UPSTREAM_TARBALL" ]; then
  echo "\$UPSTREAM_TARBALL must be set to the URL of upstream tarball"
  exit 1
fi

if [ -z "$TARBALL_SAVE_PATH" ]; then
  echo "\$TARBALL_SAVE_PATH must be set to the path where upstream tarball will be saved"
  exit 1
fi

BUILD_ROOT_PATH=$(realpath "${BUILD_ROOT_PATH}")
TARBALL_SAVE_PATH=$(realpath "${TARBALL_SAVE_PATH}")

set -ux

rm -r "${BUILD_ROOT_PATH}" || true
mkdir "${BUILD_ROOT_PATH}"
curl --fail --location "${UPSTREAM_TARBALL}" -o "${TARBALL_SAVE_PATH}"
tar xvf "${TARBALL_SAVE_PATH}" --strip-components 1 --directory "${BUILD_ROOT_PATH}"