pvim 0.1.1 includes a fix and four regression tests for repeating zero-width
line-end searches. It supersedes the initial 0.1.0 human-testing prerelease.

First **human-testing prerelease** of pvim, a Perl-centric vi-style editor in one
Perl file, targeting Perl 5.10 and newer. Not a full Vim implementation.

Download **pvim** for the standalone executable and run `perl pvim file.pl`.
No CPAN dependencies are required on a complete Perl installation. The source
archive adds documentation; SHA256SUMS covers both downloads.

Includes modal editing, counts, navigation/paging, line numbers, yank/put, undo/redo,
Perl-regex search and ranged substitutions, approximate Perl highlighting,
optional `:pt` formatting, batch automation, a provisional splash, and disk-backed
large-file storage. See `perl pvim --manual` for complete controls and limitations.

Interactive support is POSIX/ANSI; native Windows is batch/engine-only. Tabs,
visual selection, full Perl parsing, Unicode character editing and crash recovery
are future work. Individual lines are still materialized; search/save are synchronous.

Start with copies of your files and follow `docs/TESTING.md`. Splash community /
donation copy is provisional and will be supplied later.

Validation: 24 passing CI jobs cover six Perl versions on three OS families,
four minimal Linux distributions, optional formatting and standalone packaging.
The core suite has 2,653 assertions plus eight POSIX terminal scenarios. A 3 GiB /
12.5-million-line VM round trip passed with 17.38 MiB peak RSS; p95 random
jump/edit/undo was 0.214 ms and frame generation 0.693 ms (network/display excluded).
See `docs/PORTABILITY.md` for exact measurements and practical limitations.
