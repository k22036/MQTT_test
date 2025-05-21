#!/bin/bash
set -e

# Find project or workspace file
FILE_TO_BUILD=""
FILETYPE_PARAMETER=""

if [[ -n $(find . -maxdepth 1 -name '*.xcworkspace') ]]; then
    FILE_TO_BUILD=$(find . -maxdepth 1 -name '*.xcworkspace')
    FILETYPE_PARAMETER="workspace"
elif [[ -n $(find . -maxdepth 1 -name '*.xcodeproj') ]]; then
    FILE_TO_BUILD=$(find . -maxdepth 1 -name '*.xcodeproj')
    FILETYPE_PARAMETER="project"
else
    echo "Error: No .xcworkspace or .xcodeproj found in the repository root."
    exit 1
fi

# Determine Scheme to use
SCHEME="${SCHEME:-}"

if [ -z "$SCHEME" ]; then
    SCHEMES_JSON=$(xcodebuild -list -json -${FILETYPE_PARAMETER} "${FILE_TO_BUILD}")
    if command -v jq &> /dev/null; then
        SCHEMES=$(echo "${SCHEMES_JSON}" | jq -r ".${FILETYPE_PARAMETER}.schemes | join(\" \")")
    else
        SCHEMES=$(echo "${SCHEMES_JSON}" | ruby -e "require 'json'; data = JSON.parse(STDIN.gets); schemes = data['${FILETYPE_PARAMETER}']['schemes']; puts schemes.join(' ') if schemes")
    fi
    if [ -z "$SCHEMES" ]; then
            echo "Error: No schemes found in ${FILE_TO_BUILD}."
            exit 1
    fi
    SCHEME_ARRAY=(${SCHEMES})
    if [ ${#SCHEME_ARRAY[@]} -eq 1 ]; then
        SCHEME=${SCHEME_ARRAY[0]}
    else
        echo "Error: SCHEME environment variable is not set, and there is not exactly one scheme available."
        echo "Available schemes: ${SCHEMES}"
        exit 1
    fi
else
    SCHEMES_JSON=$(xcodebuild -list -json -${FILETYPE_PARAMETER} "${FILE_TO_BUILD}")
    if command -v jq &> /dev/null; then
        AVAILABLE_SCHEMES=$(echo "${SCHEMES_JSON}" | jq -r ".${FILETYPE_PARAMETER}.schemes | join(\" \")")
    else
        AVAILABLE_SCHEMES=$(echo "${SCHEMES_JSON}" | ruby -e "require 'json'; data = JSON.parse(STDIN.gets); schemes = data['${FILETYPE_PARAMETER}']['schemes']; puts schemes.join(' ') if schemes")
    fi
    if [[ ! " ${AVAILABLE_SCHEMES} " =~ " ${SCHEME} " ]]; then
            echo "Error: Specified scheme '${SCHEME}' does not exist in ${FILE_TO_BUILD}."
            echo "Available schemes: ${AVAILABLE_SCHEMES}"
            exit 1
    fi
fi

# Execute xcodebuild command (build only)
echo "Running: xcodebuild clean build -scheme \"${SCHEME}\" -\"${FILETYPE_PARAMETER}\" \"${FILE_TO_BUILD}\""
xcodebuild clean build \
    -scheme "${SCHEME}" \
    -"${FILETYPE_PARAMETER}" "${FILE_TO_BUILD}"

EXIT_STATUS=$?
if [ ${EXIT_STATUS} -ne 0 ]; then
    echo "xcodebuild command failed with exit status ${EXIT_STATUS}."
    exit ${EXIT_STATUS}
fi

echo "Build completed successfully."
