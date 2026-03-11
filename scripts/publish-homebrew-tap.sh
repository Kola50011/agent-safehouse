#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

DEFAULT_MAIN_REPO_SLUG="eugene1g/agent-safehouse"
DEFAULT_TAP_REPO_SLUG="eugene1g/homebrew-safehouse"
DEFAULT_TAP_DIR="$(cd "${ROOT_DIR}/.." && pwd -P)/homebrew-safehouse"

main_repo_slug="$DEFAULT_MAIN_REPO_SLUG"
tap_repo_slug="$DEFAULT_TAP_REPO_SLUG"
tap_dir="$DEFAULT_TAP_DIR"
push_changes=0

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") <version-or-tag> [options]

Examples:
  ./scripts/publish-homebrew-tap.sh v0.1.0
  ./scripts/publish-homebrew-tap.sh 0.1.0 --push
  ./scripts/publish-homebrew-tap.sh v0.1.0 --tap-dir ../homebrew-safehouse --push

Description:
  Download the official GitHub release asset dist/safehouse.sh for a release
  tag, compute its sha256, update Formula/agent-safehouse.rb in the Homebrew
  tap, and create a commit there. Pass --push to push the tap commit to origin.

Options:
  --tap-dir DIR
      Local checkout of the Homebrew tap
      Default: ${DEFAULT_TAP_DIR}

  --tap-repo OWNER/REPO
      GitHub repository for the Homebrew tap
      Default: ${DEFAULT_TAP_REPO_SLUG}

  --main-repo OWNER/REPO
      GitHub repository for the main source repo
      Default: ${DEFAULT_MAIN_REPO_SLUG}

  --push
      Push the resulting tap commit to origin after committing

  -h, --help
      Show this help

Notes:
  - The GitHub release must already exist and be published for the tag.
  - The release must contain the safehouse.sh asset.
  - The tap checkout must be clean before running this script.
USAGE
}

require_command() {
  local name="$1"
  command -v "$name" >/dev/null 2>&1 || {
    echo "Missing required command: ${name}" >&2
    exit 1
  }
}

