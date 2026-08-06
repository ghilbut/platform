#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(git -C "$script_dir" rev-parse --show-toplevel)"
roots_file="$script_dir/opentofu-plan-roots.txt"

usage() {
  echo "Usage: $0 all | changed <base-revision> <head-revision>" >&2
}

load_roots() {
  roots=()

  while IFS= read -r root_path; do
    [[ -z "$root_path" || "$root_path" == \#* ]] && continue

    if [[ ! -f "$repository_root/$root_path/versions.tf" ]]; then
      echo "OpenTofu root has no versions.tf: $root_path" >&2
      exit 1
    fi

    roots+=("$root_path")
  done < "$roots_file"
}

print_all_roots() {
  printf '%s\n' "${roots[@]}"
}

contains_root() {
  local candidate="$1"
  local selected_root

  for selected_root in "${selected_roots[@]-}"; do
    [[ "$selected_root" == "$candidate" ]] && return 0
  done

  return 1
}

select_root() {
  local root_path="$1"

  contains_root "$root_path" || selected_roots+=("$root_path")
}

select_changed_roots() {
  local base_revision="$1"
  local head_revision="$2"
  local changed_path
  local root_path

  if [[ "$base_revision" =~ ^0+$ ]]; then
    print_all_roots
    return
  fi

  if ! git -C "$repository_root" cat-file -e "${base_revision}^{commit}" 2>/dev/null; then
    print_all_roots
    return
  fi

  git -C "$repository_root" cat-file -e "${head_revision}^{commit}"

  selected_roots=()
  while IFS= read -r changed_path; do
    [[ -z "$changed_path" ]] && continue

    case "$changed_path" in
      .github/workflows/opentofu-plan.yml | scripts/opentofu-plan-roots.txt | scripts/opentofu-plan-roots.sh | scripts/opentofu-plan.sh)
        print_all_roots
        return
        ;;
      aws/cdn/*)
        select_root "aws/cdn/tofu"
        ;;
    esac

    for root_path in "${roots[@]}"; do
      if [[ "$changed_path" == "$root_path" || "$changed_path" == "$root_path/"* ]]; then
        select_root "$root_path"
      fi
    done
  done < <(
    git -C "$repository_root" diff \
      --name-only \
      "$base_revision" \
      "$head_revision" \
      --
  )

  for root_path in "${roots[@]}"; do
    contains_root "$root_path" && printf '%s\n' "$root_path"
  done

  return 0
}

if [[ ! -f "$roots_file" ]]; then
  echo "OpenTofu root list does not exist: $roots_file" >&2
  exit 1
fi

load_roots

case "${1:-}" in
  all)
    [[ "$#" -eq 1 ]] || {
      usage
      exit 2
    }
    print_all_roots
    ;;
  changed)
    [[ "$#" -eq 3 ]] || {
      usage
      exit 2
    }
    select_changed_roots "$2" "$3"
    ;;
  *)
    usage
    exit 2
    ;;
esac
