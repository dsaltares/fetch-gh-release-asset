# Fetch GH Release Asset

This action downloads an asset from a Github release. Private repos are supported.

## Inputs

### `repo`

The `org/repo`. Defaults to the current repo.

### `version`

The release version to fetch from. Default `"latest"`.

### `file`

**Required** The name of the file in the release.

### `token`
Optional Personal Access Token to access repository. You need to either specify this or set the GITHUB_TOKEN environment variable yourself.

## Outputs

### `version`

The version number of the release tag. Can be used to deploy for example to itch.io

## Example usage

```yaml
uses: dsaltares/fetch-gh-release-asset@master
with:
  repo: "dsaltares/godot-wild-jam-18"
  version: "latest"
  file: "plague-linux.zip"
  token: ${{ secrets.YOUR_TOKEN }}
```
