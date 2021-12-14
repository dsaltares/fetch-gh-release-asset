FROM alpine:latest

RUN	apk update && apk add --no-cache \
  bash \
  ca-certificates \
  curl \
  wget \
  outils-sha256 \
  jq

COPY fetch_github_asset.sh /fetch_github_asset.sh

ENTRYPOINT ["/fetch_github_asset.sh"]
