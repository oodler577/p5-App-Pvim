# Testing pvim

## Automated checks

`prove -v t` runs storage round trips, byte/line-ending preservation, save guards,
permission handling, 1,200 deterministic randomized splice comparisons, undo/redo,
editing commands, counts, search, substitution, prompt handling, CLI processes,
render sanitization and optional Perl::Tidy integration. Core-only tests require
no CPAN downloads. When Perl::Tidy is installed its actual formatting/failure paths
are tested; otherwise its absence is tested.

`python3 tools/pty_test.py` opens real POSIX pseudo-terminals and drives the actual
executable. It tests splash/startup, typing/save, escape decoding, arrows, opening
lines, bracketed paste (including from the ex prompt), unsaved guards, resize,
terminal-injection sanitization and terminal restoration on normal/signal exit.
Python is a test dependency only. On native Windows run the Perl suite; use WSL
or a POSIX machine for terminal tests.

`/usr/bin/time -v perl tools/benchmark.pl 1024` generates a 1 GiB source-like file,
indexes it, executes 1,000 random jump/edit/undo operations with content assertions,
saves a copy and checks SHA-256 equality. It reports indexing/save duration and
p50/p95/p99 engine latency. The external time command reports peak RSS. This is
an engine benchmark, not a claim about terminal or remote-network latency. Timing
is reported, not enforced with flaky wall-clock assertions. Temporary data cleans
up on normal exit. Budget several times the input size in free disk space.

CI runs the full Perl suite on Linux/macOS/Windows and Perl 5.10, 5.16, 5.24,
5.32, 5.40 and 5.42, PTY tests on POSIX, four minimal Linux distributions and a
separate tidy integration job. Release publishing depends on all test jobs.
Exact tested platform outcomes are recorded in PORTABILITY.md after the first run.

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
10. Check colors on comments, strings and variables; assess the documented lexer limits.
11. With Perl::Tidy installed, use `:pt`, undo it, and check diagnostics on broken Perl.
12. Open a representative large log/source file with sufficient TMPDIR space. Observe
    opening time, navigation, typing, long lines, saving and actual terminal latency.
13. Quit normally and confirm shell echo, Ctrl-C, and screen state return to normal.

Record OS, `perl -V`, terminal emulator, locale, file size/line count/longest line,
exact keys, expected/actual text, and whether reproducing with `--no-syntax` changes
behavior. Report data-loss or terminal-restoration defects before cosmetic issues.
