FROM alpine:latest

RUN	apk add --no-cache \
  curl \
  jq

COPY fetch_github_asset.sh /fetch_github_asset.sh

ENTRYPOINT ["/fetch_github_asset.sh"]
