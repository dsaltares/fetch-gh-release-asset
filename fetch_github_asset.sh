#!/bin/bash

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Missing GITHUB_TOKEN env variable"
  exit 1
fi

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

echo $GITHUB_REPOSITORY
echo $INPUT_REPO
echo $REPO

API_URL="https://$GITHUB_TOKEN:@api.github.com/repos/$GITHUB_REPOSITORY"

echo $API_URL
echo $INPUT_VERSION

ASSET_ID=$(curl $API_URL/releases/${INPUT_VERSION} | jq -r ".assets | map(select(.name == \"${INPUT_FILE}\"))[0].id")

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
