# CLI and batch mode

```text
perl pvim-standalone.pl [--no-splash] [--no-syntax] [file]
perl pvim-standalone.pl --help
perl pvim-standalone.pl --manual
perl pvim-standalone.pl --version
perl pvim-standalone.pl --batch -c '%s/old/new/g' -c w file.pl
```

| Option | Meaning |
| --- | --- |
| `--help`, `-h` | Short usage |
| `--manual` | Complete embedded POD, without needing perldoc |
| `--version` | Editor and Perl versions |
| `--no-splash` | Suppress unnamed-buffer startup splash |
| `--no-syntax` | Disable colors at startup |
| `--batch` | Run ex commands without opening a terminal |
| `--command`, `-c` | Execute an ex command; repeat as needed |
| `--` | End options before a filename beginning with `-` |

One file is accepted at a time. CLI commands run before interactive mode unless
`--batch` is set or a command quits. Commands after a quitting command are not run.

Batch example with a filename containing spaces:

```sh
perl pvim-standalone.pl --batch -c '%s/old/new/g' -c w 'example script.pl'
```

**Writes are explicit.** Omitting `-c w` leaves the disk file unchanged even when
commands change the in-memory buffer. This makes dry experimentation possible,
but there is no output buffer dump or automatic write at the end.

Exit statuses: success `0`, command/runtime failure `1`, option-parse failure `2`.
Messages go to stderr. Batch mode works on native Windows as well as POSIX; quoting
rules in PowerShell/CMD differ from the POSIX shell examples shown here.

Ex paths are literal and may contain spaces, but do not have shell-style expansion.
Use a full path instead of `~` in an ex filename. Do not add shell quotes inside
`:w some file.pl`; those quotes become filename characters. CLI shell quotes,
by contrast, are processed by your shell.

The same storage and command implementation powers interactive and batch modes.
This is suitable for agent-driven edits when its supported ex operations are useful.
See [Command Reference](Command-Reference) for that supported subset.
