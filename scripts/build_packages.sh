#!/usr/bin/env bash

set -eu -o pipefail
# -e: exits if a command fails
# -u: errors if an variable is referenced before being set
# -o pipefail: causes a pipeline to produce a failure return code if any command errors

readonly PACKAGES=${@:?"No package names specified"}

readonly RULES_NODEJS_DIR=$(cd $(dirname "$0")/..; pwd)
readonly PACKAGES_DIR="${RULES_NODEJS_DIR}/packages"
readonly DIST_DIR="${RULES_NODEJS_DIR}/dist"

echo_and_run() { echo "+ $@" ; "$@" ; }

for package in ${PACKAGES[@]} ; do
  (
    readonly DEST_DIR="${DIST_DIR}/npm_bazel_${package}"

    # Build npm package
    cd "${PACKAGES_DIR}/${package}"
    printf "\n\nBuilding package ${package} //:npm_package\n"
    ${RULES_NODEJS_DIR}/scripts/link_deps.sh
    echo_and_run bazel build --workspace_status_command=../../scripts/current_version.sh //:npm_package

    # Copy the npm_package to /dist
    echo "Copying npm package to ${DEST_DIR}"
    rm -rf ${DEST_DIR}
    mkdir -p ${DIST_DIR}
    readonly BAZEL_BIN=$(bazel info bazel-bin)
    echo_and_run cp -R "${BAZEL_BIN}/npm_package" ${DEST_DIR}
    chmod -R u+w ${DEST_DIR}
  )
done
