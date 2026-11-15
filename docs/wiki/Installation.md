# Download and installation

## Requirements

- Full Perl **5.10+**, including its standard modules (POSIX, Digest::SHA,
  File::Temp, Getopt::Long, Pod::Usage and the other bundled libraries).
- A POSIX tty and ANSI/VT100 terminal for interactive editing.
- Writable temporary disk space; see [Large Files](Large-Files).
- Optional `Perl::Tidy`, for formatting only.

No privileged installation is required. Minimal OS packages sometimes split the
standard Perl library into separate packages. A stripped-down Perl binary alone
is insufficient; this is distinct from needing CPAN dependencies for pvim.

## Standalone file

[pvim-standalone.pl](https://github.com/oodler577/pvim/releases/download/v@@VERSION@@/pvim-standalone.pl)
is the complete editor, including its POD and CLI help. It has the same bytes as
the `pvim` download. All pvim packages are already embedded in that file, so no
additional fat-packing step or extraction is required. It uses the host's core
Perl library; it does not embed a Perl interpreter or the optional formatter.

```sh
mkdir -p "$HOME/.local/bin"
curl -fL https://github.com/oodler577/pvim/releases/download/v@@VERSION@@/pvim-standalone.pl -o "$HOME/.local/bin/pvim"
chmod +x "$HOME/.local/bin/pvim"
"$HOME/.local/bin/pvim" -v
"$HOME/.local/bin/pvim" file.pl
```

If `~/.local/bin` is in your PATH, run `pvim file.pl`. Otherwise use its full path,
or add that directory to your shell's PATH configuration. The executable selects
the Perl interpreter on PATH through its shebang.

## Check downloads

Download `SHA256SUMS` alongside the exact release asset, then compare its entry:

```sh
curl -fLO https://github.com/oodler577/pvim/releases/download/v@@VERSION@@/SHA256SUMS
sha256sum "$HOME/.local/bin/pvim"
```

For a full release directory containing all listed assets, `sha256sum -c SHA256SUMS`
checks every entry. macOS also provides `shasum -a 256`. Checksums detect a mismatch;
they are not a separate cryptographic signature.

## Upgrade and remove

To upgrade, quit pvim, download the desired release, verify it, and replace your
user-owned installed file. There is no package database or installed module tree.
To uninstall the example installation: `rm "$HOME/.local/bin/pvim"`.

## Git checkout

```sh
git clone git@github.com:oodler577/pvim.git
cd pvim
git checkout master
./pvim file.pl
```

See [Perl Features](Perl-Features) for the optional formatter and
[Portability](Portability) for actual test coverage.

## CPAN-format tarball (future App::Pvim)

App::Pvim is prepared for future CPAN publication, but has not been uploaded by
this work. To install the GitHub release's CPAN-format tarball into your account:

```sh
tar -xzf App-Pvim-@@VERSION@@.tar.gz
cd App-Pvim-@@VERSION@@
perl Makefile.PL INSTALL_BASE="$HOME/.local/pvim"
make test
make install
"$HOME/.local/pvim/bin/pvim" -v
```

This needs make and standard Perl build tools. It requires no root and no
Dist::Zilla on the consuming machine. The standalone download remains the option
when you want to avoid a build/install step entirely. See [Releases](Releases).
