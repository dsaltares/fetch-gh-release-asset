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
if [[ -n ${INPUT_REPO} ]]; then
  REPO=$INPUT_REPO
fi

# Optional target file path
TARGET=$INPUT_FILE
if [[ -n ${INPUT_TARGET} ]]; then
  TARGET=$INPUT_TARGET
fi

# Optional personal access token for external repository
TOKEN=$GITHUB_TOKEN
if [[ -n ${INPUT_TOKEN} ]]; then
  TOKEN=$INPUT_TOKEN
fi

if [[ -n ${INPUT_HASH} ]]; then
  HASH=$INPUT_HASH
fi

if [[ -n ${INPUT_RETRIES//[0-9]/} ]]; then
  RETRIES=$INPUT_RETRIES
else
  RETRIES=0
fi

API_URL="https://api.github.com/repos/$REPO"
RELEASE_DATA=$(curl ${TOKEN:+"-H"} ${TOKEN:+"Authorization: token ${TOKEN}"} \
                    "$API_URL/releases/${INPUT_VERSION}")
MESSAGE=$(echo "$RELEASE_DATA" | jq -r ".message")

if [[ "$MESSAGE" == "Not Found" ]]; then
  echo "[!] Release asset not found"
  echo "Release data: $RELEASE_DATA"
  echo "-----"
  echo "repo: $REPO"
  echo "asset: $INPUT_FILE"
  echo "target: $TARGET"
  echo "version: $INPUT_VERSION"
  exit 1
fi

echo "MESSAGE: '$RELEASE_DATA'"

ASSET_ID=$(echo "$RELEASE_DATA" | jq -r ".assets | .[] | select(.name == \"${INPUT_FILE}\") | .id")
TAG_VERSION=$(echo "$RELEASE_DATA" | jq -r ".tag_name" | sed -e "s/^v//" | sed -e "s/^v.//")
RELEASE_NAME=$(echo "$RELEASE_DATA" | jq -r ".name")
RELEASE_BODY=$(echo "$RELEASE_DATA" | jq -r ".body")

if [[ -z "$ASSET_ID" ]]; then
  echo "Could not find asset id"
  exit 1
fi

if [[ -z $HASH ]]; then
  curl \
    -J \
    -L \
    --retry $RETRIES \
    --retry-delay 5 \
    -H "Accept: application/octet-stream" \
    ${TOKEN:+"-H"} ${TOKEN:+"Authorization: token ${TOKEN}"} \
    "$API_URL/releases/assets/$ASSET_ID" \
    --create-dirs \
    -o "${TARGET}"
else
  SUCCESS=0
  n=0
  until [ "$n" -ge $((RETRIES+1) ]
  do
    curl \
      -J \
      -L \
      -H "Accept: application/octet-stream" \
      ${TOKEN:+"-H"} ${TOKEN:+"Authorization: token ${TOKEN}"} \
      "$API_URL/releases/assets/$ASSET_ID" \
      --create-dirs \
      -o "${TARGET}" \
      && echo $HASH' *'$TARGET | sha256sum -c
    if [[ $? -eq 1 ]]; then
        SUCCESS=1
    else
        SUCCESS=0
        break
    fi 
    n=$((n+1)) 
    sleep 15
  done
  if [[ SUCCESS -eq 1 ]]; then
      echo "Could not download file with matching hash"
      exit 1
  fi
fi

echo "::set-output name=version::$TAG_VERSION"
echo "::set-output name=name::$RELEASE_NAME"
echo "::set-output name=body::$RELEASE_BODY"
