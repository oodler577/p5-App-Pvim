pvim 0.1.10 adds stdin import:

```sh
printf 'hi\n' | pvim
cat source.pl | pvim -
printf 'old\n' | pvim --batch -c 's/old/new/' -c 'w result.txt' -
```

Interactive input streams to the disk-backed store, opens unnamed and unsaved,
and skips the splash. Keystrokes come from the controlling terminal. Save with
`:w filename`; `:q` protects even an empty import. No controlling terminal or
redirected screen output fails clearly. Input is read until EOF, so an endless
producer prevents editing from starting. Automatic no-filename detection is a
confirmed exception to Vim's explicit `-`; batch still requires explicit `-`.

CPAN preparation now restricts gathered files and audits the built manifest,
metadata and POD. The maintained runtime remains one file with core-only
requirements. No upload to CPAN/PAUSE is performed.

This remains an experimental human-testing release: limited vi-style controls,
byte-oriented editing, no swap/recovery, visual selection, tabs or syntax
highlighting. Interactive support is tested on Linux/macOS; native Windows is
batch/engine-only. Other Unix systems, 32-bit and vintage systems are unverified.
