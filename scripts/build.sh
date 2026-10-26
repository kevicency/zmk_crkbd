#!/usr/bin/env bash
# Build every target in build.yaml locally, mirroring the CI workflow.
# Output: firmware/*.uf2. The west workspace (zmk, zephyr, modules) is cached
# in the docker volume `zmk-west`; `docker volume rm zmk-west` resets it.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$repo/firmware"

docker run --rm \
  -v "$repo:/zmk-config:ro" \
  -v "$repo/firmware:/out" \
  -v zmk-west:/west \
  -w /west \
  zmkfirmware/zmk-build-arm:stable \
  bash -euo pipefail -c '
    mkdir -p config
    if ! cmp -s /zmk-config/config/west.yml config/west.yml; then
      cp /zmk-config/config/west.yml config/
      [ -d .west ] || west init -l config
      west update --fetch-opt=--filter=tree:0
    fi
    west zephyr-export >/dev/null

    python3 -c "
import yaml
for t in yaml.safe_load(open(\"/zmk-config/build.yaml\"))[\"include\"]:
    print(\"|\".join(t.get(k, \"\") for k in (\"board\", \"shield\", \"snippet\", \"cmake-args\", \"artifact-name\")))
" | while IFS="|" read -r board shield snippet cmake_args name; do
      name=${name:-${shield// /-}-$board}
      echo "==> $name"
      west build -p auto -s zmk/app -d "build/$name" -b "$board" ${snippet:+-S "$snippet"} -- \
        -DZMK_CONFIG=/zmk-config/config -DZMK_EXTRA_MODULES=/zmk-config \
        ${shield:+-DSHIELD="$shield"} $cmake_args </dev/null
      cp "build/$name/zephyr/zmk.uf2" "/out/$name.uf2"
    done
  '

ls -1 "$repo/firmware"
