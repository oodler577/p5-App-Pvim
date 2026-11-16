# Testing pvim

## Automated checks

`prove -v t` runs storage round trips, byte/line-ending preservation, save guards,
permission handling, 1,200 deterministic randomized splice comparisons, undo/redo,
editing commands, counts, search, substitution, prompt handling, CLI processes,
render sanitization and optional Perl::Tidy integration. Core-only tests require
no CPAN downloads. When Perl::Tidy is installed its actual formatting/failure paths
are tested; otherwise its absence is tested.

`perl tools/pty_test.pl` opens real POSIX pseudo-terminals and drives the actual
executable. It tests splash/startup, typing/save, escape decoding, arrows, opening
lines, bracketed paste (including from the ex prompt), unsaved guards, resize,
terminal-injection sanitization and terminal restoration/newlines on normal/signal/EOF exit, kernel-verified
Ctrl-Z/external TSTP suspend/resume with unsaved state, yellow number fields,
Vim-style shell execution/filter/read behavior and UI restoration.
The PTY harness needs IO::Pty (from IO::Tty) on the author/test machine. Install
it with `cpanm IO::Pty`. It is not an editor or consumer-test dependency. On
native Windows run `prove t` and `perl tools/pipe_test.pl`; use a POSIX machine
for terminal tests. All repository test and audit scripts are Perl.

`/usr/bin/time -v perl tools/benchmark.pl 1024` generates a 1 GiB source-like file,
indexes it, executes 1,000 random jump/edit/undo operations with content assertions,
saves a copy and checks SHA-256 equality. It reports indexing/save duration and
p50/p95/p99 engine latency, plus p95 screen-frame generation latency over 500
frames written to a temporary file. The external time command reports peak RSS. This is
an engine benchmark, not a claim about terminal or remote-network latency. Timing
is reported, not enforced with flaky wall-clock assertions. Temporary data cleans
up on normal exit. Budget several times the input size in free disk space.

CI runs the full Perl suite on Linux/macOS/Windows and Perl 5.10, 5.16, 5.24,
5.32, 5.40 and 5.42, PTY tests on POSIX, four minimal Linux distributions and a
separate tidy integration job. Release publishing depends on all test jobs.
Exact tested platform outcomes are recorded in PORTABILITY.md after the first run.

## Trimmed CPAN kit

Test the actual archive from a fresh extraction with `perl Makefile.PL` and
`make test`. The author reported all seven test files and 2,725 checks passing
for the trimmed 0.1.13 kit on Perl 5.40.0. Optional Perl::Tidy tests can make
counts differ between machines. Expected CLI errors are captured and asserted
without printing diagnostics into a successful test run.

Author harnesses remain available in Git even though `tools/` and `docs/` are
excluded from the CPAN archive. Consumers run the included `t/` suite.

## Human testing checklist

Use disposable copies of real Perl sources for initial testing.

1. Launch without a filename. Check splash readability, then open a real script.
2. Navigate with counts, arrows, words, first/last line, paging and long-line panning.
3. Exercise insert/append/replace, Backspace at line boundaries, `o O`, `dd yy p P`.
4. Undo/redo insert sessions, line changes, joins and substitutions. Check cursor.
5. Search forward/backward, wrap, repeat with `n/N`, and try missing/invalid regexes.
6. Try line/range/global substitutions, groups `\1`, `&`, alternate delimiters and `gi`.
7. Save/reopen LF, CRLF, mixed-newline and no-final-newline files; compare externally.
8. Edit the source externally and check the write guard. Check `:q` vs `:q!`.
9. Paste a multiline Perl snippet; resize the terminal; use Ctrl-L to redraw.
10. Check plain Perl text display and the optional yellow line-number gutter.
11. With Perl::Tidy installed, use `:pt`, undo it, and check diagnostics on broken Perl.
12. Suspend/resume in insert and prompt modes with Ctrl-Z and `fg`; check preserved
    text and tty state. Test `:!` display, `:.!`/ranged filtering, and `:r !` insertion.
13. Open a representative large log/source file with sufficient TMPDIR space. Observe
    opening time, navigation, typing, long lines, saving and actual terminal latency.
14. Quit normally and confirm shell echo, Ctrl-C, and screen state return to normal.

Record OS, `perl -V`, terminal emulator, locale, file size/line count/longest line,
exact keys, expected/actual text, and a minimal reproducing sample. Report data-loss or terminal-restoration defects before cosmetic issues.


Stdin import tests cover byte/line-ending round trips, empty-input protection,
explicit batch editing, command-looking input as data, no-terminal failures and
streaming CRLF boundaries. POSIX PTYs attach a controlling terminal separately
from piped stdin, test automatic and explicit imports, and check terminal restore.
The CPAN CI job also seeds stray files and runs `tools/cpan_audit.pl` on the fresh
build to verify file gathering, metadata and executable/module POD.

`tools/pipe_test.pl` uses a real stdin pipe with file-backed stdout/stderr capture and an alarm deadline on Linux, macOS
and native Windows. The Perl suite separately tests redirected stdin with actual
standard descriptors, avoiding IPC::Open3's native-Windows EOF hang. CI gives the
core/pipe step five minutes and cancels superseded runs of the same git ref.

PTY waits drain screen output while polling process exit. Darwin revokes a tty
when its session leader exits, so those synthetic sessions cannot inspect the
revoked slave afterward. The real-shell pipeline test compares full tty state
before launch and after pvim exits, while the shell and terminal remain alive;
the kernel PENDIN state bit is masked for that probe. Ordinary PTY sessions retain
exact before/after checks with the same existing PENDIN exception.
