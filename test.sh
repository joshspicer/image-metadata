#!/bin/bash

set -e

BOLD_RED='\033[1;31m'
NC='\033[0m' # No Color

# Detect if 'devcontainer' is on the path
DEVCONTAINER_PROGRAM='devcontainer'
if ! command -v $DEVCONTAINER_PROGRAM &> /dev/null
then
    # Assume local dev
    # Clone into /workspaces in a Codespace
    DEVCONTAINER_PROGRAM='./devcontainer.js'
fi

# Get path of where this script exists
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

function msg() {
    echo -e "${BOLD_RED}--- $1 ---${NC}"
}

msg "Building 'base-image'"
$DEVCONTAINER_PROGRAM build --no-cache --image-name base-image --workspace-folder "$SCRIPT_PATH/base-image"

msg "Image labels for 'base-image'"
docker inspect base-image | jq .[].Config.Labels | jq ".[\"devcontainer.metadata\"]" -r | jq

msg "Build 'example-project'"
$DEVCONTAINER_PROGRAM build --no-cache --image-name example-project --workspace-folder "$SCRIPT_PATH/example-project"

msg "Image labels for 'example-project'"
docker inspect example-project | jq .[].Config.Labels | jq ".[\"devcontainer.metadata\"]" -r | jq

msg "Run 'example-project'"

result=$($DEVCONTAINER_PROGRAM up --workspace-folder "$SCRIPT_PATH/example-project" --cache-from example-project)
containerId=$(echo $result | jq .containerId -r)

msg "Container metadata for 'example-project'"
docker inspect $containerId | jq .[].Config.Labels | jq ".[\"devcontainer.metadata\"]" -r | jq

msg "devcontainer read-configuration (merged)"
$DEVCONTAINER_PROGRAM read-configuration --include-merged-configuration --workspace-folder "$SCRIPT_PATH/example-project" | jq .mergedConfiguration