# Fetch GH Release Asset

This action downloads an asset from a Github release. Private repos are supported.

## Inputs

### `repo`

The `org/repo`. Defaults to the current repo.

### `version`

The release version to fetch from. Default `"latest"`. If not `"latest"`, this has to be in the form `tags/<tag_name>` or `<release_id>`.

### `file`

**Required** The name of the file in the release.

### `target`

Optional target file path. Only supports paths to subdirectories of the Github Actions workspace directory

### `token`

Optional Personal Access Token to access repository. You need to either specify this or use the ``secrets.GITHUB_TOKEN`` environment variable.

## Outputs

### `version`

The version number of the release tag. Can be used to deploy for example to itch.io

### `name`

[Also called a title of a release](https://docs.github.com/en/github/administering-a-repository/managing-releases-in-a-repository). Defaults to the same value as `version` if not specified when creating a release. 

### `body`

The body (description) of a release.

## Example usage

```yaml
uses: dsaltares/fetch-gh-release-asset@master
with:
  repo: "dsaltares/godot-wild-jam-18"
  version: "latest"
  file: "plague-linux.zip"
  target: "subdir/plague-linux.zip"
  token: ${{ secrets.YOUR_TOKEN }}
```

## Support

This action only supports Linux runners as this is a [docker container](https://docs.github.com/en/actions/creating-actions/about-actions#types-of-actions) action. If you encounter `Error: Container action is only supported on Linux` then you are using non-linux runner.
