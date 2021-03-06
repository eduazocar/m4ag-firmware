#!/usr/bin/env bash
#
# Copyright (C) 2017 Alexandre Abadie <alexandre.abadie@inria.fr>
#
# This file is subject to the terms and conditions of the GNU Lesser
# General Public License v2.1. See the file LICENSE in the top level
# directory for more details.
#
. "$(dirname "$0")/../ci/github_annotate.sh"
github_annotate_setup

FLAKE8_CMD="python3 -m flake8"

if tput colors &> /dev/null && [ "$(tput colors)" -ge 8 ]; then
    CERROR=$'\033[1;31m'
    CRESET=$'\033[0m'
else
    CERROR=
    CRESET=
fi

: "${RIOTBASE:=$(cd $(dirname $0)/../../../; pwd)}"
cd $RIOTBASE

: "${RIOTTOOLS:=${RIOTBASE}/dist/tools}"
. "${RIOTTOOLS}"/ci/changed_files.sh

EXCLUDE="^(.+/vendor/\
|RIOT/*\
|dist/tools/*)"
FILEREGEX='(\.py$|pyterm$)'
FILES=$(FILEREGEX=${FILEREGEX} EXCLUDE=${EXCLUDE} changed_files)

if [ -z "${FILES}" ]
then
    exit 0
fi

${FLAKE8_CMD} --version &> /dev/null || {
    printf "%s%s: cannot execute \"%s\"!%s\n" "${CERROR}" "$0" "${FLAKE8_CMD}" "${CRESET}"
    exit 1
}

ERRORS=$(${FLAKE8_CMD} --config="${RIOTTOOLS}"/flake8/flake8.cfg ${FILES})

if github_annotate_is_on; then
    echo "${ERRORS}" | grep "^.\+:[0-9]\+:" | while read line; do
        FILENAME=$(echo "${line}" | cut -d: -f1)
        LINENR=$(echo "${line}" | cut -d: -f2)
        DETAILS=$(echo "${line}" | cut -d: -f4- |
                  sed -e 's/^[ \t]*//' -e 's/[ \t]*$//')
        github_annotate_error "${FILENAME}" "${LINENR}" "${DETAILS}"
    done
fi

github_annotate_teardown

if [ -n "${ERRORS}" ]
then
    printf "%sThere are style issues in the following Python scripts:%s\n\n" "${CERROR}" "${CRESET}"
    printf "%s\n" "${ERRORS}"
    exit 1
else
    exit 0
fi