to_abs_path() {
  local input="$1"

  if [[ "$input" == /* ]]; then
    printf '%s\n' "$input"
    return
  fi

  printf '%s/%s\n' "$ROOT_DIR" "$input"
}

normalize_tag() {
  local raw="$1"
  local normalized_version=""
  local normalized_tag=""
  local semver_regex='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'

  if [[ "$raw" == v* ]]; then
    normalized_tag="$raw"
    normalized_version="${raw#v}"
  else
    normalized_version="$raw"
    normalized_tag="v${raw}"
  fi

  if [[ ! "$normalized_version" =~ $semver_regex ]]; then
    echo "Expected a SemVer version or tag like 1.2.3 or v1.2.3. Got: ${raw}" >&2
    exit 64
  fi

  printf '%s\n%s\n' "$normalized_tag" "$normalized_version"
}

ensure_clean_git_worktree() {
  local repo_dir="$1"

  if [[ -n "$(git -C "$repo_dir" status --porcelain)" ]]; then
    echo "Tap checkout is not clean: ${repo_dir}" >&2
    git -C "$repo_dir" status --short >&2 || true
    exit 1
  fi
}

ensure_tap_checkout() {
  if [[ -d "${tap_dir}/.git" ]]; then
    return 0
  fi

  if [[ -e "$tap_dir" ]]; then
    echo "Tap directory exists but is not a git checkout: ${tap_dir}" >&2
    exit 1
  fi

  require_command gh
  gh repo clone "$tap_repo_slug" "$tap_dir"
}

verify_tap_remote() {
  local origin_url

  origin_url="$(git -C "$tap_dir" remote get-url origin 2>/dev/null || true)"
  if [[ -z "$origin_url" ]]; then
    echo "Tap checkout has no origin remote: ${tap_dir}" >&2
    exit 1
  fi

  case "$origin_url" in
    *"${tap_repo_slug}"*|*"${tap_repo_slug}.git")
      ;;
    *)
      echo "Tap checkout origin does not match ${tap_repo_slug}: ${origin_url}" >&2
      exit 1
      ;;
  esac
}

ensure_release_asset() {
  local tag="$1"
  local json=""
  local asset_count=""
  local asset_name=""
  local total_assets=""
  local is_draft=""
  local release_url=""

  require_command gh

  if ! json="$(gh release view "$tag" --repo "$main_repo_slug" --json isDraft,url,assets 2>/dev/null)"; then
    echo "GitHub release ${tag} does not exist in ${main_repo_slug}" >&2
    exit 1
  fi

  is_draft="$(printf '%s\n' "$json" | jq -r '.isDraft')"
  if [[ "$is_draft" != "false" ]]; then
    echo "GitHub release ${tag} is still a draft in ${main_repo_slug}" >&2
    exit 1
  fi

  total_assets="$(printf '%s\n' "$json" | jq '.assets | length')"
  if [[ "$total_assets" != "1" ]]; then
    echo "Expected release ${tag} to have exactly one custom asset; found ${total_assets}" >&2
    exit 1
  fi

  asset_count="$(printf '%s\n' "$json" | jq '[.assets[] | select(.name == "safehouse.sh")] | length')"
  if [[ "$asset_count" != "1" ]]; then
    echo "Expected exactly one safehouse.sh asset on release ${tag}; found ${asset_count}" >&2
    exit 1
  fi

  asset_name="$(printf '%s\n' "$json" | jq -r '.assets[] | select(.name == "safehouse.sh") | .name')"
  if [[ "$asset_name" != "safehouse.sh" ]]; then
    echo "Release ${tag} is missing the safehouse.sh asset" >&2
    exit 1
  fi

  release_url="$(printf '%s\n' "$json" | jq -r '.url')"
  if [[ -z "$release_url" || "$release_url" == "null" ]]; then
    echo "Could not resolve GitHub release URL for ${tag}" >&2
    exit 1
  fi
}

write_formula() {
  local formula_path="$1"
  local version="$2"
  local sha256="$3"
  local asset_url="$4"

  cat >"$formula_path" <<EOF
class AgentSafehouse < Formula
  desc "macOS sandbox wrapper for coding agents"
  homepage "https://github.com/${main_repo_slug}"
  url "${asset_url}"
  version "${version}"
  sha256 "${sha256}"
  license "Apache-2.0"
  head "https://github.com/${main_repo_slug}.git", branch: "main"

  def install
    odie "Agent Safehouse requires macOS" unless OS.mac?
    artifact_path = build.head? ? "dist/safehouse.sh" : "safehouse.sh"
    bin.install artifact_path => "safehouse"
  end

  test do
    assert_match "(version 1)", shell_output("#{bin}/safehouse --stdout")
  end
end
EOF
}

main() {
  local raw_version_or_tag=""
  local tag version asset_url
  local asset_path formula_path sha256
  local tmpdir normalized_output

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tap-dir)
        [[ $# -ge 2 ]] || { echo "Missing value for --tap-dir" >&2; exit 64; }
        tap_dir="$(to_abs_path "$2")"
        shift 2
        ;;
      --tap-repo)
        [[ $# -ge 2 ]] || { echo "Missing value for --tap-repo" >&2; exit 64; }
        tap_repo_slug="$2"
        shift 2
        ;;
      --main-repo)
        [[ $# -ge 2 ]] || { echo "Missing value for --main-repo" >&2; exit 64; }
        main_repo_slug="$2"
        shift 2
        ;;
      --push)
        push_changes=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 64
        ;;
      *)
        if [[ -n "$raw_version_or_tag" ]]; then
          echo "Unexpected extra argument: $1" >&2
          usage >&2
          exit 64
        fi
        raw_version_or_tag="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$raw_version_or_tag" ]]; then
    usage >&2
    exit 64
  fi

  require_command curl
  require_command git
  require_command jq
  require_command shasum

  normalized_output="$(normalize_tag "$raw_version_or_tag")"
  tag="${normalized_output%%$'\n'*}"
  version="${normalized_output#*$'\n'}"

  asset_url="https://github.com/${main_repo_slug}/releases/download/${tag}/safehouse.sh"

  ensure_tap_checkout
  verify_tap_remote
  ensure_clean_git_worktree "$tap_dir"
  ensure_release_asset "$tag"

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/safehouse-homebrew.XXXXXX")"
  trap "rm -rf \"$tmpdir\"" EXIT
  asset_path="${tmpdir}/safehouse.sh"

  echo "Downloading release asset: ${asset_url}"
  curl -fsSL "$asset_url" -o "$asset_path"
  sha256="$(shasum -a 256 "$asset_path" | awk '{print $1}')"

  mkdir -p "${tap_dir}/Formula"
  formula_path="${tap_dir}/Formula/agent-safehouse.rb"
  write_formula "$formula_path" "$version" "$sha256" "$asset_url"

  git -C "$tap_dir" add Formula/agent-safehouse.rb

  if git -C "$tap_dir" diff --cached --quiet; then
    echo "Formula already matches ${tag}; nothing to commit."
    exit 0
  fi

  git -C "$tap_dir" commit -m "agent-safehouse ${tag}"

  if [[ "$push_changes" -eq 1 ]]; then
    git -C "$tap_dir" push origin HEAD
  else
    echo "Tap commit created locally. Re-run with --push to publish it."
  fi

  echo "Updated ${formula_path}"
  echo "sha256=${sha256}"
}

main "$@"
