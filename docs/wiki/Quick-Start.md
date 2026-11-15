# Your first pvim session

On a Linux system with a full Perl 5.10+ installation, including Debian with Perl
5.40, open a shell inside your usual terminal emulator. macOS and WSL also provide
suitable POSIX environments. Native Windows interactive mode is pending.

Install the release with cpanm, then use the command directly:

```sh
cpanm https://github.com/oodler577/pvim/releases/download/v@@VERSION@@/App-Pvim-@@VERSION@@.tar.gz
pvim -v
pvim practice.pl
```

For the standalone route, no build/install step is needed:

```sh
curl -fL https://github.com/oodler577/pvim/releases/download/v@@VERSION@@/pvim-standalone.pl -o pvim
chmod +x pvim
./pvim -v
./pvim practice.pl
```

If curl is unavailable, download [pvim-standalone.pl](https://github.com/oodler577/pvim/releases/download/v@@VERSION@@/pvim-standalone.pl)
in a browser, save it as `pvim`, make it executable, and run `./pvim practice.pl`.
Put it in a directory on PATH to invoke it as `pvim` from anywhere. The `pvim`
release asset contains the same executable bytes.

1. Press `i` to enter insert mode.
2. Type `use strict;`, press Enter, and type `print "hello\n";`.
3. Press Escape to return to normal mode.
4. Type `:w` and press Enter to save `practice.pl`.
5. Type `:q` and press Enter to quit.
6. Back in the shell, run `perl practice.pl`.

To start without a filename, use `pvim` (or `./pvim` in the download directory). The provisional splash
appears, centered horizontally and vertically; press any key to dismiss it. That key is consumed by the splash. Press `i`
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
