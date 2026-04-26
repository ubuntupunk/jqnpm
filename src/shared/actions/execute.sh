# TODO: remove execute capabilities once jq is up to speed with the package import algorithm.
# One should not have to use `jqnpm execute` when `jq` is enough.
# https://github.com/joelpurra/jqnpm/blob/master/CONTRIBUTE.md#requirements-for-the-jq-binary
function jqArgumentsContainFileArgument {
  if arrayContainsValue "-f" "$@" || arrayContainsValue "--from-file" "$@" ]]; then
    return 0
  fi

  return 1
}

function execute {
  if hasPackageMetadataFile && isDebugAtLevel 4; then
    # TODO: this array handling feels hacky.
    # https://mywiki.wooledge.org/BashFAQ/020
    unset directDependencyNames i
    while IFS= read -r -d '' dependencyName; do
      directDependencyNames[i++]="$dependencyName"
    done < <(getDirectDependencyNames)

    local numberOfDirectDependencyNames="${#directDependencyNames[@]}"

    debugInPackageIfAvailable 4 "(preparing execute) numberOfDirectDependencyNames: ${numberOfDirectDependencyNames} directDependencyNames: '${directDependencyNames[@]}'"
  fi

  local usePackageMainJq="false"

  if jqArgumentsContainFileArgument "$@"; then
    debugInPackageIfAvailable 4 "(preparing execute) call contains '-f' or '--from-file' argument, skipping checking for main jq file."
  else
    if hasValidPackageMainJq; then
      local mainPath=$(getValidPackageMainJq)

      debugInPackageIfAvailable 3 "(preparing execute) found the main jq file: '${mainPath}'"

      usePackageMainJq="true"
    else
      debugInPackageIfAvailable 4 "(preparing execute) found no main jq file"
    fi
  fi

  # Collect all -L paths: main package, global ~/.jq, and all nested .jq/packages in dependencies
  local jqLoadPathArgs="-L $localJqPackageBase -L $HOME/.jq"

  if hasPackageMetadataFile && hasDirectDependencies; then
    local pkgRoot
    pkgRoot=$(getLocalPackageRoot)
    while IFS= read -r -d '' nestedPkg; do
      jqLoadPathArgs="$jqLoadPathArgs -L $nestedPkg"
    done < <(find "$pkgRoot/${localJqPackageBase}" -type d -name 'packages' -print0 2>/dev/null)

    if [[ "$usePackageMainJq" == "true" ]]; then
      debugInPackageIfAvailable 5 "(executing jq)" jq $jqLoadPathArgs -f "$mainPath" "$@"
      jq $jqLoadPathArgs -f "$mainPath" "$@"
    else
      debugInPackageIfAvailable 5 "(executing jq)" jq $jqLoadPathArgs "$@"
      jq $jqLoadPathArgs "$@"
    fi
  elif [[ "$usePackageMainJq" == "true" ]]; then
    # Take care when editing the follow line, so debugging information and actual command stay in sync.
    debugInPackageIfAvailable 5 "(executing jq)" jq -f "$mainPath" "$@"
    jq -f "$mainPath" "$@"
  else
    # Take care when editing the follow line, so debugging information and actual command stay in sync.
    debugInPackageIfAvailable 5 "(executing jq)" jq "$@"
    jq "$@"
  fi
}
