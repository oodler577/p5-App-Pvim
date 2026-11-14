# Undo, redo and registers

| Keys or command | Effect |
| --- | --- |
| `u`, `:undo`, `:u` | Undo |
| Ctrl-R, `:redo` | Redo |
| `3u`, `3` then Ctrl-R | Undo / redo up to three units |
| `yy`, `3yy` | Yank one / three lines |
| `dd`, `3dd` | Delete lines and put them in the register |
| `yw`, `y$` | Yank with a supported same-line motion |
| `p` / `P` | Put after / before the cursor, or below / above for linewise data |

A continuous insert/replace session is an undo unit. Opening a line and typing
into it is grouped together. Arrow movement in insert commits that segment and
starts another. Substitution and perltidy each form one unit. Editing after undo
clears the redo branch. Returning to a saved state clears the dirty marker.

The register is internal to pvim; it is not the desktop clipboard. Named registers,
system clipboard integration, recording and macros are not implemented. Registers
clear when opening a different/new buffer because backing-file references belong
to that buffer. Closing the process loses all undo/register state.

Undo snapshots refer to edit pieces rather than whole file text. Metadata and
scratch disk usage still grow with edits and fragmentation. There is no history
compaction or configurable history limit yet; see [Large Files](Large-Files).
