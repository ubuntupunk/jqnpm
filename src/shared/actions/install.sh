# Track install chain for circular dependency detection
declare -a INSTALL_CHAIN=()

function checkCircularDependency {
	local dep="$1"
	for installed in "${INSTALL_CHAIN[@]}"; do
		if [[ "$installed" == "$dep" ]]; then
			die 1 "Circular dependency detected: '$dep' is already being installed in this chain: ${INSTALL_CHAIN[*]}"
		fi
	done
	INSTALL_CHAIN+=("$dep")
}

function installSingle {
	(( "$#" != 1 && "$#" != 2 )) && die 100 "not the right number of arguments to '$FUNCNAME'"

	local installGlobal="false"
	if (( "$#" == "1" )) && [[ "$1" == "--global" || "$1" == "-g" ]];
	then
		die 100 "cannot install local project globally"
	elif (( "$#" == "2" ));
	then
		if [[ "$1" == "--global" || "$1" == "-g" ]];
		then
			installGlobal="true"
			shift
		else
			die 100 "unknown combination of arguments '$@' in '$FUNCNAME'"
		fi
	fi

	IFS='@' read -ra nameAndVersion <<< "$1"
	shift

	local dependencyName="${nameAndVersion[0]}"
	local dependencySemverRange="${nameAndVersion[1]}"

	checkCircularDependency "$dependencyName"

	if [[ "$installGlobal" == "true" ]];
	then
		debugInPackageIfAvailable 5 "(installing single) '${dependencyName}@${dependencySemverRange}' globally"
	else
		debugInPackageIfAvailable 5 "(installing single) '${dependencyName}@${dependencySemverRange}' starting in path: $(echo -nE "$PWD" | replaceHomeWithTilde)"
	fi

	# Make sure the remote repository is in the local cache.
	local noFetch=false
	if [[ "$1" == "--no-fetch" ]]; then
		noFetch=true
		shift
	fi

	if ! $noFetch; then
		"$JQNPM_SOURCE" fetch "${dependencyName}@${dependencySemverRange}"
	fi

	debugInPackageIfAvailable 4 "(installing) dependency '${dependencyName}'@'${dependencySemverRange}'"

	local cache="${JQNPM_PACKAGES_CACHE:-$config_default_packagesCache}/${dependencyName}"

	local installTarget

	if [[ "$installGlobal" == "true" ]];
	then
		local globalDependencyPath="${globalJqPackageBase}/${dependencyName}"
		installTarget="$globalDependencyPath"
	else
		createPackageRootIfNecessary

		local packageRoot=$(getLocalPackageRoot)
		local localDependencyPath="${packageRoot}/${localJqPackageBase}/${dependencyName}"
		installTarget="$localDependencyPath"
	fi

	debugInPackageIfAvailable 5 "(installing single) '${dependencyName}@${dependencySemverRange}' target: $(echo -nE "$installTarget" | replaceHomeWithTilde)"

	[[ -d "$installTarget" ]] && rm -r "$installTarget"
	mkdir -p "$installTarget"

	# Use `git archive` to copy git content instead of the repository.
	# Archive from the resolved tag if available, otherwise HEAD.
	pushd "$cache" >/dev/null
	local remote="${JQNPM_REMOTE_BASE:-$config_default_remoteBase}/${dependencyName}${JQNPM_REMOTE_SUFFIX:-$config_default_remoteSuffix}"
	local archiveRef="HEAD"
	if [[ -n "$dependencySemverRange" && "$dependencySemverRange" != "*" ]]; then
		local resolvedTag
		resolvedTag=$(getBestTagForRange "$remote" "$dependencySemverRange")
		[[ -n "$resolvedTag" ]] && archiveRef="$resolvedTag"
	fi
	debugInPackageIfAvailable 4 "(installing) archiving ref '${archiveRef}' from cache to '$(echo -nE "$installTarget" | replaceHomeWithTilde)'"
	git archive "$archiveRef" | tar x -C "$installTarget"
	popd >/dev/null

	# Make this installed package an unambiguous package root of its own.
	mkdir -p "${installTarget}/${packageMetadataDirectoryName}"

	# Install recursively.
	pushd "$installTarget" >/dev/null
	"$JQNPM_SOURCE" install
	popd >/dev/null
}

function installSingleManually {
	(( "$#" != 1 && "$#" != 2 )) && die 100 "not the right number of arguments to '$FUNCNAME'"
	debugInPackageIfAvailable 4 "(installing manually) '${1}' starting in path: $(echo -nE "$PWD" | replaceHomeWithTilde)"

	installSingle "$@"

	if [[ "$1" != "--global" && "$1" != "-g" ]];
	then
		# TODO: if semver range is empty, extract most recent dependency version, use it as the single '=1.2.3' range when saving.
		addOrUpdateDependencyAndRangeInJqJson "$1"
	fi
}

function installFromJqJson {
	(( "$#" != 0 )) && die 100 "not the right number of arguments to '$FUNCNAME'"
	requiresJqJson

debugInPackageIfAvailable 5 "(attempting install from jq.json) starting in path: $(echo -nE "$PWD" | replaceHomeWithTilde)"

	# Reads jq.json, puts files in ./jq/packages/

	# TODO: this array handling feels hacky.
	# https://mywiki.wooledge.org/BashFAQ/020
	unset directDependencyNames i
	while IFS= read -r -d '' dependencyName; do
		directDependencyNames[i++]="$dependencyName"
	done < <(getDirectDependencyNames)

	debugInPackageIfAvailable 4 "(preparing install) directDependencyNames: '${directDependencyNames[@]}'"

	hasDirectDependencies || return 0;

	for dependencyName in "${directDependencyNames[@]}";
	do
		local dependencySemverRange=$(getDirectDependencyVersion "$dependencyName")

		installSingle "${dependencyName}@${dependencySemverRange}"
	done
}

function install {
	(( "$#" > 2 )) && die 100 "not the right number of arguments to '$FUNCNAME'"

	if (( "$#" == 0 ));
	then
		installFromJqJson
	else
		installSingleManually "$@"
	fi
}
