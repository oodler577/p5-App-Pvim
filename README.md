# pvim

[![Portability CI](https://github.com/oodler577/pvim/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/oodler577/pvim/actions/workflows/ci.yml)

A Perl-centric vi-style editor in **one Perl file**, targeting **Perl 5.10+**.
An experimental human-testing release, inspired by the everyday command set in
[Retrodores XVI2](https://github.com/retrodores/XVI/blob/master/readme.txt).
This is an independent implementation; no XVI2 code is included.

```sh
pvim hello.pl
pvim -v
pvim --help
pvim --manual
```

Install the CPAN-format release tarball with `cpanm`, or copy `pvim` to a
user-writable directory such as `~/.local/bin` and run `chmod +x ~/.local/bin/pvim`.
The standalone route needs no root, build step, compiler, or CPAN installation.
The single file is already the standalone distribution: fat-packing adds nothing
while its only required modules ship with full Perl 5.10+. Minimal distro Perl
packages may split core modules into separate OS packages; see portability notes.

Download the standalone file, source archive and checksums from
[Releases](https://github.com/oodler577/pvim/releases). The clearly named
`pvim-standalone.pl` asset is the same file. Save it as `pvim`, run
`chmod +x pvim`, then `./pvim file.pl`, or place it on PATH and run `pvim file.pl`.

[Wiki and quick start](https://github.com/oodler577/pvim/wiki) cover installation,
controls, Perl features and troubleshooting. Wiki sources are maintained in
`docs/wiki/` and synchronized from master by the development VM.

## First steps

- Press `i`, type, then Escape. `:w filename` saves, `:q` quits.
- Move with `hjkl`, arrows, `w b e`, `0 ^ $`, `gg G`, counts, and paging.
- Use `dd yy p P`, `x r R`, `o O`, same-line operators, `J`, `u` and Ctrl-R.
- Search with `/`, `?`, `n`, `N`. `:%s/old/new/g` substitutes across the file.
- File text is plain; syntax highlighting is deferred. Line numbers start off;
  `:set number` enables a yellow, three-column number field.
- `\t` (backslash then t), `:pt` / `:perltidy` formats with `-l 500` if the optional Perl::Tidy module is
  installed. It ignores tidy profiles, is undoable, and never saves automatically.
- Ctrl-Z suspends cleanly; `fg` resumes the same buffer and editing mode.
- `:! command` displays shell output; `:.! command` and `!!` filter the current
  line. `:2,10! command` / `:%! command` filter a range / file, and `:r !command`
  inserts output. Buffer edits are undoable; failed commands preserve text.
- An unnamed startup shows centered splash text that recenters on terminal resize;
  the community-message copy remains provisional.

The embedded POD is the complete command and CLI reference. No tabs, splits,
visual selection, dot-repeat, full Vim compatibility, or native Windows UI yet.
Interactive use requires a POSIX tty and ANSI/VT100 terminal. Windows batch mode
and the editing engine are tested separately from interactive terminal support.

## Large files

Contents and a fixed-width line index live in private temporary files; RAM does
not scale with initial file size. Opening streams/indexes the file once. Undo
stores edit pieces rather than file-sized copies. A bounded line cache and
changed-row rendering keep ordinary navigation and typing responsive. Saving
streams contiguous pieces. Set `TMPDIR` to a disk with sufficient free space:
roughly file size plus 24 bytes per line, plus subsequent edits and save space.

An individual line is materialized for editing/search/display. Huge single lines,
pathological regexes, whole-file substitutions and heavily fragmented undo
histories remain practical limits. Search/format/save are synchronous. Use a
64-bit Perl for multi-gigabyte files. See the POD's performance and safety notes.

## Automation and development

```sh
pvim --batch -c '%s/old/new/g' -c w file.pl
prove -v t
python3 tools/pty_test.py
perl tools/benchmark.pl 128
perl tools/release.pl
```

Batch mode makes the same command engine usable in scripts and agent workflows.
Writes are explicit; invalid commands exit nonzero. Shell execution is explicit through `!` filters; substitution replacement text
is never evaluated as Perl code.

[Testing and human checklist](docs/TESTING.md) ·
[Portability](docs/PORTABILITY.md) · [Changes](Changes)

Source is on `master`. CI tests old/current Perls across Linux, macOS and Windows,
plus minimal Linux distributions, optional tidy integration and real PTYs on
POSIX runners. Tagged releases wait for every required CI job before publishing.

## Future CPAN distribution: App::Pvim

The project is now packaged as **App::Pvim** for a future CPAN upload; it has not
been published to CPAN by this work. GitHub releases also provide the tested
`App-Pvim-VERSION.tar.gz` distribution. You can install that tarball into a
user-owned prefix with standard Perl build tools; consumers do not need Dist::Zilla.

Author commands (with Dist::Zilla installed):

```sh
dzil build
dzil test
```

`dist.ini` uses a local author plugin to read the version and runtime from `pvim`,
then generate `script/pvim` and `lib/App/Pvim.pm`. The module supplies the CPAN
namespace/version, not a second editor implementation or a library API. All
application code remains in the one standalone file. The CPAN build adds no
non-core runtime requirements; Perl::Tidy remains optional.

Do not run `dzil release` until a CPAN upload is intentionally authorized and PAUSE
permissions are verified. Normal CI and GitHub release jobs only build/test the
distribution; they never upload to PAUSE. See [CPAN preparation](docs/CPAN.md).
