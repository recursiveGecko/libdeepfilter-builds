#!/usr/bin/env bash
set -eo pipefail

NAME=deepfilternet
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOWNLOAD_URL=$1


if [ -z "$DOWNLOAD_URL" ]; then
  echo ".tar.gz download URL must be provided as first and only argument"
  exit 1
fi

if [ -z "$RUST_VERSION" ]; then
  echo "\$RUST_VERSION must be set (e.g. '1.76.0')"
  exit 1
fi

if [ -z "$TARGET" ]; then
  echo "\$TARGET must be set to target triple (e.g. 'x86_64-unknown-linux-gnu')"
  exit 1
fi

set -u

BUILD_ROOT_DIR="${SCRIPT_DIR}/build/root"
BUILD_OUT_DIR="${SCRIPT_DIR}/build/out"
MODELS_DIR="${BUILD_OUT_DIR}/models"
FILE_NAME="DeepFilterNet.tar.gz"

rm -r "${BUILD_ROOT_DIR}" 2>/dev/null || true
rm -r "${BUILD_OUT_DIR}" 2>/dev/null || true
mkdir -p "${BUILD_ROOT_DIR}"
mkdir -p "${BUILD_OUT_DIR}"

echo "Downloading ${DOWNLOAD_URL}"

set -x
cd "${BUILD_ROOT_DIR}"
# Download and extract DFN
curl --fail --location "${DOWNLOAD_URL}" -o "${FILE_NAME}"
tar xvf "${FILE_NAME}" --strip-components 1

# Copy cbindgen.toml to libDF, `cinstall` doesn't seem to be using the one in root directory for some reason.
# The "state" of the project directory also seems to get cached between builds, so if this step isn't performed correctly
# `cargo cinstall` will keep generating C++ headers rather than C headers even after the file is later copied in correct
# location. To resolve this, run `cargo clean`. If the file is now in correct location, `cargo cinstall` should work as expected.
cp cbindgen.toml libDF
# Build DeepFilterNet
cargo "+${RUST_VERSION}" cinstall --locked --package deep_filter --profile release-lto --target "${TARGET}" --prefix "${BUILD_OUT_DIR}"

# Copy the models
cp -r models "${MODELS_DIR}"
# # Delete build root
rm -r "${BUILD_ROOT_DIR}"
set +x

echo "libdeepfilter built successfully."
