# pvim project instructions

- Default to Vim's behavior and command semantics. If a user request appears
  to diverge from Vim, explain the difference and ask for confirmation before
  implementing the divergence. Do not silently invent an alternative default.
- Preserve the single-file runtime and Perl 5.10+ compatibility. Keep `master` as
  the main branch. Tabs and visual selection remain deferred until requested.
- When behavior changes, update embedded POD, relevant `docs/wiki/*.md` sources,
  tests and release notes together. Never leave new CLI options or commands
  documented only in chat. Run `perl tools/wiki.pl --check`.
- Wiki pages are generated from source templates plus current POD, Changes,
  TESTING.md and PORTABILITY.md. Use `tools/publish-wiki.sh` with the clean SSH
  checkout at `/root/projects/pvim-work/pvim-wiki` when on the development VM.
  Do not edit generated wiki pages as the permanent source of a change.
- The VM also publishes from master hourly using a separate checkout. Preserve
  this job's clean-worktree and fast-forward-only guards; do not export its keys.
- Releases must include `pvim-standalone.pl`, the identical `pvim` alias, source
  archive and SHA256SUMS. `tools/release.pl` builds them. No FatPacker dependency
  is needed while the runtime has no non-core dependencies.
- Run checks appropriate to a change. Runtime changes require the core suite and
  POSIX PTY integration; packaging changes require relocated standalone checks.

- Prepare CPAN releases as App::Pvim with dist.ini. The local author plugin
  generates script/pvim and lib/App/Pvim.pm from the one maintained pvim source;
  do not introduce a second manually edited runtime copy or independent version.
- Run dzil build/test and verify a nonprivileged INSTALL_BASE install for packaging
  changes. Author dependencies are not runtime dependencies. Never run dzil release
  or upload to PAUSE without explicit authorization to publish to CPAN.

- Syntax highlighting is deferred by user request. Keep file text plain and do not
  reintroduce a lexer or make highlighting a release requirement unless requested.
  The yellow number gutter and status styling are intentional terminal UI features.

- Confirmed Vim exception: `pvim -v` prints the version, alongside `--version`.
- Show pvim as an executable utility in all user-facing examples (`pvim`,
  `./pvim` or its installed full path), without a `perl` command prefix. Standalone
  instructions must include chmod and PATH/full-path guidance. Internal tests and
  build probes may invoke explicit interpreters to validate portability.
