<p align="center">
  <a href="https://github.com/jqnpm/jqnpm"><img src="https://raw.githubusercontent.com/joelpurra/jqnpm/master/resources/logotype/penrose-triangle.svg?sanitize=true" alt="jqnpm logotype, a Penrose triangle" width="100" border="0" /></a>
</p>

# [jqnpm](https://github.com/jqnpm/jqnpm) — [jq](https://jqlang.org/) package manager

A package manager built for the command-line JSON processor [`jq`](https://jqlang.org/). Inspired by [`npm`](https://npmjs.org/), it brings namespaced packages, semantic versioning, and a local dependency tree to jq's module system.

<p align="center">
  <a href="https://github.com/jqnpm/jqnpm/">
    <img src="https://cloud.githubusercontent.com/assets/1398544/5852881/aaefa09c-a21d-11e4-9e7b-7c2c5574e0b6.gif" alt="jqnpm in action" border="0" />
  </a>
</p>

- Uses namespaced packages — `jqnpm install joelpurra/jq-stress` clones from [`github.com/joelpurra/jq-stress`](https://github.com/joelpurra/jq-stress).
- Uses strict [semantic versioning](https://semver.org/) tags.
- No central registry needed — packages are plain GitHub repositories.
- Works on Linux, macOS, and anywhere bash 4+ and jq 1.5+ are available.



## Requirements

- [jq](https://jqlang.org/) 1.5+
- [bash](https://www.gnu.org/software/bash/) 4+
- [git](https://git-scm.com/)
- [shUnit2](https://github.com/kward/shunit2) *(only needed to run the test suite)*



## Installation

There is no build step. Clone the repository and symlink the script onto your `$PATH`.

**Linux / macOS / any Unix**

```bash
git clone https://github.com/jqnpm/jqnpm.git ~/.jqnpm
ln -s ~/.jqnpm/src/jqnpm ~/.local/bin/jqnpm   # adjust target to any directory in $PATH
```

Verify:

```bash
jqnpm help
```

**macOS with Homebrew** *(legacy, may be out of date)*

```bash
brew install joelpurra/joelpurra/jqnpm
```



## Usage

```bash
jqnpm help
```


**Example 1 — install and use a package**

```shell
# Create a new project folder.
mkdir my-project
cd my-project/

# Create jq.json, jq/main.jq, and the local .jq/ folder.
jqnpm init

# Fetch a package from GitHub and install it into .jq/packages/.
jqnpm install joelpurra/jq-stress

# Write your jq code.
echo 'import "joelpurra/jq-stress" as Stress; Stress::remove("e")' > jq/main.jq

# Execute — jqnpm passes the correct -L path to jq automatically.
echo '"Hey there!"' | jqnpm execute
# => "Hy thr!"
```

**Example 2 — multiple dependencies**

`jq/main.jq` combining two packages after `jqnpm install joelpurra/jq-zeros && jqnpm install joelpurra/jq-dry`:

```jq
import "joelpurra/jq-zeros" as Zeros;
import "joelpurra/jq-dry" as DRY;

def fib($n):
    [ 0, 1 ]
    | DRY::repeat(
        $n;
        [
            .[1],
            (.[0] + .[1])
        ]
    )
    | .[0];

# Get the eighth Fibonacci number, pad it to four digits.
fib(8) | Zeros::pad(4; 0)
```

```shell
jqnpm execute --null-input
```



## How it works

`jqnpm execute` is a thin wrapper around `jq` that adds `-L .jq/packages` to the search path, making installed packages resolvable by name. Packages are cached in `~/.jq/cache/` and installed locally into `.jq/packages/` per project, similar to `node_modules`.

Packages are fetched from GitHub by default. The full install path for `joelpurra/jq-stress` is:

```
.jq/packages/joelpurra/jq-stress/jq/main.jq
```



## Creating a package

Share your code! 💓

**Guidelines**

- One piece of functionality per package — *do one thing, do it well*.
- Name your GitHub repository with a `jq-` prefix: `jq-good-tool`.
- The `jq.json` package name omits the prefix: `good-tool`.

**Steps**

1. [Create a new GitHub repository](https://github.com/new) named `jq-<your-tool>`.
2. Scaffold it locally:
   ```bash
   jqnpm generate <github-username> jq-<your-tool> "One sentence description"
   ```
3. Write your jq code in `jq/main.jq`.
4. Publish:
   ```bash
   git commit -am "Initial release"
   git push
   git tag -a v0.1.0 -m v0.1.0
   git push origin v0.1.0
   ```
5. Add it to the [jqnpm wiki package list](https://github.com/jqnpm/jqnpm/wiki) and tell the world!



## Environment variables

| Variable | Default | Description |
|---|---|---|
| `JQNPM_REMOTE_BASE` | `https://github.com` | Base URL for cloning packages |
| `JQNPM_REMOTE_SUFFIX` | `.git` | Suffix appended to repository URLs |
| `JQNPM_PACKAGES_CACHE` | `~/.jq/cache` | Local cache directory for cloned repos |
| `JQNPM_DEBUG_LEVEL` | *(unset)* | Set to `1`–`6` for log output (see [CONTRIBUTING.md](CONTRIBUTING.md)) |



## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).



## License

Copyright (c) 2014, 2015, [Joel Purra](https://joelpurra.com/). All rights reserved.

When using [**jqnpm**](https://github.com/jqnpm/jqnpm), comply with at least one of the three available licenses: BSD, MIT, GPL. See the `LICENSE*` files for details.
