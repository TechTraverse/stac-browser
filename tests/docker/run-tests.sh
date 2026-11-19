#!/usr/bin/env bash
#
# Runs Docker image tests.
#
# Usage:
#   bash tests/docker/run-tests.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=tests/docker/common.sh
source "$SCRIPT_DIR/common.sh"

container_id=""
invalid_container_id=""
cleanup() {
  local id
  for id in "$container_id" "$invalid_container_id"; do
    if [[ -n "$id" ]]; then
      docker rm --force "$id" > /dev/null 2>&1 || true
    fi
  done
}
trap cleanup EXIT

echo "── Building Docker image ──"
build_image "$DOCKER_IMAGE"
echo "✓ Docker build passed"

echo "── Testing runtime configuration ──"
allowed_domains="example.com,quote's.test,back\\slash.test"
catalog_title=$'Earth\'s \\ catalog\nSecond line'
path_prefix="/browser/"
footer_links='[{"label":"Docs","url":"https://example.com/docs"}]'
container_id="$(
  docker run --detach --rm \
    --env "SB_allowedDomains=$allowed_domains" \
    --env "SB_catalogTitle=$catalog_title" \
    --env "SB_pathPrefix=$path_prefix" \
    --env "SB_footerLinks=$footer_links" \
    --env "SB_allowExternalAccess=1" \
    --env "SB_showFavorites=No" \
    --env "SB_displayPreview=Y" \
    --env "SB_preferredAssets=data" \
    "$DOCKER_IMAGE"
)"

runtime_config=""
for _ in $(seq 1 50); do
  # Image ships an empty stub (`window.STAC_BROWSER_CONFIG = {};`); wait for the
  # entrypoint to replace it. pathPrefix is always written by the entrypoint.
  if runtime_config="$(docker exec "$container_id" cat /usr/share/nginx/html/runtime-config.js 2>/dev/null)" \
    && [[ "$runtime_config" == *'pathPrefix:'* ]]; then
    break
  fi
  sleep 0.1
done
if [[ "$runtime_config" != *'pathPrefix:'* ]]; then
  echo "Runtime config was not generated in time" >&2
  exit 1
fi

RUNTIME_CONFIG="$runtime_config" PATH_PREFIX="$path_prefix" node <<'NODE'
const assert = require("node:assert/strict");

global.window = {};
eval(process.env.RUNTIME_CONFIG);

assert.deepEqual(window.STAC_BROWSER_CONFIG.allowedDomains, [
  "example.com",
  "quote's.test",
  "back\\slash.test",
]);
assert.equal(
  window.STAC_BROWSER_CONFIG.catalogTitle,
  "Earth's \\ catalog\nSecond line",
);
assert.equal(window.STAC_BROWSER_CONFIG.pathPrefix, process.env.PATH_PREFIX);
assert.deepEqual(window.STAC_BROWSER_CONFIG.footerLinks, [
  { label: "Docs", url: "https://example.com/docs" },
]);
assert.equal(window.STAC_BROWSER_CONFIG.allowExternalAccess, true);
assert.equal(window.STAC_BROWSER_CONFIG.showFavorites, false);
assert.equal(window.STAC_BROWSER_CONFIG.displayPreview, true);
// ["boolean", "string"]: a non-boolean value is kept as a string
assert.equal(window.STAC_BROWSER_CONFIG.preferredAssets, "data");
NODE

nginx_conf="$(docker exec "$container_id" cat /etc/nginx/conf.d/default.conf)"
assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "Expected nginx config to contain: $needle" >&2
    echo "$haystack" >&2
    exit 1
  fi
}
assert_contains "$nginx_conf" "location ${path_prefix}"
assert_contains "$nginx_conf" "location = /browser"

base_href="$(
  docker exec "$container_id" \
    sed -n 's/.*<base href="\([^"]*\)" id="stac-browser-base">.*/\1/p' /usr/share/nginx/html/index.html
)"
if [[ "$base_href" != "$path_prefix" ]]; then
  echo "Expected <base href=\"$path_prefix\">, got: $base_href" >&2
  exit 1
fi

echo "✓ Runtime configuration passed"

echo "── Testing invalid boolean configuration ──"
# An unrecognised boolean must stop the container instead of serving a
# truncated (syntactically invalid) runtime-config.js.
invalid_container_id="$(
  docker run --detach \
    --env "SB_allowExternalAccess=maybe" \
    "$DOCKER_IMAGE"
)"

running="true"
for _ in $(seq 1 100); do
  running="$(docker inspect --format '{{.State.Running}}' "$invalid_container_id")"
  [[ "$running" == "false" ]] && break
  sleep 0.1
done
if [[ "$running" != "false" ]]; then
  echo "Container with an invalid boolean is still running; expected it to exit" >&2
  docker exec "$invalid_container_id" cat /usr/share/nginx/html/runtime-config.js >&2 || true
  exit 1
fi

exit_code="$(docker inspect --format '{{.State.ExitCode}}' "$invalid_container_id")"
if [[ "$exit_code" == "0" ]]; then
  echo "Container with an invalid boolean exited with status 0; expected non-zero" >&2
  exit 1
fi

invalid_logs="$(docker logs "$invalid_container_id" 2>&1)"
if [[ "$invalid_logs" != *'SB_allowExternalAccess has unknown boolean value "maybe"'* ]]; then
  echo "Expected an error about SB_allowExternalAccess in the container logs:" >&2
  echo "$invalid_logs" >&2
  exit 1
fi

echo "✓ Invalid boolean configuration passed"
