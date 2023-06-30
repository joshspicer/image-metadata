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

# If --all is passed to this script, then we'll show all the configuration
# Otherwise, we'll just show the configuration we care about
if [ "$1" == "--all" ]; then
    CONTAINER_INSPECT_SHOW_ALL=true
    READ_CONFIGURATION_FILTER='.'
else
    READ_CONFIGURATION_FILTER='.mergedConfiguration'
fi

if [ "$1" == "--no-cleanup" ]; then
    NO_CLEANUP=true
fi


function msg() {
    echo -e "${BOLD_RED}--- $1 ---${NC}"
}

function clean_up {
    msg "Cleanup"
    # Remove all containers with label EXAMPLE=true
    docker ps -a -q --filter label=EXAMPLE=true | xargs -r docker rm -f
}

# Get path of where this script exists
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

msg "Building 'base-image'"
$DEVCONTAINER_PROGRAM build --no-cache --image-name base-image --workspace-folder "$SCRIPT_PATH/base-image"

msg "Image labels for 'base-image'"
docker inspect base-image | jq .[].Config.Labels | jq ".[\"devcontainer.metadata\"]" -r | jq

msg "Build 'example-project'"
$DEVCONTAINER_PROGRAM build --no-cache --image-name example-project --workspace-folder "$SCRIPT_PATH/example-project"

msg "Image labels for 'example-project'"
docker inspect example-project | jq .[].Config.Labels | jq ".[\"devcontainer.metadata\"]" -r | jq

msg "Run 'example-project'"

result=$($DEVCONTAINER_PROGRAM up --workspace-folder "$SCRIPT_PATH/example-project" --cache-from example-project --id-label EXAMPLE=true)
containerId=$(echo $result | jq .containerId -r)

msg 'Export env from "example-project"'
$DEVCONTAINER_PROGRAM exec --id-label EXAMPLE=true env

msg "Container metadata for 'example-project')"

if [ -z "$CONTAINER_INSPECT_SHOW_ALL" ]; then
    docker inspect $containerId | jq .[].Config.Labels | jq ".[\"devcontainer.metadata\"]" -r | jq
else
    docker inspect $containerId | jq
fi

msg "devcontainer read-configuration ($READ_CONFIGURATION_FILTER)"
$DEVCONTAINER_PROGRAM read-configuration --include-merged-configuration --workspace-folder "$SCRIPT_PATH/example-project" | jq $READ_CONFIGURATION_FILTER

if [ -z "$NO_CLEANUP" ]; then
    clean_up
fi
