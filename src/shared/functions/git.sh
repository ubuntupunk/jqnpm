function getHEADCommitHash {
	git rev-parse --short --verify HEAD
}

function getDefaultBranch {
	# Detect the remote default branch rather than assuming 'master'.
	git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
}

# Return "true" if the given version (vX.Y.Z or X.Y.Z) satisfies the semver range.
# Supports: ^X.Y.Z  ~X.Y.Z  >=X.Y.Z  >X.Y.Z  X.Y.Z (exact)  *  "" (any)
function semverSatisfies {
	(( "$#" != 2 )) && die 100 "not the right number of arguments to '$FUNCNAME'"
	local version="${1#v}"
	local range="$2"
	local op="" range_ver=""

	if [[ "$range" == "^"* ]]; then
		op="^"; range_ver="${range#^}"
	elif [[ "$range" == "~"* ]]; then
		op="~"; range_ver="${range#\~}"
	elif [[ "$range" == ">="* ]]; then
		op=">="; range_ver="${range#>=}"
	elif [[ "$range" == ">"* ]]; then
		op=">"; range_ver="${range#>}"
	elif [[ -z "$range" || "$range" == "*" ]]; then
		echo "true"; return 0
	else
		op="="; range_ver="$range"
	fi
	range_ver="${range_ver#v}"

	local rmaj rmin rpat
	IFS='.' read -r rmaj rmin rpat <<< "$range_ver"

	local gte_ok=false gte_lowest
	gte_lowest=$(printf '%s\n' "$range_ver" "$version" | sort -V | head -1)
	[[ "$gte_lowest" == "$range_ver" ]] && gte_ok=true

	case "$op" in
		"^")
			local upper
			(( rmaj > 0 )) && upper="$(( rmaj + 1 )).0.0" || upper="${rmaj}.$(( rmin + 1 )).0"
			local lt_lowest lt_ok=false
			lt_lowest=$(printf '%s\n' "$version" "$upper" | sort -V | head -1)
			[[ "$lt_lowest" == "$version" && "$version" != "$upper" ]] && lt_ok=true
			$gte_ok && $lt_ok && echo "true" || echo "false"
			;;
		"~")
			local upper="${rmaj}.$(( rmin + 1 )).0"
			local lt_lowest lt_ok=false
			lt_lowest=$(printf '%s\n' "$version" "$upper" | sort -V | head -1)
			[[ "$lt_lowest" == "$version" && "$version" != "$upper" ]] && lt_ok=true
			$gte_ok && $lt_ok && echo "true" || echo "false"
			;;
		">=") $gte_ok && echo "true" || echo "false" ;;
		">")  $gte_ok && [[ "$version" != "$range_ver" ]] && echo "true" || echo "false" ;;
		"=")  [[ "$version" == "$range_ver" ]] && echo "true" || echo "false" ;;
	esac
}

# Given a remote URL and a semver range, return the highest matching vX.Y.Z tag.
# Returns empty string if no tag satisfies the range.
function getBestTagForRange {
	(( "$#" != 2 )) && die 100 "not the right number of arguments to '$FUNCNAME'"
	local remote="$1"
	local range="$2"
	local best=""

	while IFS= read -r tag; do
		if [[ "$(semverSatisfies "$tag" "$range")" == "true" ]]; then
			if [[ -z "$best" ]]; then
				best="$tag"
			else
				best=$(printf '%s\n' "$best" "$tag" | sort -V | tail -1)
			fi
		fi
	done < <(git ls-remote --tags "$remote" 2>/dev/null \
		| grep -v '\^{}' \
		| sed 's|.*refs/tags/||' \
		| grep '^v[0-9]')

	echo "$best"
}
