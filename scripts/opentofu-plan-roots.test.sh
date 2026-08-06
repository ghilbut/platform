#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test_directory="$(mktemp -d "${TMPDIR:-/tmp}/opentofu-plan-roots.XXXXXX")"

cleanup() {
  find "$test_directory" -depth -delete
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_output() {
  local expected="$1"
  local actual="$2"
  local description="$3"

  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: $description" >&2
    echo "Expected:" >&2
    printf '%s\n' "$expected" >&2
    echo "Actual:" >&2
    printf '%s\n' "$actual" >&2
    exit 1
  fi
}

trap cleanup EXIT

mkdir -p "$test_directory/scripts"
cp "$script_dir/opentofu-plan-roots.sh" "$test_directory/scripts/"
cp "$script_dir/opentofu-plan-roots.txt" "$test_directory/scripts/"

while IFS= read -r root_path; do
  [[ -z "$root_path" || "$root_path" == \#* ]] && continue
  mkdir -p "$test_directory/$root_path"
  touch "$test_directory/$root_path/versions.tf"
done < "$script_dir/opentofu-plan-roots.txt"

git -C "$test_directory" init --quiet
git -C "$test_directory" config user.email test@ghilbut.com
git -C "$test_directory" config user.name "OpenTofu Plan Test"
git -C "$test_directory" add .
git -C "$test_directory" commit --quiet -m initial

selector="$test_directory/scripts/opentofu-plan-roots.sh"
expected_all="$($selector all)"
[[ -n "$expected_all" ]] || fail "all returned no roots"

actual_all="$($selector all)"
assert_output "$expected_all" "$actual_all" "all returns every configured root"

base_revision="$(git -C "$test_directory" rev-parse HEAD)"
touch "$test_directory/README.md"
git -C "$test_directory" add README.md
git -C "$test_directory" commit --quiet -m unmanaged
head_revision="$(git -C "$test_directory" rev-parse HEAD)"

if ! empty_output="$($selector changed "$base_revision" "$head_revision")"; then
  fail "changed returned a failure when no managed root matched"
fi
assert_output "" "$empty_output" "changed returns no roots for an unmanaged change"

touch "$test_directory/apps/tofu/deleted.tf"
git -C "$test_directory" add apps/tofu/deleted.tf
git -C "$test_directory" commit --quiet -m add-deletion-fixture
base_revision="$(git -C "$test_directory" rev-parse HEAD)"
git -C "$test_directory" rm --quiet apps/tofu/deleted.tf
git -C "$test_directory" commit --quiet -m delete-managed-file
head_revision="$(git -C "$test_directory" rev-parse HEAD)"

deletion_output="$($selector changed "$base_revision" "$head_revision")"
assert_output "apps/tofu" "$deletion_output" "changed selects a root for a deleted file"

all_zero_output="$($selector changed 0000000000000000000000000000000000000000 HEAD)"
assert_output "$expected_all" "$all_zero_output" "all-zero base returns every root"

unreachable_output="$($selector changed ffffffffffffffffffffffffffffffffffffffff HEAD)"
assert_output "$expected_all" "$unreachable_output" "unreachable base returns every root"

echo "All OpenTofu Plan root selection tests passed."
