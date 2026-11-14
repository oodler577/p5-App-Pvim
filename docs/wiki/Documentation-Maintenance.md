# Keeping documentation current

Wiki source lives in the main repository under `docs/wiki/`. The complete manual
and command reference are generated from `pvim`'s embedded POD; testing, portability
and change-history pages are generated from their corresponding repository files.
The version and download URLs are filled from the executable's actual version.
Do not edit a generated wiki page as the permanent source of a change.

```sh
perl tools/wiki.pl --check
perl tools/wiki.pl --output /path/to/pvim.wiki
sh tools/publish-wiki.sh /path/to/pvim.wiki
```

The checker validates generated page links, required pages, unresolved template
markers and source POD. CI runs it on every push/PR and gates release publication.
The publishing command requires a clean wiki checkout, pulls it with fast-forward
only, generates managed pages, commits changes only if needed, and pushes through
the checkout's existing remote. It preserves files outside the generated manifest.
It neither creates nor copies SSH keys or access tokens.

The development VM has a dedicated hourly publisher following `origin/master`,
using its already-authorized SSH access to `git@github.com:oodler577/pvim.wiki.git`.
It uses a separate source checkout and a non-overlapping lock, so it does not alter
the development working tree. No changes means no wiki commit. Failures are logged
on the VM for investigation; the job does not bypass dirty/diverged-checkout guards.

Whenever code behavior changes, update its POD, relevant authored wiki pages,
examples/tests and release notes in the same source commit. The generator prevents
stale copied references, but it cannot prove that prose accurately describes a new
feature. Future project agents are instructed to maintain these sources.

GitHub wiki clone:

```sh
git clone git@github.com:oodler577/pvim.wiki.git
```

Publishing is also done immediately when documentation is deliberately updated;
the hourly job catches subsequent master updates. No separate release is required
for a wiki-only correction.
