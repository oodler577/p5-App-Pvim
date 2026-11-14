# Vim and XVI2 differences

pvim is a small vi-style editor, not a compatible implementation of Vim.
Supported controls are fully listed in [Command Reference](Command-Reference).

| Area | Current behavior |
| --- | --- |
| Files | One active buffer; tabs and splits deferred |
| Selection | No visual selection yet |
| Operators | Repeated line operators and a limited same-line motion set |
| Regex | Perl syntax rather than Vim syntax |
| Substitution | `g`/`i`, captures and whole match; no expression or confirm flags |
| Text | Byte-oriented, escaped non-ASCII display; no Unicode grapheme editing |
| Registers | One internal register, cleared on buffer switches |
| Repeat/macros | No dot-repeat, macro recording, named registers or mappings |
| Indentation | No automatic indent, shift operators or text objects |
| Perl colors | Approximate single-line lexer, not a complete Perl parser |
| Formatting | Optional whole-buffer Perl::Tidy using `-npro -l=500` |
| Configuration | CLI/ex toggles; no vimrc or persistent configuration file |
| Shell integration | No shell escapes or command execution |
| Recovery | No swap recovery, crash journal or autosave |
| Windows | Native batch/engine support; interactive mode needs POSIX/WSL |

Compared with the referenced XVI2 quick help: pvim uses `gg` rather than a lone
`g` for the top of the file; `^` is first nonblank and `0` is absolute line start.
`:e` without a filename reloads the current path; use `:enew` for an unnamed buffer.
The splash consumes a dismissal key before normal editing begins.

Tabs, visual selection and community/donation splash copy are deferred plans,
not promises of current behavior. Human feedback will determine the next stage.
