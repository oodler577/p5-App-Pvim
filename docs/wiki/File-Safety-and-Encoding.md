# File safety and encoding

## Saving and external changes

`:w` writes through a temporary file in the destination directory and then renames
it into place. Normal write errors leave the previous destination intact. Ordinary
mode bits are preserved. SHA-256 detects changed external contents before a save;
`:w!` can intentionally replace an existing/changed file.

Symlink, hard-linked and read-only destinations are refused, including with `!`.
This prevents silently breaking link semantics or replacing a read-only file.
External-change detection is a guard, not an atomic lock or compare-and-swap.
Avoid simultaneous editing of the same path by different writers.

Ownership, ACLs, xattrs and sparse layout are not preserved or guaranteed. There
is no fsync/power-failure durability guarantee, writer locking, swap recovery,
autosave or crash journal. Unsaved changes can be lost on a crash or terminal loss.

## Bytes and newlines

The editor is byte-oriented. Printable ASCII and tabs display normally; other
bytes display as `<HH>` escapes. Their underlying bytes are preserved. Cursor
columns are byte positions, not Unicode grapheme positions. Do not expect UTF-8
character-wise movement/deletion or locale-aware display-width handling.

Untouched LF, CRLF, mixed line endings and missing-final-newline state survive
round trips. New lines use the first observed newline style. A new file uses LF
and a final newline. Existing line terminators are kept for edited line records
where applicable; structural changes introduce the buffer's newline style.

File bytes, filenames and messages are sanitized before terminal output to prevent
file-provided terminal controls from executing. Bracketed paste treats printable
text, tabs and newlines as data and discards other controls.

## Quitting

`:q` refuses unsaved changes. `:q!` discards them. The same guard applies to `:e`
and `:enew`, with `!` variants available for intentional discard. Terminal settings
are restored on normal exit and handled signal/error paths. SIGKILL and power
failure cannot be handled. See [Troubleshooting](Troubleshooting) if a terminal
is left in an unexpected state.
