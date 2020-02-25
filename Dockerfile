FROM alpine:latest

RUN	apk add --no-cache \
  bash \
  ca-certificates \
  curl \
  wget \
  jq

COPY fetch_github_asset.sh /fetch_github_asset.sh

ENTRYPOINT ["/fetch_github_asset.sh"]
