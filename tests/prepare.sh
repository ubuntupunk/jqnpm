#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/shared-functions.sh"


function addJqnpmDirectoryToPath {
	# Make sure we're running the right `jqpm`.
	# TODO: might need to preprend ${BASH_SOURCE%/*}/ with $PWD/ to get the absolute path?
	local jqpmDirectory=$(resolveDirectory "${BASH_SOURCE%/*}/../src")

	export PATH="$jqpmDirectory:$PATH"
}

function selectJqCommandUnderTest {
	# Allow overriding the `jq` command in tests.
	unset jqCommandUnderTest

	if [[ -s "${BASH_SOURCE%/*}/jq-command-override.sh" ]];
	then
		jqCommandUnderTest=$(resolvePath "${BASH_SOURCE%/*}/jq-command-override.sh")
	else
		jqCommandUnderTest=$(resolvePath "${BASH_SOURCE%/*}/jq-command.sh")
	fi
}

addJqnpmDirectoryToPath
selectJqCommandUnderTest
