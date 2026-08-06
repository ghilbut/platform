#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(git -C "$script_dir" rev-parse --show-toplevel)"
roots_file="$script_dir/opentofu-plan-roots.txt"

usage() {
  echo "Usage: $0 <root> [<root> ...]" >&2
}

is_managed_root() {
  local candidate="$1"
  local configured_root

  while IFS= read -r configured_root; do
    [[ -z "$configured_root" || "$configured_root" == \#* ]] && continue
    [[ "$configured_root" == "$candidate" ]] && return 0
  done < "$roots_file"

  return 1
}

run_plan() {
  local root_path="$1"

  echo "OpenTofu Plan: $root_path"

  if [[ -f "$repository_root/$root_path/tofu-apply.auto.tfvars" ]]; then
    echo "Apply provider override exists: $root_path/tofu-apply.auto.tfvars" >&2
    return 1
  fi

  if ! tofu -chdir="$repository_root/$root_path" init \
    -input=false \
    -lockfile=readonly \
    -no-color \
    -reconfigure; then
    return 1
  fi

  tofu -chdir="$repository_root/$root_path" plan \
    -input=false \
    -lock-timeout=30m \
    -no-color
}

[[ "$#" -gt 0 ]] || {
  usage
  exit 2
}

command -v tofu >/dev/null 2>&1 || {
  echo "OpenTofu executable is not available." >&2
  exit 1
}

if [[ -n "${TF_VAR_aws_execution_role_arn:-}" ]]; then
  echo "TF_VAR_aws_execution_role_arn is not allowed in OpenTofu Plan." >&2
  exit 1
fi

for cli_args_variable in TF_CLI_ARGS TF_CLI_ARGS_init TF_CLI_ARGS_plan; do
  if [[ -n "${!cli_args_variable:-}" ]]; then
    echo "$cli_args_variable is not allowed in OpenTofu Plan." >&2
    exit 1
  fi
done

failed_roots=()

for root_path in "$@"; do
  if ! is_managed_root "$root_path"; then
    echo "OpenTofu root is not in $roots_file: $root_path" >&2
    failed_roots+=("$root_path")
    continue
  fi

  if [[ ! -f "$repository_root/$root_path/versions.tf" ]]; then
    echo "OpenTofu root has no versions.tf: $root_path" >&2
    failed_roots+=("$root_path")
    continue
  fi

  if run_plan "$root_path"; then
    echo "OpenTofu Plan succeeded: $root_path"
  else
    echo "OpenTofu Plan failed: $root_path" >&2
    failed_roots+=("$root_path")
  fi
done

if [[ "${#failed_roots[@]}" -gt 0 ]]; then
  echo "Failed OpenTofu roots:" >&2
  printf '  %s\n' "${failed_roots[@]}" >&2
  exit 1
fi

echo "All requested OpenTofu Plans succeeded."
