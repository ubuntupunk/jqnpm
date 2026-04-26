# NOTE: Array Handling Pattern

The original "hacky" pattern is acceptable for now. The clean `mapfile` approach was tried but caused test failures, likely due to the bash/shell environment in the test CI. The current pattern works reliably - it's just ugly. The TODO is low priority cosmetic debt.

The pattern:
```bash
unset directDependencyNames i
while IFS= read -r -d '' dependencyName; do
    directDependencyNames[i++]="$dependencyName"
done < <(getDirectDependencyNames)
```

This will be addressed when there's a stronger reason to refactor it.
