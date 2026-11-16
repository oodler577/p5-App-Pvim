# Releases and standalone packaging

Use [GitHub Releases](https://github.com/oodler577/pvim/releases) and read the
release's prerelease flag/notes. The current documented version is @@VERSION@@.

| Asset | Purpose |
| --- | --- |
| `pvim-standalone.pl` | Complete single-file editor, POD and CLI; install as executable `pvim` and run `pvim file.pl` |
| `pvim` | Identical executable bytes under a short command name |
| `pvim-@@VERSION@@.tar.gz` | Source, tests, tools, license texts and documentation |
| `App-Pvim-@@VERSION@@.tar.gz` | CPAN-format source distribution for future App::Pvim publication |
| `SHA256SUMS` | SHA-256 values for all release downloads |

There are no required non-core pvim modules to resolve. The one-file distribution
already contains all of pvim's packages. It does not bundle Perl itself or the
optional formatter, so a separate FatPacker dependency is unnecessary. A full Perl
standard library is still required; see [Installation](Installation).

## Maintainer release process

1. Make code, tests, POD and wiki-source changes on `master`.
2. Run `prove t`, the POSIX PTY suite, `perl tools/wiki.pl --check`, and relevant benchmarks.
3. Update the embedded version, Changes and release notes together. Keep the
   splash title versionless: `pvim - portable vim clone`.
4. Run `perl tools/release.pl`; check the generated checksums and standalone script.
5. Commit/push and create an annotated `vVERSION` tag.
6. The tag workflow runs the platform/version suite, minimal-distro checks,
   formatter integration, documentation and packaging checks before publishing.
7. Confirm the release is present and verify the downloaded assets.

A tag must match the embedded editor version. Current automated publication marks
releases as prereleases for human testing. The wiki follows `master`, with its
version shown at publication; for an older release use that tag's embedded manual
and source archive. See [Documentation Maintenance](Documentation-Maintenance).

## App::Pvim distribution and PAUSE publication

The repository now contains `dist.ini`. Run `dzil build` and `dzil test` with
Dist::Zilla on the author machine. A local author plugin generates the CPAN
namespace module and installed command from the maintained `pvim` file; there is
no independently edited second runtime or version.

Consumers of `App-Pvim-VERSION.tar.gz` use standard `perl Makefile.PL`, `make test`
and `make install`, optionally with `INSTALL_BASE=/your/writable/prefix`.
Dist::Zilla and Moose are author/build-time tooling, not runtime requirements.
`App::Pvim` provides namespace/version metadata; run the `pvim` executable to edit.

CI builds/tests the CPAN tarball and installs it into a user-local prefix. GitHub
releases include it and checksum it alongside the standalone download. These jobs
never publish to PAUSE. A future `dzil release` requires intentional authorization
and confirmed PAUSE namespace permissions; it is not part of ordinary maintenance.

### Trimmed CPAN archive

The CPAN kit includes the runtime, generated installed command and App::Pvim
module, seven consumer test files, README, Changes, licenses, metadata,
Makefile.PL, dist.ini and its local build plugin. The root pvim copy remains
because the tests and author plugin use it.

Author tools and docs/wiki sources stay in Git; tools/ and docs/ are excluded
from the CPAN tarball. The full command manual is embedded in pvim and installs
as man pvim. Dist::Zilla and Moose are not consumer requirements.

After rebuilding, inspect the actual archive with tar -tzf; extracting over an
old directory does not remove stale files. Test from a fresh extraction with:

```sh
perl Makefile.PL
make test
```

The trimmed 0.1.13 kit passed the author's Perl 5.40.0 installation test: seven
test files and 2,725 checks, with clean test output. Optional Perl::Tidy coverage
can change the check count between machines. This verifies the kit; it does not
indicate that a PAUSE upload has occurred.

For single-file use, continue downloading `pvim-standalone.pl`; nothing needs to
be installed from CPAN. [Repository CPAN notes](https://github.com/oodler577/pvim/blob/master/docs/CPAN.md).
