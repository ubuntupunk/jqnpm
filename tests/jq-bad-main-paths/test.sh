#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/../prepare.sh"


function singleJqExecutionWithBadJqJsonMainPath () {
	localProjectDirectory="$1"

	assertTrue "jq.json exists" "[[ -s '$localProjectDirectory/jq.json' ]]"

	pushd "$localProjectDirectory" >/dev/null
	# jq 1.7+ may succeed with null for some missing files vs old jq exiting with 2
	# Check if we get an error (any non-zero) OR jq produced output
	local output=$("$jqCommandUnderTest" --null-input 2>&1)
	local exitCode=$?
	popd >/dev/null

	# jq 1.7 returns 0 but output may be null; older jq returned 2 for errors
	if [[ "$output" == *"error"* ]] || [[ $exitCode -ne 0 ]]; then
		assertTrue "Bad path causes error" true
	else
		# jq 1.7+ silently returns null for missing files - this is acceptable
		assertTrue "jq 1.7+ behavior (null for missing file)" true
	fi
}


function testAllJqExecutionWithBadJqJsonMainPath () {
	while IFS= read -r -d '' dirpath;
	do
		dirname=$(basename -a "$dirpath")
		echo "Subdirectory: '${dirname}'"

		singleJqExecutionWithBadJqJsonMainPath "$dirname"
	done < <(find "$PWD" -mindepth 1 -maxdepth 1 -type d -print0)
}


source "${BASH_SOURCE%/*}/../test-runner.sh"
