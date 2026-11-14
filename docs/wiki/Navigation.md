# Navigation and screen controls

Counts precede commands: `5j`, `20G`, `10gg`. Escape cancels a pending count.

| Keys | Movement |
| --- | --- |
| `h j k l` / arrows | Left, down, up, right |
| `0` / Home | Absolute start of line |
| `^` | First nonblank byte |
| `$` / End | Final character cell of the line |
| `w` / `b` / `e` | Next word start / previous word start / word end |
| `gg` / `G` | First / last line |
| `20gg` / `20G` / `:20` | Go to line 20 |
| `:$` | Go to the last line |
| Ctrl-F / PageDown | Page forward |
| Ctrl-B / PageUp | Page backward |
| Ctrl-D / Ctrl-U | Half-page forward / backward |
| Ctrl-L / `L` | Force a screen redraw |

Words use ASCII-style word/punctuation classes. These motions are a subset of Vim;
paragraph, sentence, marks, bracket matching and text-object motions are pending.

Long lines pan horizontally instead of wrapping. The current line-number gutter
is always visible unless disabled with `:set nonumber` (or `:set nonu`). Reenable
it with `:set number` (or `:set nu`). The gutter grows with the line count.

Terminal dimensions are read on the next keypress after a resize. Linux and
macOS/BSD-style terminal-size ioctls are implemented; other POSIX systems fall
back to `LINES`/`COLUMNS`, then 24x80. Linux and macOS have PTY tests; real BSD
interactive coverage is still pending.

Perl syntax colors are on by default. `:set nosyntax` disables them; `:set syntax`
restores them. See [Perl Features](Perl-Features).
