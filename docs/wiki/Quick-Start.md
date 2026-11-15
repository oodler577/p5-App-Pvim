# Your first pvim session

On a Linux system with a full Perl 5.10+ installation, including Debian with Perl
5.40, open a shell inside your usual terminal emulator. macOS and WSL also provide
suitable POSIX environments. Native Windows interactive mode is pending.

If you have no install privileges or build tools, use the standalone file:

```sh
curl -fL https://github.com/oodler577/pvim/releases/download/v@@VERSION@@/pvim-standalone.pl -o pvim
chmod +x pvim
./pvim -v
./pvim practice.pl
```

If curl is unavailable, download [pvim-standalone.pl](https://github.com/oodler577/pvim/releases/download/v@@VERSION@@/pvim-standalone.pl)
on another machine and transfer it to the account. Save it as `pvim` and make it
executable. Put it in a directory on PATH to call `pvim` from anywhere.
The `pvim` release asset contains the same bytes.

If you have cpanm and the usual Perl build tools, including make, you can install
the CPAN-format tarball instead. pvim itself has no C code to compile:

```sh
cpanm https://github.com/oodler577/pvim/releases/download/v@@VERSION@@/App-Pvim-@@VERSION@@.tar.gz
pvim -v
pvim practice.pl
```

1. Press `i` to enter insert mode.
2. Type `use strict;`, press Enter, and type `print "hello\n";`.
3. Press Escape to return to normal mode.
4. Type `:w` and press Enter to save `practice.pl`.
5. Type `:q` and press Enter to quit.
6. Back in the shell, run `perl practice.pl`.

To start without a filename, use `pvim` (or `./pvim` in the download directory). The splash, titled “pvim - portable vim clone”,
appears with “Support Us at PerlCommunity.org”, centered horizontally and vertically; press any key to dismiss it. That key is consumed by the splash. Press `i`
again to begin inserting. Save an unnamed buffer using `:w practice.pl`.

Useful first experiments:

| Keys | Effect |
| --- | --- |
| `h j k l` or arrows | Move in normal mode |
| `gg`, `G`, `10G` | First line, last line, line 10 |
| `dd`, then `u` | Delete a line, then undo |
| `yy`, then `p` | Copy a line, then put it below |
| `/hello` then Enter | Find the next matching text |
| `:%s/hello/world/g` then Enter | Replace throughout the file |
| `:q!` then Enter | Discard unsaved changes and quit |

There is no autosave or crash recovery yet. Use a disposable copy when evaluating
the first release. The [full manual](Full-Manual) and `--help` / `--manual` work offline.
