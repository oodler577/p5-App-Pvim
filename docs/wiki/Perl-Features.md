# Perl-focused features and current limits

## What exists now

| Feature | Current implementation | Limits |
| --- | --- | --- |
| Perl syntax colors | Common keywords, scalar/array/hash variables, simple strings, comments, decimal numbers | Approximate single-line lexer; not a complete Perl parser |
| Perltidy | `\t` (backslash then t), `:pt`, `:perltidy` | Optional Perl::Tidy for the same interpreter; whole-buffer, 8 MiB / 200,000-line cap |
| Search/substitution | Host Perl regex engine; captures, `&`, `g` and `i` | Not Vim regex syntax; line-oriented replacement; no evaluated replacement |
| External Perl tools | `:! command` displays results; `:.!`, ranged `!`, `%!` filter text | Tools must already be installed; explicit shell commands can have external effects |
| Command output insertion | `:r !command`, `:0r !command` | Command gets no buffer input; output is inserted as lines |
| Automation | `--batch` and repeatable `-c` ex commands | Supported ex subset; writes are explicit |

There is no PPI/tree-sitter parser, language server, automatic completion,
buffer-aware compiler checker, debugger, test-results panel or project navigation
yet. Optional external tools can be invoked, but that is distinct from an integrated
Perl IDE. The runtime still requires only the full standard Perl library.

## Syntax highlighting

Colors are enabled by default; line numbers are independently **off** by default.

| Text | ANSI terminal color |
| --- | --- |
| Recognized keywords | Cyan |
| Variables | Yellow |
| Complete simple single/double-quoted strings | Green |
| Comments | Gray |
| Decimal numbers | Magenta |
| Enabled line numbers | Yellow |

`:set syntax` / `:set nosyntax` toggle text colors. `--no-syntax` starts without
text colors. These do not disable the yellow gutter enabled by `:set number`.
The terminal's palette determines the exact appearance; custom themes/color
configuration and true-color styling are not implemented.

The lexer does not fully handle heredocs, multiline quotes, `q/qq/qw` quoting,
POD, regex literals, embedded languages or all Perl context-sensitive syntax.
Horizontal clipping can also lose lexical context. Improving multiline state
and quote recognition is a useful next step, but is not already implemented.

## Perltidy

Type backslash followed by `t` in normal mode, or use `:pt` / `:perltidy`.
The built-in integration loads `Perl::Tidy` from the same Perl interpreter as pvim.
Merely having a perltidy executable for a different interpreter does not enable
`:pt`. Ordinary editing works without the formatter.

Optional user-local installation with an existing cpanminus:

```sh
cpanm --local-lib "$HOME/perl5" Perl::Tidy
PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}" perl pvim-standalone.pl file.pl
```

Formatting uses `-npro -l=500`, ignores perltidy profiles, forms one undo unit,
and never saves automatically. Failure leaves the buffer unchanged. The built-in
integration caps whole-buffer input at 8 MiB and 200,000 lines.

An installed executable can instead be called explicitly as a whole-file filter:

```vim
:%! perltidy -st -npro -l=500
```

This uses the executable on PATH, which may belong to another Perl. Its stdout
replaces the whole buffer; its own memory requirements apply. Use `u` to undo.

## Syntax checks and tests through the shell

For example, save the file and run a check:

```vim
:w
:! perl -c path/to/saved-file.pl
```

Output appears on the terminal; press Enter to return. The command checks the
saved file, not unsaved buffer text. Spell the path explicitly: Vim-style `%`
filename expansion inside commands is not implemented yet.

`:! prove -l t` can run a project's tests from the directory where pvim was
launched. Ctrl-Z also suspends to the shell; `fg` resumes with the same buffer.
Neither mechanism yet supplies clickable diagnostics or automatic error navigation.

Do **not** run `:%! perl -c`: a successful compiler check normally emits no source
on stdout, so a filter would delete its input range. Use bare `:!` for execution.
See [Shell Commands and Filters](CLI-and-Batch) for all three command forms.

## Visual highlighting

Vim-style visual selection is **not implemented**: no `v`, `V`, blockwise Ctrl-V,
selection highlight or selection operators. ANSI colors and the reverse-video
status line provide display primitives; a real selection still needs an anchor,
range tracking and copy/delete/change behavior.

Linewise `V` is the smallest useful first stage because line yank/delete and
ranged filters already exist. Characterwise `v` would follow; blockwise selection
is a larger task. These are proposed stages, not enabled features. See
[Vim Differences](Vim-Differences) for the advanced-beginner feature shortlist.
