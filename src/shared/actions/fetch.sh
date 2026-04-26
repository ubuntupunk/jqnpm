function fetchSingle {
	(( "$#" != 1 )) && die 100 "not the right number of arguments to '$FUNCNAME'"
	IFS='@' read -ra nameAndVersion <<< "$1"
	shift

	local dependencyName="${nameAndVersion[0]}"
	local dependencySemverRange="${nameAndVersion[1]}"

	debugInPackageIfAvailable 4 "(fetching single) dependency '${dependencyName}'@'${dependencySemverRange}' starting in path: $(echo -nE "$PWD" | replaceHomeWithTilde)"

	# TODO: use a local folder per remote server, /github.com/?
	# TODO: make building remote and cache variables functions.
	local remote="${JQNPM_REMOTE_BASE:-$config_default_remoteBase}/${dependencyName}${JQNPM_REMOTE_SUFFIX:-$config_default_remoteSuffix}"
	local cache="${JQNPM_PACKAGES_CACHE:-$config_default_packagesCache}/${dependencyName}"

	# Resolve the best matching tag for the requested semver range.
	local resolvedTag=""
	if [[ -n "$dependencySemverRange" && "$dependencySemverRange" != "*" ]]; then
		debugInPackageIfAvailable 3 "Resolving best tag for '${dependencyName}'@'${dependencySemverRange}' from '${remote}'"
		resolvedTag=$(getBestTagForRange "$remote" "$dependencySemverRange")
		if [[ -n "$resolvedTag" ]]; then
			debugInPackageIfAvailable 3 "Resolved tag: '${resolvedTag}'"
		else
			debugInPackageIfAvailable 3 "No tags found for '${dependencySemverRange}', using HEAD"
		fi
	fi

	if [[ ! -d "$cache" ]]; then
		mkdir -p "$cache"

		debugInPackageIfAvailable 3 "Cloning repository '$(echo -nE "$remote" | replaceHomeWithTilde)' to '$(echo -nE "$cache" | replaceHomeWithTilde)'"

		if [[ -n "$resolvedTag" ]]; then
			git -c advice.detachedHead=false clone --branch "$resolvedTag" --single-branch --depth 1 "$remote" "$cache"
		else
			git clone --single-branch --depth 1 "$remote" "$cache"
		fi
	else
		pushd "$cache" >/dev/null
		debugInPackageIfAvailable 3 "Fetching new commits '$(echo -nE "$remote" | replaceHomeWithTilde)' to '$(echo -nE "$cache" | replaceHomeWithTilde)'"

		local defaultBranch
		defaultBranch=$(getDefaultBranch)
		if [[ -z "$defaultBranch" ]]; then
			defaultBranch="main"
		fi

		if [[ -n "$resolvedTag" ]]; then
			# Fetch the specific tag and check it out.
			git fetch --depth 1 origin "refs/tags/${resolvedTag}:refs/tags/${resolvedTag}" &>/dev/null
			git checkout "$resolvedTag" &>/dev/null
		else
			# No version constraint — update to latest on the default branch.
			git reset --hard &>/dev/null
			git checkout "$defaultBranch" &>/dev/null
			git reset --hard "$defaultBranch" &>/dev/null
			git pull --rebase --quiet &>/dev/null
			git reset --hard "$defaultBranch" &>/dev/null
		fi
		popd >/dev/null
	fi

	pushd "$cache" >/dev/null
	debugInPackageIfAvailable 3 "Current package commit hash is '$(getHEADCommitHash)' in '$(echo -nE "$cache" | replaceHomeWithTilde)'"
	popd >/dev/null

	# Fetch recursively.
	pushd "$cache" >/dev/null
	"$JQNPM_SOURCE" fetch
	popd >/dev/null
}

function fetchSingleManually {
	(( "$#" != 1 )) && die 100 "not the right number of arguments to '$FUNCNAME'"
	debugInPackageIfAvailable 4 "(fetching manually) '${1}' starting in path: $(echo -nE "$PWD" | replaceHomeWithTilde)"

	fetchSingle "$1"
}

function fetchFromJqJson {
	(( "$#" != 0 )) && die 100 "not the right number of arguments to '$FUNCNAME'"
	# TODO: enable arguments controlling what is being fetched.
	# For now, assume jq.json is being used, or die.
	requiresJqJson

	debugInPackageIfAvailable 5 "(attempting fetch from jq.json) starting in path: $(echo -nE "$PWD" | replaceHomeWithTilde)"

	# Reads jq.json, clone remote repos to ./jq/packages/username/reponame
	# This continues recursively.

	# TODO: this array handling feels hacky.
	# https://mywiki.wooledge.org/BashFAQ/020
	unset directDependencyNames i
	while IFS= read -r -d '' dependencyName; do
		directDependencyNames[i++]="$dependencyName"
	done < <(getDirectDependencyNames)

	debugInPackageIfAvailable 4 "(preparing fetch) directDependencyNames: '${directDependencyNames[@]}'"

	hasDirectDependencies || return 0;

	for dependencyName in "${directDependencyNames[@]}";
	do
		local dependencySemverRange=$(getDirectDependencyVersion "$dependencyName")

		fetchSingle "${dependencyName}@${dependencySemverRange}"
	done
}

function fetch {
	(( "$#" > 1 )) && die 100 "not the right number of arguments to '$FUNCNAME'"
	if [[ -z "$1" ]];
	then
		fetchFromJqJson
	else
		fetchSingleManually "$1"
	fi
}
