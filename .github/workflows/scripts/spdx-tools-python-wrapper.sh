#!/usr/bin/env bash

# SPDX-FileCopyrightText: Maximilian Huber <maximilian.huber@tngtech.com>
# SPDX-FileCopyrightText: Sebastian Schuberth <sschuberth@gmail.com>
# SPDX-FileCopyrightText: Helio Chissini de Castro <heliocastro@gmail.com>
#
# SPDX-License-Identifier: CC0-1.0

set -euo pipefail

version="0.8.2"

bootstrap() {
    [[ -f "./venv/bin/activate" ]] && return

    python -m venv venv
    source ./venv/bin/activate
    pip install spdx-tools=="$version"

    ./venv/bin/pyspdxtools  --help
}

verify() {
    local spdx="$1"

    >&2 echo "Verify $spdx"

    ./venv/bin/pyspdxtools -i "$spdx"
}

if [[ "$1" == "bootstrap" ]]; then
    bootstrap
elif [[ "$1" == "verify" ]]; then
    shift
    verify "$@"
elif [[ "$1" == "get-supported-versions" ]]; then
    cat <<EOF
SPDX-2.3
EOF
elif [[ "$1" == "get-supported-extensions" ]]; then
    cat <<EOF
.spdx
.rdf.xml
.spdx.json
.spdx.xml
.spdx.yaml
EOF
else
    exit 1
fi
