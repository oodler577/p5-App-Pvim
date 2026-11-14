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

Verified on 2026-11-14. All 24 required test jobs passed for 0.1.0, followed by a regression fix
for repeating zero-width line-end searches in 0.1.1. The tag workflow repeats
the complete suite before publishing each release. Assertion counts below
include the four additional line-end regressions in 0.1.1.
[Passing CI run](https://github.com/oodler577/pvim/actions/runs/43635261193).

| Environment | Perl versions | Verified behavior |
| --- | --- | --- |
| GitHub Ubuntu runner | 5.10, 5.16, 5.24, 5.32, 5.40, 5.42 | Syntax, POD, 2,653 assertions, eight PTY scenarios |
| GitHub macOS runner | 5.10, 5.16, 5.24, 5.32, 5.40, 5.42 | Syntax, POD, 2,653 assertions, eight PTY scenarios |
| GitHub Windows runner | 5.10, 5.16, 5.24, 5.32, 5.40, 5.42 | Syntax, POD, engine/CLI/batch suite; interactive UI explicitly unavailable |
| Debian bookworm slim | Distro Perl | Complete suite as unprivileged nobody |
| Ubuntu 24.04 container | Distro Perl | Complete suite as unprivileged nobody |
| Alpine 3.22 | Distro Perl, musl libc | Complete suite as unprivileged nobody |
| Fedora 43 | Distro Perl | Complete suite as unprivileged nobody |
| Optional formatting job | Perl 5.40 + Perl::Tidy | Actual formatting, key shortcut, undo and failure preservation |
| Packaging job | Runner Perl | Single-file relocation, help, batch editing and checksum verification |
| Development VM | Ubuntu 24.04.4, x86_64, Perl 5.38.2 | Complete suite, eight PTYs, packaging, 1/3 GiB benchmarks |

The 5.10 matrix resolves to 5.10.1. Perl 5.10.0 is the syntax/runtime target;
5.10.0 itself has not been executed. macOS PTY verification masks only the kernel's
PENDIN state flag, which the Darwin kernel sets upon returning to canonical mode;
all other terminal flags, speeds and control characters are compared. See
[Apple's terminal driver](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/tty.c).

## Measured large-file results

VM measurements use generated source-like lines of 257 bytes, no filesystem
compression, and `/usr/bin/time -v`. Each run performs 1,000 random
jump/edit/undo operations, saves a copy, and asserts equal SHA-256 digests.
The benchmark also validates offsets beyond 2 GiB in the ordinary test suite
using a sparse backing-file fixture.

| Input | Lines | Index/open | Save | Peak RSS | Jump/edit/undo p95 / p99 | Frame generation p95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 GiB | 4,177,983 | 15.69 s | 8.82 s | 17.38 MiB | 0.196 / 0.254 ms | Not measured in that run |
| 3 GiB | 12,533,951 | 45.26 s | 25.51 s | 17.38 MiB | 0.214 / 0.240 ms | 0.693 ms |

These are measurements on this VM, not universal latency guarantees. Frame
measurements generate ANSI output into a temporary file; remote SSH/network and
terminal display latency are not included. Indexing, search and saves remain
synchronous. The initial one-pass scan is the main opening delay. Peak RAM did
not increase from 1 GiB to 3 GiB for these line sizes and edit patterns. Very long
individual lines and accumulated fragmentation/undo history can use more memory.
Temporary files and undo data persist until the buffer is closed. Raw benchmark
logs are retained in the development workspace.

## File-write limitations

Atomic same-directory rename protects against partially written destination files
on normal write errors. Existing ordinary mode bits are copied. Symlink, hard-link
and read-only targets are refused. SHA-256 guards against changed file contents.
There is no atomic writer lock or compare-and-swap; do not concurrently edit the
same path. ACLs, xattrs, ownership preservation, crash recovery, fsync and durable
power-failure guarantees are outside this first release. This is an experimental
editor: begin human testing on copies of your files.
