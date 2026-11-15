# Vim and XVI2 differences

The goal is a highly capable Vim replacement for restricted accounts where
Perl is available. The current release covers the basics; this page records
what differs from Vim and what still needs implementing.
[Portability](Portability) separates verified interactive, batch-only and untested platforms.
Supported controls are fully listed in [Command Reference](Command-Reference).

| Area | Current behavior |
| --- | --- |
| Version flag | `pvim -v` prints the version; Vim uses that flag for Vi mode |
| Files | One active buffer; tabs and splits deferred |
| Selection | No visual selection yet |
| Operators | Repeated line operators and a limited same-line motion set |
| Regex | Perl syntax rather than Vim syntax |
| Substitution | `g`/`i`, captures and whole match; no expression or confirm flags |
| Text | Byte-oriented, escaped non-ASCII display; no Unicode grapheme editing |
| Registers | One internal register, cleared on buffer switches |
| Repeat/macros | No dot-repeat, macro recording, named registers or mappings |
| Indentation | No automatic indent, shift operators or text objects |
| Perl colors | Syntax highlighting deferred; file text is plain |
| Formatting | Optional whole-buffer Perl::Tidy using `-npro -l=500` |
| Configuration | CLI/ex toggles; no vimrc or persistent configuration file |
| Shell integration | `:!` execution, ranged filters, `!!`, and `:r !` output insertion; no filename/history expansion yet |
| Recovery | No swap recovery, crash journal or autosave |
| Windows | Native batch/engine support; interactive mode needs POSIX/WSL |

Compared with the referenced XVI2 quick help: pvim uses `gg` rather than a lone
`g` for the top of the file; `^` is first nonblank and `0` is absolute line start.
`:e` without a filename reloads the current path; use `:enew` for an unnamed buffer.
The splash consumes a dismissal key before normal editing begins.

Tabs and visual selection are deferred plans, not promises of current behavior.
The centered splash includes “Support Us at PerlCommunity.org”. Human feedback will determine the next stage.

## Behavior policy

Vim is the default behavior standard for implemented features. If a proposed
request differs from Vim, maintainers should explain that difference and obtain
confirmation before introducing it. Missing features below are not alternative
semantics or promises that every Vim command already works. Perl regex syntax
and the explicitly requested Perl-centric integrations remain documented choices.

## Useful advanced-beginner additions

These are missing features worth considering next, ordered roughly by effort and
reuse of current code. Effort is a design estimate, not a release commitment.

| Feature | Why useful | Relative effort |
| --- | --- | --- |
| `f F t T`, `; ,` | Jump to a character on the current line and repeat | Small |
| `W B E` | Move by whitespace-delimited words | Small |
| `*` / `#` | Search for the word under the cursor | Small |
| `>>` / `<<` | Indent/unindent lines with counts | Small to moderate |
| `autoindent`, `tabstop`, `shiftwidth`, `expandtab` | Practical code editing with consistent whitespace | Small to moderate |
| Insert-mode Ctrl-W / Ctrl-U | Erase a word or inserted line text quickly | Small |
| Marks `ma`, `'a`, backtick-a | Return to saved positions | Small to moderate; marks must track edits |
| `:r file`, `:w !command` | Insert files and send text to tools without replacing it | Small to moderate |
| Basic `%` bracket matching | Jump among matching delimiters | Small initially; Perl-aware quote/comment handling takes more work |
| Linewise visual `V` | Highlight lines, then yank/delete/filter them | Moderate; best first visual stage |
| Characterwise visual `v` | Select text across line boundaries | Moderate; needs multi-line character ranges |
| Dot-repeat `.` | Repeat the last edit | Moderate; record/replay insert sessions and counts correctly |
| Search-match highlighting | Make results visible while navigating | Moderate; compose with future selection colors |
| Substitute confirmation `:s/.../.../gc` | Review replacements individually | Moderate; interactive decisions and coherent undo |

I would prioritize character-find motions, indentation/options, word-under-cursor
search, and then linewise visual selection. Dot-repeat is highly useful, but is
not merely replaying the last key and deserves its own tests.

Tabs, window splits, blockwise visual selection, comprehensive Perl parsing,
Unicode grapheme editing and language-server integration are larger projects and
are not included in the small-feature shortlist.

Interactive `producer | pvim` automatically imports stdin when no filename is
provided. Vim requires explicit `vim -`.
`pvim -` is also supported. Imports are unnamed and modified; use `:w filename`.
Keystrokes use `/dev/tty`; stdout must remain a terminal. Batch requires explicit `-`.
