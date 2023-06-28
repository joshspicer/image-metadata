#!/bin/bash

BOLD_RED='\033[1;31m'
NC='\033[0m' # No Color

function msg() {
    echo -e "${BOLD_RED}--- $1 ---${NC}"
}

msg "Building 'base-image'"
devcontainer build --no-cache --image-name base-image --workspace-folder ./base-image

msg "Image labels for 'base-image'"
docker inspect base-image | jq .[].Config.Labels | jq ".[\"devcontainer.metadata\"]" -r | jq

msg "Build 'example-project'"
devcontainer build --no-cache --image-name example-project --workspace-folder ./example-project

msg "Image labels for 'example-project'"
docker inspect example-project | jq .[].Config.Labels | jq ".[\"devcontainer.metadata\"]" -r | jq

msg "Run 'example-project'"

result=$(devcontainer up --workspace-folder ./example-project --cache-from example-project)
containerId=$(echo $result | jq .containerId -r)

msg "Container metadata for 'example-project'"
docker inspect $containerId | jq .[].Config.Labels | jq ".[\"devcontainer.metadata\"]" -r | jq

msg "devcontainer read-configuration (merged configuration))"
devcontainer read-configuration --include-merged-configuration --workspace-folder ./example-project | jq .mergedConfiguration 