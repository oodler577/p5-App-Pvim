# Portability and restricted hosts

pvim is intended to become a highly capable Vim replacement for accounts where
Perl is available but Vim is missing and installing packages is out of reach.
Shared web hosting and minimal Unix installs without gcc or make are intended
use cases. The standalone file needs neither, but the account still needs an
interactive shell/terminal, permission to run scripts and writable temporary
space. The test record below covers platforms, not every hosting provider's
account policy.

- Runtime: one file; full Perl 5.10.0+ with its bundled core modules.
- UI: POSIX Termios plus ANSI/VT100 escapes. Linux and macOS have PTY integration
  coverage in CI. BSD-style window-size ioctl is implemented but real BSD runner
  coverage is pending. Other POSIX platforms fall back to LINES/COLUMNS or 24x80.
- Windows: byte-storage engine, ex commands, CLI, tests and batch mode. Native
  console raw input is not implemented; WSL provides the interactive environment.
- CPU: verified runner coverage includes Linux/Windows x86-64 and macOS ARM64.
  Multi-gigabyte work should use 64-bit Perl with large-file seek support.
  32-bit builds, other CPU architectures and actual vintage hosts are unverified.
- Text: byte-oriented, ASCII display with escaped non-ASCII bytes; not Unicode
  character editing. Existing LF/CRLF/mixed endings and final-newline state survive.
- Optional: Perl::Tidy installed for the same interpreter as pvim, only for `:pt`.
- No curses, Term::ReadKey, make, compiler or privileged runtime installation.

Some Linux distributions split core Perl libraries into optional OS packages.
A Perl binary without its standard library is insufficient; the standalone file
bundles pvim itself, not a Perl interpreter or copies of the Perl core library.

## What the opening title claims

The splash reads **pvim - portable vim clone**. Here, portable means that the
single-file source and tested command subset run across the environments below
without a privileged application install or non-core runtime modules. It does not
mean every system with a Perl binary, every terminal, or all of Vim's behavior.
The intended replacement is being built in stages; the command manual records
what the current release can do.

The implementation remains an early Vim-like subset. There is no Vimscript/plugin
compatibility, visual selection, tabs, splits, complete Unicode editing, crash
recovery or full Vim command/regex grammar. Read the embedded manual and
[Vim differences](https://github.com/oodler577/pvim/wiki/Vim-Differences).

## Verification record

The completed **v0.1.10** [CI run](https://github.com/oodler577/pvim/actions/runs/43679703152)
passed all **26 workflow jobs**, including 25 verification jobs and publication.
Later tags repeat this gate. The table records tests that ran successfully;
adding a job to a workflow alone doesn't establish support.

| Environment | Tested Perl versions | Evidence and support scope |
| --- | --- | --- |
| GitHub Linux x86-64 runner | 5.10.1, 5.16, 5.24, 5.32, 5.40, 5.42 | Core/CLI/POD suite and 22 real POSIX PTY scenarios and OS-pipe integration |
| GitHub macOS ARM64 runner | 5.10.1, 5.16, 5.24, 5.32, 5.40, 5.42 | Core/CLI/POD suite and 22 real POSIX PTY scenarios and OS-pipe integration |
| GitHub Windows x86-64 runner | 5.10.1, 5.16, 5.24, 5.32, 5.40, 5.42 | Engine, CLI, ex, batch and OS-pipe integration; native interactive UI unavailable |
| Debian bookworm slim | Distro Perl | Core suite as unprivileged nobody; separate container UI tests are not run |
| Ubuntu 24.04 container | Distro Perl | Core suite as unprivileged nobody |
| Alpine 3.22 / musl | Distro Perl | Core suite as unprivileged nobody |
| Fedora 43 | Distro Perl | Core suite as unprivileged nobody |
| Optional formatter job | Perl 5.40 + Perl::Tidy | Real formatting, key shortcut, undo and failure preservation |
| Standalone packaging job | Runner Perl | Relocation, direct execution, help, batch editing and checksums |
| App::Pvim packaging job | Runner Perl + author Dist::Zilla | Build, distribution tests, user-local install and command/module version |
| Development VM | Ubuntu 24.04.4 x86-64, Perl 5.38.2 | Core and terminal suites, standalone/CPAN packaging, nobody-user install, historical 1/3 GiB benchmarks |

The suite reports **2,719 Perl tests**; platform/build-specific skips apply.
The built CPAN distribution additionally executes the generated-module/script
checks that skip in a raw checkout. Python is used only by author/CI integration
tests, not by the installed editor.

The earliest executed Perl is **5.10.1**, not 5.10.0. Runtime syntax targets 5.10.0,
but that exact patch release has not been executed. Six representative Perl
versions are tested; this is not evidence that every intermediate patch release
or custom Perl configuration works. GitHub `*-latest` runner images may evolve;
the linked job logs retain the actual runner and interpreter details.

PTY verification compares terminal flags, speeds and control characters. Darwin's
kernel PENDIN state bit is masked when comparing restored canonical state; the
real-shell probe masks that state bit on both platforms. Darwin revokes a tty
when its session leader exits, so owned-session teardown also checks the restore
sequence. The shell pipeline test compares tty state before and after pvim while
the shell and tty remain alive. See [Apple's terminal driver](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/tty.c).

## Not yet verified

- Native Windows interactive console mode is not implemented. WSL is a plausible
  Linux route, but has not been independently exercised in this CI matrix.
- FreeBSD/OpenBSD/NetBSD, Solaris, AIX, other Unix systems and Intel macOS are
  unverified. BSD-style resize support in code is not a BSD test result.
- 32-bit builds, other CPU architectures, vintage systems and unusual terminals
  are unverified. Full standard Perl libraries and a POSIX tty/ANSI terminal are
  requirements, not optional components supplied by the standalone file.
- Text editing is byte-oriented; non-ASCII bytes are escaped for display.
- Host scratch/destination disk capacity, filesystem semantics and the workload
  still constrain large-file use. Giant individual lines and synchronous regex
  operations remain practical responsiveness limits.

Useful next portability work would be a real BSD terminal job, 32-bit Perl checks,
and an additional architecture. These are suggestions, not passed tests or
requirements blocking the currently verified platforms.

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

