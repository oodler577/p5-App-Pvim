# Modes and editing

pvim starts in **normal mode**, with line numbers off. Most normal-mode keys are commands rather than
text. The status line names the mode and shows the filename, dirty marker `[+]`,
cursor byte position and line count. Escape exits insert/replace, cancels an ex
prompt, or clears a pending operator/count.

| Command | Effect |
| --- | --- |
| `i` / `a` | Insert before / after the cursor |
| `I` / `A` | Insert at first nonblank / end of line |
| `o` / `O` | Open a blank line below / above, then insert |
| `R` | Enter overwrite mode |
| `rX`, `3rX` | Replace one / three existing characters with `X` |
| `x`, `3x`, Delete | Delete character(s) at the cursor |
| `dd`, `3dd` | Delete one / three lines |
| `cc`, `3cc` | Replace one / three lines with a blank insert line |
| `D` / `C` | Delete / change through the end of the current line |
| `J`, `3J` | Join with the next line / join three lines total |

Insert accepts printable bytes, Tab, newline, Backspace and arrows. At the start
of a line, insert-mode Backspace joins it to the previous line. Replace-mode
Backspace moves left without restoring overwritten characters. Arrow movement
inside insert commits that undo segment and starts another.

## Operators

`d`, `c` and `y` combine with the supported **same-line** motions `w e b h l 0 $`.
Repeating an operator acts on lines (`dd`, `cc`, `yy`). Operator and motion counts
multiply: `2d3d` deletes up to six lines.

Examples: `dw` deletes through the next word start; `de` deletes through a word's
end; `d$` deletes to line end; `y0` copies back to the start. `cw` starting on a
nonblank word leaves trailing whitespace. General cross-line operators, text
objects, indent operators and arbitrary Vim operator combinations are not present.

Bracketed paste enters insert mode and treats printable text, tabs and newlines
as text. Other control sequences are discarded. Avoid pasting raw binary content.

Ctrl-Z suspends from normal, insert, replace, prompt or splash mode; `fg` restores
the same editing state and redraws. All handled interactive exits emit a newline
after returning to the main terminal screen.

See [Undo and Registers](Undo-and-Registers), [Navigation](Navigation), and the
complete [Command Reference](Command-Reference).
