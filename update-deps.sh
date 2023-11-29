#!/bin/bash

set -euo pipefail
# set -x

SCRATCHDIR="$(mktemp -d)"
trap 'rm -rf -- "${SCRATCHDIR}" &> /dev/null' EXIT

ENVOY_ORG=envoyproxy
ENVOY_REPO=envoy

WORKSPACE="$(cd "$(dirname "$0")" & pwd)"
VENDOR_DIR="${WORKSPACE}/vendor"
VENDOR_BAZELRC="${WORKSPACE}/vendor.bazelrc"
OUTPUT_BASE="${SCRATCHDIR}/output"

# Find out what branch we're on
BRANCH_NAME="$(cd "${WORKSPACE}" && git symbolic-ref --quiet --short HEAD)"

# Download matching envoy branch
cd "${SCRATCHDIR}"
git clone --depth=1 -b "${BRANCH_NAME}" "https://github.com/${ENVOY_ORG}/${ENVOY_REPO}.git"

# Get the commit id
cd "${ENVOY_REPO}"
ENVOY_COMMIT=$(git rev-parse HEAD)

# Get the SHA256
curl -sfLO "https://github.com/${ENVOY_ORG}/${ENVOY_REPO}/archive/${ENVOY_COMMIT}.tar.gz"
ENVOY_SHA256=$(sha256sum "${ENVOY_COMMIT}.tar.gz" | awk '{print $1}')

# Update the envoy org, repo, commit & sha256 valuse in the WORKSPACE file
sed -i "s|^ENVOY_ORG = .*|ENVOY_ORG = \"${ENVOY_ORG}\"|" "${WORKSPACE}/WORKSPACE"
sed -i "s|^ENVOY_REPO = .*|ENVOY_REPO = \"${ENVOY_REPO}\"|" "${WORKSPACE}/WORKSPACE"
sed -i "s|^ENVOY_COMMIT = .*|ENVOY_COMMIT = \"${ENVOY_COMMIT}\"|" "${WORKSPACE}/WORKSPACE"
sed -i "s|^ENVOY_SHA256 = .*|ENVOY_SHA256 = \"${ENVOY_SHA256}\"|" "${WORKSPACE}/WORKSPACE"

# Work out what bazel cache options to use
BAZEL_CACHE_FLAGS=""
if [[ -n ${BAZEL_REMOTE_CACHE} ]]; then
  BAZEL_CACHE_FLAGS="--remote_cache=${BAZEL_REMOTE_CACHE}"
  if [[ -n ${BAZEL_EXPERIMENTAL_REMOTE_DOWNLOADER} ]]; then
    BAZEL_CACHE_FLAGS+=" --experimental_remote_downloader=${BAZEL_EXPERIMENTAL_REMOTE_DOWNLOADER}"
  fi
elif [[ -n ${BAZEL_DISK_CACHE} ]]; then
  BAZEL_CACHE_FLAGS+="--disk_cache=${BAZEL_DISK_CACHE}"
fi

# Empty the vendor bazelrc file so bazel will always fetch envoy
: > "${VENDOR_BAZELRC}"

# Use build --nobuild, rather than fetch, because it honours configuration options
bazel --output_base="${OUTPUT_BASE}" build --nobuild ${BAZEL_CACHE_FLAGS} @envoy//:envoy

# Copy the fetched & patched envoy directory to the ${VENDOR_DIR}
rm -r "${VENDOR_DIR}/envoy"
cp -rL "${OUTPUT_BASE}/external/envoy" "${VENDOR_DIR}/envoy"

# Reintate the envoy repository mapping
echo "build --override_repository=envoy=%workspace%/vendor/envoy" > "${VENDOR_BAZELRC}"

# Remove stuff we don't want to vendor
find "${VENDOR_DIR}" -type d -name .git -print0 | xargs -0 -r rm -rf


echo
echo "========================================"
echo "Done. Inspect the result with git status"
echo "========================================"
echo
