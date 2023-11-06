#!/usr/bin/env bash

# SPDX-FileCopyrightText: Maximilian Huber <maximilian.huber@tngtech.com>
#
# SPDX-License-Identifier: CC0-1.0

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GITHUB_STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

main_for_wrapper() {
    local wrapper="$1"
    local root="$2"
    local failed="$3"

    find "$root" -maxdepth 1 -mindepth 1 -not -path '*/.*' -type d -print0 | while IFS= read -r -d '' supplier; do
        $wrapper get-supported-versions | while read -r version; do
            if [[ -d "$supplier/$version" ]]; then
                $wrapper get-supported-extensions | while read -r extension; do
                    find "$supplier/$version" -iname "*$extension" -print0 | while IFS= read -r -d '' spdx; do
                        echo
                        if $wrapper verify "$spdx"; then
                            echo "OK"
                        else
                            echo "FAILED"

                            GITHUB_SERVER_URL="${GITHUB_SERVER_URL:-.}"
                            GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-.}"
                            GITHUB_SHA="${GITHUB_SHA:-..}"

                            echo "* [$spdx]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/blob/$GITHUB_SHA/$spdx)" >> "$failed"
                        fi
                    done
                done
            fi
        done
    done
}

main() {
    local root="$1"
    local failed="$(mktemp)"

    main_for_wrapper "$SCRIPT_DIR/spdx-tools-java-wrapper.sh" "$root" "$failed"
    main_for_wrapper "$SCRIPT_DIR/spdx-tools-python-wrapper.sh" "$root" "$failed"

    cat "$failed" | sort -u > "$failed".sorted

    if [[ -s "$failed".sorted ]]; then
        local count
        count=$(wc -l < "$failed".sorted)
        echo -e "### The following $count \`.spdx\` files are invalid :x: (see the job logs for details)\n$(cat "$failed")" > "$GITHUB_STEP_SUMMARY"
        cat "$failed".sorted > "$GITHUB_STEP_SUMMARY"
        exit 1
    else
        echo "### All \`.spdx\` files are valid :heavy_check_mark:" > "$GITHUB_STEP_SUMMARY"
    fi
}

main "$@"