# jqnpm Technical Debt & Gotchas

## Recently Completed
- [x] Semver version resolution (^1.0.0, ~1.0.0, >=1.0.0)
- [x] Nested dependencies (.jq/packages paths)
- [x] Default branch detection
- [x] jq 1.7 test compatibility
- [x] Ubuntu 24.04 (Travis CI)
- [x] Username/package validation, circular dep, --no-fetch

## In Progress

## Backlog (Priority Order)

### High Priority
- [x] Fix hardcoded `'master'` branch in `generate.sh` lines 102-103
- [x] Fix hardcoded `'origin" "master'` in `tests/create-bundles.sh` line 81
- [x] Add fallback to HEAD when no tags satisfy semver range

### Medium Priority
- [x] Add username format validation (generate.sh)
- [x] Add package name validation (generate.sh)
- [x] Implement `--no-fetch` flag (install.sh)
- [x] Detect circular dependencies (install.sh)
- [ ] Write unit tests per function (src/jqnpm)

### Low Priority
- [ ] Refactor array handling (hacky bash FAQ #020 pattern)
- [ ] Validate path format (filesystem-temp.sh)
- [ ] Separate shunit2 colorize alias
- [ ] Normalize configuration naming
- [ ] Check git capabilities (--single-branch --depth 1)

### Expected/Low (Future jq Features)
- [ ] Remove execute workaround (once jq supports -L natively)
- [ ] Remove jq workarounds in workarounds-jq.sh

## Known Limitations
- Deep dependency resolution requires packages at root level
- Only GitHub remotes supported (no generic git)
- No lockfile for reproducible installs

## Testing Status
- 17/17 tests passing (jq 1.7)
- 2 legacy tests updated for jq 1.7 behavior