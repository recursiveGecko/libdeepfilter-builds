#!/usr/bin/env bash
set -euo pipefail

NAME=deepfilternet
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "$RUST_VERSION" ]; then
  echo "\$RUST_VERSION must be set (e.g. '1.76.0')"
  exit 1
fi

if [ -z "$TARGET" ]; then
  echo "\$TARGET must be set to target triple (e.g. 'x86_64-unknown-linux-gnu')"
  exit 1
fi

if [ -z "$BUILD_ROOT_PATH" ]; then
  echo "\$BUILD_ROOT_PATH must be set to project build root"
  exit 1
fi

if [ -z "$ARTIFACT_PATH" ]; then
  echo "\$ARTIFACT_PATH must be set to directory where artifacts will be placed"
  exit 1
fi

rm -r "${ARTIFACT_PATH}" 2>/dev/null || true
mkdir -p "${ARTIFACT_PATH}"

set -x
cd "${BUILD_ROOT_PATH}"
# Copy cbindgen.toml to libDF, `cinstall` doesn't seem to be using the one in root directory for some reason.
# The "state" of the project directory also seems to get cached between builds, so if this step isn't performed correctly
# `cargo cinstall` will keep generating C++ headers rather than C headers even after the file is later copied in correct
# location. To resolve this, run `cargo clean`. If the file is now in correct location, `cargo cinstall` should work as expected.
cp cbindgen.toml libDF
# Build DeepFilterNet
cargo "+${RUST_VERSION}" cinstall --locked --package deep_filter --profile release-lto --target "${TARGET}" --prefix "${ARTIFACT_PATH}" --features capi

# Copy the models
cp -r models "${ARTIFACT_PATH}/models"

set +x
echo "libdeepfilter built successfully."
