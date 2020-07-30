#!/bin/bash

if [[ -z "$INPUT_FILE" ]]; then
  echo "Missing file input in the action"
  exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "Missing GITHUB_REPOSITORY env variable"
  exit 1
fi

REPO=$GITHUB_REPOSITORY
if ! [[ -z ${INPUT_REPO} ]]; then
  REPO=$INPUT_REPO ;
fi

# Optional personal access token for external repository
TOKEN=$GITHUB_TOKEN
if ! [[ -z ${INPUT_TOKEN} ]]; then
  TOKEN=$INPUT_TOKEN
fi

API_URL="https://$TOKEN:@api.github.com/repos/$REPO"
RELEASE_DATA=$(curl $API_URL/releases/${INPUT_VERSION})
ASSET_ID=$(echo $RELEASE_DATA | jq -r ".assets | map(select(.name == \"${INPUT_FILE}\"))[0].id")
TAG_VERSION=$(echo $RELEASE_DATA | jq -r ".tag_name" | sed -e "s/^v//" | sed -e "s/^v.//")

if [[ -z "$ASSET_ID" ]]; then
  echo "Could not find asset id"
  exit 1
fi

curl \
  -J \
  -L \
  -H "Accept: application/octet-stream" \
  "$API_URL/releases/assets/$ASSET_ID" \
  -o ${INPUT_FILE}

echo "::set-output name=version::$TAG_VERSION"