# Releases and standalone packaging

Use [GitHub Releases](https://github.com/oodler577/pvim/releases) and read the
release's prerelease flag/notes. The current documented version is @@VERSION@@.

| Asset | Purpose |
| --- | --- |
| `pvim-standalone.pl` | Complete single-file editor, POD and CLI; run `perl pvim-standalone.pl file.pl` |
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
3. Update the embedded version, splash, Changes and release notes together.
4. Run `perl tools/release.pl`; check the generated checksums and standalone script.
5. Commit/push and create an annotated `vVERSION` tag.
6. The tag workflow runs the platform/version suite, minimal-distro checks,
   formatter integration, documentation and packaging checks before publishing.
7. Confirm the release is present and verify the downloaded assets.

A tag must match the embedded editor version. Current automated publication marks
releases as prereleases for human testing. The wiki follows `master`, with its
version shown at publication; for an older release use that tag's embedded manual
and source archive. See [Documentation Maintenance](Documentation-Maintenance).

## App::Pvim on CPAN: prepared, not uploaded

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

For single-file use, continue downloading `pvim-standalone.pl`; nothing needs to
be installed from CPAN. [Repository CPAN notes](https://github.com/oodler577/pvim/blob/master/docs/CPAN.md).
