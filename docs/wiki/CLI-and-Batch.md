# CLI and batch mode

```text
pvim [--no-splash] [file]
pvim --help
pvim --manual
pvim -v
pvim --version
pvim --batch -c '%s/old/new/g' -c w file.pl
```

| Option | Meaning |
| --- | --- |
| `--help`, `-h` | Short usage |
| `--manual` | Complete embedded POD, without needing perldoc |
| `-v`, `--version` | Editor and Perl versions; `-v` is an explicitly confirmed exception to Vim |
| `--no-splash` | Suppress the centered unnamed-buffer startup splash |
| `--batch` | Run ex commands without opening a terminal |
| `--command`, `-c` | Execute an ex command; repeat as needed |
| `--` | End options before a filename beginning with `-` |

One file is accepted at a time. CLI commands run before interactive mode unless
`--batch` is set or a command quits. Commands after a quitting command are not run.

Batch example with a filename containing spaces:

```sh
pvim --batch -c '%s/old/new/g' -c w 'example script.pl'
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

## Shell commands, filters and output insertion

pvim follows Vim's distinction between executing, replacing and inserting:

| Command | Effect |
| --- | --- |
| `:! command` | Run and display output; leave buffer unchanged |
| `:.! command` | Filter and replace the current line |
| `!!` then a command | Open the current-line filter prompt |
| `:2,10! command` | Replace lines 2–10 with stdout |
| `:%! command` | Replace the whole buffer with stdout |
| `:r !command` | Insert stdout below the current line |
| `:0r !command` | Insert stdout at the top |
| `:10r !command` | Insert stdout below line 10 |

Interactive bare `:!` restores the main terminal, runs the command, then waits for
Enter before returning to the buffer. Batch mode displays command output without
waiting. These commands do not implicitly save the buffer.

Filters send their selected lines to stdin. Read commands do not send the existing
buffer. Filters and reads capture stdout on temporary disk; stderr diagnostics
are bounded to 4096 bytes for status display. A failing command leaves buffer text
unchanged. Successful empty filter output deletes its range; successful empty read
output does nothing. Replacements/insertions can be undone as a single edit.

Numeric line addresses, `.`, `$`, and `%` are supported. Address offsets such as
`.+3`, marks, and the full ex range grammar are pending. `:!!` history reuse, `%`/`#`
filename expansion inside commands, `!motion`, and ordinary `:r file` are pending.
Normal-mode `2!!` prepares a filter for two lines starting at the cursor.

POSIX uses `/bin/sh -c`; native Windows batch uses COMSPEC/cmd.exe. Shell pipelines
and redirection follow that shell's rules. Commands run synchronously. Core pipe
capture cannot deadlock from full stdout/stderr pipes because captures are files;
the command itself can still hang or use significant resources. Undo reverses
buffer edits, not external filesystem changes made by the command.

Examples on POSIX:

```vim
:! ls
:.! tr '[:lower:]' '[:upper:]'
:2,10! sort
:%! perl -pe 's/old/new/g'
:r !date
```

[Vim reference: shell](https://vimhelp.org/various.txt.html#:!),
[filter](https://vimhelp.org/change.txt.html#:range!),
[read output](https://vimhelp.org/insert.txt.html#:r!).

`pvim -v` intentionally prints the version by user request. Vim uses that flag
for Vi mode; pvim retains `--version` as well. This exception does not change the
general policy of following Vim semantics unless a divergence is confirmed.

## Piped and redirected input

```sh
printf 'hi\n' | pvim
cat source.pl | pvim -
pvim < source.pl
printf 'old\n' | pvim --batch -c 's/old/new/' -c 'w result.txt' -
```

`pvim -` imports stdin, like Vim. With no filename, interactive `pvim` also detects
non-terminal stdin automatically. Vim requires explicit `-`.
The imported buffer is unnamed and modified, even for empty input. Save with
`:w filename`; `:q` protects it and `:q!` discards it. The splash is skipped.
Use `pvim ./-` to edit a file named `-`.

Input streams to private disk storage until EOF; a never-ending producer delays
startup indefinitely. Existing temporary-disk and giant-line limits apply.
Keystrokes come separately from `/dev/tty`; input text is never editor commands.
No controlling terminal or redirected stdout produces a clear error before input
is consumed. This does not implement `producer | pvim | consumer` output routing.
With a named file, stdin is not imported and interactive stdin must be a terminal.
Batch imports stdin only with explicit `-`, needs no tty, and saves only on request.
