#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/../prepare.sh"


function testImportRelativeJqFiles () {
	assertTrue "jq.json exists" "[[ -s 'local-project/jq.json' ]]"

	pushd "local-project" >/dev/null
	local result=$("$jqCommandUnderTest" --null-input 2>&1) || true
	local exitCode=$?
	popd >/dev/null

	# jq 1.7+ blocks parent directory traversal with an error
	# Older jq allowed it and would succeed (or error at runtime)
	if [[ "$result" == *"may not traverse to parent directories"* ]]; then
		assertTrue "jq 1.7+ blocks parent path traversal" true
	else
		assertEquals "Result" '"main.jq|same folder|subfolder|sibling folder|parent folder|folder outside of package"' "$result"
	fi
}


source "${BASH_SOURCE%/*}/../test-runner.sh"
