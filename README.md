# danmackinlay/tap

A personal [Homebrew](https://brew.sh) tap.

```sh
brew install danmackinlay/tap/<formula>
```

Or `brew tap danmackinlay/tap` first, then `brew install <formula>`. In a `Brewfile`:

```ruby
tap "danmackinlay/tap"
brew "hister"
```

## Formulae

### hister

[Hister](https://hister.org) is a personal search engine over the pages you visit
and the files on your disk. AGPL-3.0-or-later, by [asciimoo](https://github.com/asciimoo/hister).

```sh
brew install danmackinlay/tap/hister
brew services start hister
```

The web UI is then on <http://127.0.0.1:4433>, and the launchd agent restarts it
unless it exits cleanly. Data lives in `~/Library/Application Support/hister`;
logs go to `$(brew --prefix)/var/log/hister.log`.

Nothing is indexed until you connect a source — install the
[browser extension](https://hister.org/docs/browser-extension), or seed the index
from history you already have with `hister import-browser`.

Config is optional. To write one:

```sh
hister create-config ~/Library/Preferences/hister/config.yml
```

## Notes for future me

**These formulae install prebuilt release binaries, not source builds.** That is
fine in a third-party tap; it is only [homebrew-core](https://docs.brew.sh/Acceptable-Formulae)
that requires building from source. Two consequences:

- No bottles, and no bottle-building CI. A bottle caches a source build; there is
  no source build here, so it would only repackage the binary we already fetched.
  `.github/workflows/lint.yml` runs style, audit, install and test instead.
- The release artefacts are bare binaries rather than archives, so they arrive
  mode 0644 and the formula has to `chmod 0755` them. Without that, install fails
  with `EACCES` during completion generation.

**Bumping a version.** `brew livecheck --tap danmackinlay/tap` reports what is out;
the weekly CI run does the same and prints it in the job log. To update all four
url/sha256 pairs at once:

```sh
brew bump-formula-pr --write-only --version=<new> danmackinlay/tap/hister
```

Then `brew audit --strict --online --tap danmackinlay/tap` before committing.

**`brew services` is formula-only.** Casks have no `service` stanza, so anything
here that needs a launchd agent has to stay a formula even though Homebrew's
docs otherwise point binary-only software at casks.
