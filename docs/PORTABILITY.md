# Portability contract

- Runtime: one file; full Perl 5.10.0+ with its bundled core modules.
- UI: POSIX Termios plus ANSI/VT100 escapes. Linux and macOS have PTY integration
  coverage in CI. BSD-style window-size ioctl is implemented but real BSD runner
  coverage is pending. Other POSIX platforms fall back to LINES/COLUMNS or 24x80.
- Windows: byte-storage engine, ex commands, CLI, tests and batch mode. Native
  console raw input is not implemented; WSL provides the interactive environment.
- CPU: multi-gigabyte work should use 64-bit Perl with large-file seek support.
  32-bit/other architecture coverage and actual vintage hosts remain future work.
- Text: byte-oriented, ASCII display with escaped non-ASCII bytes; not Unicode
  character editing. Existing LF/CRLF/mixed endings and final-newline state survive.
- Optional: Perl::Tidy installed for the same interpreter as pvim, only for `:pt`.
- No curses, Term::ReadKey, make, compiler or privileged runtime installation.

Some Linux distributions split core Perl libraries into optional OS packages.
A Perl binary without its standard library is insufficient; the standalone file
bundles pvim itself, not a Perl interpreter or copies of the Perl core library.

## Verification record

The initial VM and GitHub Actions verification results will be added before the
human-testing prerelease is tagged. Configured jobs are not passed tests.

## File-write limitations

Atomic same-directory rename protects against partially written destination files
on normal write errors. Existing ordinary mode bits are copied. Symlink, hard-link
and read-only targets are refused. SHA-256 guards against changed file contents.
There is no atomic writer lock or compare-and-swap; do not concurrently edit the
same path. ACLs, xattrs, ownership preservation, crash recovery, fsync and durable
power-failure guarantees are outside this first release. This is an experimental
editor: begin human testing on copies of your files.
