# Contributing to jqpm

Thanks for your interest! jqpm (formerly jqnpm) is a small, focused project — contributions of any size are welcome.

- [Report a bug or suggest a feature](https://github.com/ubuntupunk/jqpm/issues)
- [Browse or add packages on the wiki](https://github.com/ubuntupunk/jqpm/wiki)
- Read on to contribute code.

## Development setup

**Requirements**

- [jq](https://jqlang.org/) 1.5+
- [bash](https://www.gnu.org/software/bash/) 4+
- [git](https://git-scm.com/)
- [shUnit2](https://github.com/kward/shunit2) 2.1.x+ in your `$PATH` *(tests only)*

**Clone and link**

```bash
git clone https://github.com/ubuntupunk/jqpm.git
cd jqpm
ln -s "$PWD/src/jqpm" ~/.local/bin/jqpm
```

No build step required — edits to `src/` take effect immediately.



## Making a change

1. Run `git clean -idX :/` to start from a clean state.
2. Create a branch: `git checkout -b my-fix`.
3. Edit files under `src/`.
4. Add or update tests in `tests/`.
5. If you changed anything under `tests/*/package-source/`, regenerate the bundles:
   ```bash
   ./tests/create-bundles.sh
   ```
6. Run the full test suite (see below).
7. Open a pull request against `master`.

Code with tests is much more likely to be merged without back-and-forth. Follow the existing conventions — the codebase is intentionally small and consistent.



## Running tests

```bash
./tests/all.sh
```

To run tests against the plain `jq` binary instead of the `jqpm execute` wrapper:

```bash
cd tests/
echo 'jq "$@"' > jq-command-override.sh
chmod u+x jq-command-override.sh
./all.sh
```



## Debugging

Set `JQNPM_DEBUG_LEVEL` to increase log verbosity:

```bash
JQNPM_DEBUG_LEVEL=4 jqpm execute
```

| Level | Meaning  |
|-------|----------|
| 0     | fatal    |
| 1     | errors   |
| 2     | warnings |
| 3     | info     |
| 4     | debug    |
| 5     | verbose  |
| 6     | trace    |

You can also override the remote base and cache locations for offline or isolated testing:

```bash
export JQNPM_PACKAGES_CACHE="${BASH_SOURCE%/*}/tests/package-cache"
export JQNPM_REMOTE_BASE="${BASH_SOURCE%/*}/tests/remote-base"
export JQNPM_REMOTE_SUFFIX=".bundle"
```



## Architecture

jqpm is plain bash — no compiled components. Source is under `src/`:

```
src/
  jqpm                        # entry point; checks deps, dispatches to actions
  shared/
    functions/
      basic.sh                 # die, logging helpers
      configuration.sh         # default values for remote base, cache path, etc.
      debug.sh                 # debug/log output
      filesystem-temp.sh       # mktemp wrapper, EXIT trap for cleanup
      git.sh                   # git helpers (clone, archive, HEAD hash)
      workarounds-jq.sh        # reserved for future jq compatibility shims
    metadata/
      jq.json.sh               # read/write jq.json (name, version, deps)
      main.jq.sh               # locate jq/main.jq for a package
      package-root.sh          # walk up to find the nearest .jq/ directory
      read.sh                  # read package metadata
      update.sh                # update jq.json dependencies
      validation.sh            # validate package structure
    actions/
      execute.sh               # jqpm execute — wraps jq with -L .jq/packages
      fetch.sh                 # clone/pull package repos into ~/.jq/cache
      generate.sh              # scaffold a new package skeleton
      help.sh                  # usage text
      initialize.sh            # jqpm init
      install.sh               # copy from cache into .jq/packages/, recurse
```

The key data flow for `jqpm install <user>/<pkg>`:

1. `fetch` — `git clone https://github.com/<user>/<pkg>.git` into `~/.jq/cache/<user>/<pkg>`
2. `install` — `git archive HEAD | tar x` into `.jq/packages/<user>/<pkg>/`
3. Recurse into the installed package and repeat for its own `jq.json` dependencies.

The key data flow for `jqpm execute`:

1. Locate the nearest `jq.json` and `jq/main.jq`.
2. Run `jq -L .jq/packages -f jq/main.jq [extra args]`.



## Known limitations

- **Recursive dependency resolution** requires all dependencies to be installed at the package root. Deep/nested resolution needs further work.
- **Semantic version matching** against git tags is not yet implemented — the latest commit on the default branch is always used.
- `jqpm execute` is a workaround. Once `jq` fully supports the `-L`-based resolution algorithm described below, plain `jq -L .jq/packages` will be sufficient.



## The jq module resolution algorithm jqpm expects

This is the algorithm the original author specified and which a future `jq` release should implement natively. For `import "<package>" as <alias>;`:

- Strings matching built-in jq modules take priority.
- Strings starting with `./`, `../`, or `/` are treated as file paths.
- All other strings are package names, resolved relative to `<package-root>/.jq/packages/`.
  - `<package-root>` is the nearest ancestor directory containing a `.jq/` subdirectory.
  - Let `D` = `<package-root>/.jq/packages/<package>/`
  - Resolve `F` from `D` by trying in order:
    1. `D/jq/main.jq`
    2. `D/data/main.json`
    3. The `main` property from `D/jq.json`
  - If none resolve, raise an error.



## Ideas and TODO

Patches welcome!

- Write additional tests; add asserts to existing ones.
- Implement semver tag matching (currently always uses HEAD).
- Implement `~/.jq/bin/` for globally installed executable jq scripts.
- Enforce `jq.json` `engines` version ranges at install/execute time.
- Support non-GitHub hosts more explicitly in documentation.
- Consider a lockfile (`jq.lock`) for reproducible installs.



## Background

jqpm (formerly jqnpm) was built to demonstrate and exercise jq's module system while it was still maturing. It is modelled on npm's conventions: namespaced packages, `jq.json` as the manifest, a local `.jq/packages/` tree, and a global cache. The core is intentionally kept in bash to remain dependency-free and portable.
