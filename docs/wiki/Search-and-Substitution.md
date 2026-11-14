# Search and substitution

## Find text

Type `/pattern` and Enter to search forward, or `?pattern` and Enter to search
backward. Search wraps through the buffer. `n` repeats in the original direction;
`N` repeats in the opposite direction without changing what subsequent `n` means.
An empty search reuses the previous pattern. Escape cancels the prompt.

These are **Perl regexes**, not Vim regexes. `\d+`, `\bword\b`, grouping, anchors and
other supported Perl patterns follow the host interpreter's regex behavior.
Invalid regexes and missing matches produce a message rather than changing text.
A successful substitution also sets the remembered search pattern.

## Replace text

| Ex command | Scope |
| --- | --- |
| `:s/old/new/` | First match on the current line |
| `:s/old/new/g` | Every match on the current line |
| `:%s/old/new/g` | Every line in the file |
| `:2,10s/old/new/gi` | Lines 2 through 10, global and case insensitive |
| `:.,$s#old#new#g` | Current line through EOF, alternative delimiter |

Ranges accept decimal line numbers, `.`, `$`, or `%`. A reversed or out-of-bounds
range is rejected. Only `g` and `i` flags are accepted. Include the closing delimiter.

Replacement syntax:

| Form | Meaning |
| --- | --- |
| `&` | Entire match |
| `\1` through `\9` | Captured groups |
| `\t` | Tab |
| `\&` | Literal ampersand |
| `\\` | Literal backslash |
| Escaped delimiter | Literal delimiter |

For example, `:%s/(hello)/[\1]/g` changes `hello` to `[hello]`.
`:s#path/to/file#other/path#` avoids escaping `/` characters.

Replacement is never evaluated as Perl. `$1` is not capture-replacement syntax
here. Expression replacement, `e`, confirm (`c`), multiline replacements and Vim's
full ex grammar are not implemented. Substitutions work line by line, and the
whole command is one undo unit. A failed edit transaction rolls back.

Search and whole-file replacement are synchronous. Long files and pathological
regexes can pause the UI; there is no interactive progress/cancel interface for
these operations yet. See [Large Files](Large-Files).
