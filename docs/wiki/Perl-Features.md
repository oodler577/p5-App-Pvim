# Perl-focused features

## Syntax colors

Perl colors are enabled by default. The bounded single-line lexer recognizes
common keywords, variables, simple quoted strings, comments and decimal numbers.
It is approximate: heredocs, multiline quoting, POD, regex literals and embedded
languages are not fully parsed. Horizontal clipping can also lose lexical context.

- `:set syntax` enables colors.
- `:set nosyntax` disables colors.
- `--no-syntax` starts without colors.

The display escapes file-provided control/non-ASCII bytes rather than sending
them directly to the terminal. See [File Safety and Encoding](File-Safety-and-Encoding).

## Perltidy

Type **backslash followed by `t`** in normal mode (`\t`), or use `:pt` / `:perltidy`.
This requires `Perl::Tidy` to be installed for the **same Perl interpreter** that
runs pvim. Merely having a `perltidy` executable for a different Perl is insufficient.

Optional user-local installation with an existing cpanminus:

```sh
cpanm --local-lib "$HOME/perl5" Perl::Tidy
PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}" perl pvim-standalone.pl file.pl
```

Use the formatter only if you want it; ordinary editing works without it. pvim
reports a clear message if the module is unavailable. It never runs a shell.

Formatting uses `-npro -l=500`: project/user perltidy profiles are ignored. It acts
on the whole buffer, is undoable, and does **not** save automatically. An invalid
source or formatter failure leaves the buffer unchanged. Formatting is capped at
8 MiB and 200,000 lines because the formatter materializes the whole source.

## Automation

[Batch mode](CLI-and-Batch) exposes the same ex engine for command-line scripting
and agent use. It supports explicit writes and nonzero error status without a tty.
No Perl execution, shell escape, REPL, language server, completion or debugger is
embedded in this first release.
