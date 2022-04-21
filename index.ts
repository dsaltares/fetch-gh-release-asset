import * as core from '@actions/core'
import * as github from '@actions/github'

import { mkdir, writeFile } from 'fs/promises'

import type { Context } from '@actions/github/lib/context'
import type { HeadersInit } from 'node-fetch'
import { dirname } from 'path'
import fetch from 'node-fetch'

interface GetRepoResult {
  readonly owner: string
  readonly repo: string
}

const getRepo = (inputRepoString: string, context: Context): GetRepoResult => {
  if (inputRepoString === '') {
    return { owner: context.repo.owner, repo: context.repo.repo }
  } else {
    const [owner, repo] = inputRepoString.split('/')
    if (typeof owner === 'undefined' || typeof repo === 'undefined') throw new Error('Malformed repo')
    return { owner, repo }
  }
}

interface GetReleaseOptions {
  readonly owner: string
  readonly repo: string
  readonly version: string
}

const getRelease = (octokit: ReturnType<typeof github.getOctokit>, { owner, repo, version }: GetReleaseOptions) => {
  const tagsMatch = version.match(/^tags\/(.*)$/)
  if (version === 'latest') {
    return octokit.rest.repos.getLatestRelease({ owner, repo })
  } else if (tagsMatch !== null && tagsMatch[1]) {
    return octokit.rest.repos.getReleaseByTag({ owner, repo, tag: tagsMatch[1] })
  } else {
    return octokit.rest.repos.getRelease({ owner, repo, release_id: Math.trunc(Number(version)) })
  }
}

type GetReleaseResult = ReturnType<typeof getRelease> extends Promise<infer T> ? T : never

interface FetchAssetFileOptions {
  readonly id: number
  readonly outputPath: string
  readonly owner: string
  readonly repo: string
  readonly token: string
}

const MAX_RETRY = 5
const RETRY_INTERVAL = 1000

const fetchAssetFile = async (octokit: ReturnType<typeof github.getOctokit>, { id, outputPath, owner, repo, token }: FetchAssetFileOptions): Promise<void> => {
  const {
    body,
    headers: {
      accept,
      'user-agent': userAgent
    },
    method,
    url
  } = octokit.request.endpoint('GET /repos/:owner/:repo/releases/assets/:asset_id', {
    asset_id: id,
    headers: {
      accept: 'application/octet-stream'
    },
    owner,
    repo
  })
  let headers: HeadersInit = {
    accept,
    authorization: `token ${token}`
  }
  if (typeof userAgent !== 'undefined') headers = { ...headers, 'user-agent': userAgent }

  let i = 0
  while (true) {
    const response = await fetch(url, { body, headers, method })
    if (!response.ok) {
      if (i < MAX_RETRY) {
        i++
        await new Promise(resolve => setTimeout(resolve, RETRY_INTERVAL))
        continue
      } else {
        const text = await response.text()
        core.warning(text)
        throw new Error('Invalid response')
      }
    }
    const blob = await response.blob()
    const arrayBuffer = await blob.arrayBuffer()
    await mkdir(dirname(outputPath), { recursive: true })
    await writeFile(outputPath, new Uint8Array(arrayBuffer))
    return
  }
}

const printOutput = (release: GetReleaseResult): void => {
  core.setOutput('version', release.data.tag_name)
  core.setOutput('name', release.data.name)
  core.setOutput('body', release.data.body)
}

const main = async (): Promise<void> => {
  const { owner, repo } = getRepo(core.getInput('repo', { required: false }), github.context)
  const token = core.getInput('token', { required: false })
  const version = core.getInput('version', { required: false })
  const inputTarget = core.getInput('target', { required: false })
  const file = core.getInput('file', { required: true })
  const target = inputTarget === '' ? file : inputTarget

  const octokit = github.getOctokit(token)
  const release = await getRelease(octokit, { owner, repo, version })

  const asset = release.data.assets.find(e => e.name === file)
  if (typeof asset === 'undefined') throw new Error('Could not find asset id')
  await fetchAssetFile(octokit, { id: asset.id, outputPath: target, owner, repo, token })
  printOutput(release)
}

const mainRegex = async (): Promise<void> => {
  const { owner, repo } = getRepo(core.getInput('repo', { required: false }), github.context)
  const token = core.getInput('token', { required: false })
  const version = core.getInput('version', { required: false })
  const file = core.getInput('file', { required: true })
  const target = core.getInput('target', { required: true })

  const octokit = github.getOctokit(token)
  const release = await getRelease(octokit, { owner, repo, version })

  const regexp = new RegExp(file)
  const assets = release.data.assets.filter(e => regexp.test(e.name))
  if (assets.length === 0) throw new Error('Could not find asset id')
  for (const asset of assets) {
    await fetchAssetFile(octokit, { id: asset.id, outputPath: `${target}${asset.name}`, owner, repo, token })
  }
  printOutput(release)
}

if (core.getBooleanInput('regex', { required: false })) {
  mainRegex()
} else {
  main()
}
