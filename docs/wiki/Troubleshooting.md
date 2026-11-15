# Troubleshooting

| Symptom | Check or action |
| --- | --- |
| `Can't locate ... in @INC` at startup | Check that the host's complete Perl standard library is installed. A minimal binary may omit core packages. |
| Interactive mode requires a POSIX tty | Run inside a terminal on Linux/macOS/WSL, not an output-only IDE panel, downstream output pipe, or native Windows console. Piped input is supported with a controlling terminal. |
| `Permission denied` launching the file | Run `chmod +x /path/to/pvim`, then call `/path/to/pvim` directly. Check that Perl is on PATH and the filesystem permits execution. |
| `Perl::Tidy is unavailable` | Optional formatter must be installed for the same interpreter. Ordinary editing does not need it. |
| New file has no name | Save with `:w filename.pl`. |
| Quit/open refuses unsaved changes | Save, undo back to the saved state, or intentionally use `:q!`, `:e!`, `:enew!`. |
| Write says file exists or changed | Check external changes first. Use a different save path, or `:w!` only when intentional. |
| Symlink/hard-link/read-only write refused | Save to a different ordinary writable file; `!` does not bypass these protections. |
| Long pause before the screen opens | The initial streaming index/copy must finish; check file size and TMPDIR disk performance. |
| Temporary-file or disk-full error | Check scratch and destination free space/permissions. See Large Files. |
| Ctrl-Z / resume | Ctrl-Z should restore the shell tty; use shell `fg` to resume. Include your shell and terminal in a bug report if this fails. |
| Arrow keys act unexpectedly | Record the terminal type/emulator and exact input sequence; `hjkl` remain available in normal mode. |
| Resize leaves stale text | Press Ctrl-L or `L`; resizing is recognized on a subsequent keypress. |
| Search/substitution syntax surprises | Use Perl regex syntax, and `\1`/`&` in replacements. Only `g` and `i` flags are supported. |
| Non-ASCII appears as `<HH>` | Expected byte-preserving display; Unicode character editing is not implemented. |

If an abnormal termination leaves your shell without normal input/echo, type
`stty sane` and press Enter (the command may not visibly echo), then use `reset`
if the display still needs restoration. These are external shell commands, not
pvim ex commands. Never use Ctrl-C as the normal way out of the editor: in raw
mode it is an input byte. Use Escape, `:q`, Enter.

For a useful bug report, include OS, `perl -V`, terminal emulator, locale, file
size/line count/longest line, exact keys, expected and actual text, and a minimal reproducing file. Reproduce on a disposable file and attach the
smallest relevant example. Report at [Issues](https://github.com/oodler577/pvim/issues).
See [Testing](Testing) for the human checklist.

For stdin import, a producer must finish before editing begins. A missing
controlling terminal fails immediately; use `--batch ... -` for automation.
Imported buffers need `:w filename` and cannot be discarded by plain `:q`.
