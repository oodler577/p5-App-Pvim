pvim 0.1.12 replaces the four Python test/audit scripts with Perl equivalents:

- `tools/pty_test.pl`: the same 22 real-terminal scenarios, including suspend/fg,
  stdin import, shell commands, colors, paste, resizing and terminal restoration.
- `tools/pipe_test.pl`: real stdin pipes on Linux, macOS and native Windows,
  with binary/line-ending round trips, batch editing and unsaved-input guards.
- `tools/wiki_test.pl`: idempotent generation, stale-page cleanup, bad-link
  rejection, and guarded publication against a local Git remote.
- `tools/cpan_audit.pl`: archive allowlist, complete MANIFEST, metadata, core-only
  runtime prerequisites, valid POD and identical generated executable checks.

CI and documentation use the Perl tools. IO::Pty is needed only for POSIX author
terminal tests; the editor and consumer test suite keep their core-only runtime
requirements. The audit uses JSON::PP and Pod::Checker on the author machine.
There are no Python scripts or Python dependencies left in the repository.

Editing behavior is unchanged. This remains an early Vim replacement for
restricted accounts where Perl is available. No upload to PAUSE is performed.
