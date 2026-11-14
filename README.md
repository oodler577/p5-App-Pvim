# pvim

[![Portability CI](https://github.com/oodler577/pvim/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/oodler577/pvim/actions/workflows/ci.yml)

A Perl-centric vi-style editor in **one Perl file**, targeting **Perl 5.10+**.
An experimental human-testing release, inspired by the everyday command set in
[Retrodores XVI2](https://github.com/retrodores/XVI/blob/master/readme.txt).
This is an independent implementation; no XVI2 code is included.

```sh
perl pvim hello.pl
perl pvim --help
perl pvim --manual
```

Copy `pvim` to a user-writable directory such as `~/.local/bin`, and optionally
`chmod +x ~/.local/bin/pvim`. No root, build step, compiler, or CPAN installation.
The single file is already the standalone distribution: fat-packing adds nothing
while its only required modules ship with full Perl 5.10+. Minimal distro Perl
packages may split core modules into separate OS packages; see portability notes.

Download the standalone file, source archive and checksums from
[Releases](https://github.com/oodler577/pvim/releases). The clearly named
`pvim-standalone.pl` asset is the same file and can be run with
`perl pvim-standalone.pl file.pl`.

[Wiki and quick start](https://github.com/oodler577/pvim/wiki) cover installation,
controls, Perl features and troubleshooting. Wiki sources are maintained in
`docs/wiki/` and synchronized from master by the development VM.

## First steps

- Press `i`, type, then Escape. `:w filename` saves, `:q` quits.
- Move with `hjkl`, arrows, `w b e`, `0 ^ $`, `gg G`, counts, and paging.
- Use `dd yy p P`, `x r R`, `o O`, same-line operators, `J`, `u` and Ctrl-R.
- Search with `/`, `?`, `n`, `N`. `:%s/old/new/g` substitutes across the file.
- Line numbers and approximate single-line Perl syntax colors are on by default.
- `\t` (backslash then t), `:pt` / `:perltidy` formats with `-l 500` if the optional Perl::Tidy module is
  installed. It ignores tidy profiles, is undoable, and never saves automatically.
- An unnamed startup shows a splash with provisional community-message text.

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
perl pvim --batch -c '%s/old/new/g' -c w file.pl
prove -v t
python3 tools/pty_test.py
perl tools/benchmark.pl 128
perl tools/release.pl
```

Batch mode makes the same command engine usable in scripts and agent workflows.
Writes are explicit; invalid commands exit nonzero. No shell commands or arbitrary
replacement-code evaluation are supported.

[Testing and human checklist](docs/TESTING.md) ·
[Portability](docs/PORTABILITY.md) · [Changes](Changes)

Source is on `master`. CI tests old/current Perls across Linux, macOS and Windows,
plus minimal Linux distributions, optional tidy integration and real PTYs on
POSIX runners. Tagged releases wait for every required CI job before publishing.
