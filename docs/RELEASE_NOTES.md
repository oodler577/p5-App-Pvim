pvim 0.1.4 adds **App::Pvim** CPAN preparation while retaining the single-file runtime.

- `dist.ini` and a local author plugin build the installed command and CPAN module
  from the one pvim source/version. No separate runtime implementation is maintained.
- CI builds/tests the App-Pvim tarball and checks installation into a user-owned
  prefix. Dist::Zilla is author tooling, not a runtime or end-user requirement.
- The GitHub release includes `App-Pvim-0.1.4.tar.gz` with checksums alongside the
  identical `pvim` / `pvim-standalone.pl` executables and ordinary source archive.
- **No upload to CPAN/PAUSE has been performed.** Publication is deferred until
  explicitly authorized and namespace permissions are confirmed.

All v0.1.3 terminal, gutter, Vim-style shell execution/filter/read changes are
included. See the wiki for current Perl highlighting/tooling and the prioritized
advanced-beginner feature shortlist. Visual selection and tabs remain deferred.

pvim 0.1.3 addresses initial terminal feedback and adds Vim-style shell tools.

- Ctrl-Z / external SIGTSTP restore the tty, suspend, and resume with `fg` without
  losing unsaved text or editing mode. Handled interactive exits emit a newline.
- Line numbers are off by default. `:set number` enables a yellow three-column
  number field plus separator, widening for four or more digits.
- `:! command` displays output without editing. `:.!`, `!!`, `:2,10!` and `:%!`
  filter text. `:r !command` / `:0r !command` insert output below the cursor / at
  the top. Buffer edits are undoable and failed captures preserve buffer text.
- Wiki pages describe current Perl colors/tooling, visual-selection limitations,
  and useful next Vim features. Vim behavior is the default for future work;
  departures require explicit confirmation.

Download **pvim-standalone.pl** and run `perl pvim-standalone.pl file.pl`.
This remains a human-testing prerelease. Native Windows interactive mode,
visual selection, tabs and comprehensive Perl parsing are not yet implemented.

pvim 0.1.2 adds the clearly named **pvim-standalone.pl** download and comprehensive
[wiki documentation](https://github.com/oodler577/pvim/wiki).

Download that one file and run `perl pvim-standalone.pl practice.pl` on Linux,
macOS or WSL. It already contains all pvim code and POD; no non-core modules or
separate fat-packing step are required. The `pvim` alias has identical bytes.
Standard Perl core libraries are required; Perl::Tidy remains optional.

The wiki includes a first-session guide, command reference, search/substitution,
Perl formatting/colors, CLI/batch, large files, safety, troubleshooting, portability,
testing and maintenance. Pages are generated/validated from source and published
from master. This remains a human-testing prerelease; tabs and visual selection
are deferred. Native Windows supports batch/engine use only.

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
