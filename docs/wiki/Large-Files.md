# Large files and responsiveness

pvim handles files larger than RAM by keeping an original snapshot and a line
index on temporary disk. Index entries use 24 bytes per line. Opening performs a
streaming O(file-size) scan and copy; it does not immediately display the first
screen while indexing. RAM does not scale with initial file size for ordinary
line lengths. Navigation uses indexed line reads and a bounded line cache.

Edits append scratch data and update a compact list of line pieces. Undo refers
to pieces rather than file-sized copies. Saving streams physical runs in bounded
chunks. Only changed terminal rows are sent on redraw, and visible-column
expansion is bounded. Engine timing excludes SSH/network/display latency.

## Disk budget

Budget approximately original file size **plus 24 bytes per line** for opening,
plus subsequent edits and undo metadata. Saving also requires enough space for a
full output file in the destination directory. Scratch and destination may be on
different filesystems. Configure a writable scratch disk before startup:

```sh
TMPDIR=/path/to/large/scratch perl pvim-standalone.pl large.log
```

## Measured behavior

A 3 GiB / 12.5-million-line generated file passed a complete round trip on the VM
with about 17.4 MiB peak RSS. Indexing took 45 seconds and saving 26 seconds.
Random jump/edit/undo p95 was 0.214 ms; screen-frame generation p95 was 0.693 ms.
These measurements use short source-like lines and a limited edit pattern.
[Portability](Portability) records exact measurements and methodology.

## Practical limits

- Use a 64-bit Perl with large-file seek support beyond 2 GiB.
- Individual lines are materialized for editing, searching and display; giant
  single-line files can consume substantial memory and slow operations.
- Search, substitution, indexing and save are synchronous and can pause the UI.
- Pathological regexes have no bounded-runtime guarantee.
- Undo metadata grows with edit count and piece fragmentation; scratch storage
  and history are not compacted before the buffer closes.
- Perltidy separately caps its whole-buffer input at 8 MiB and 200,000 lines.
- No autosave or crash recovery exists yet.

For a reproducible benchmark, see [Testing](Testing). Large-file support means
within disk, Perl and workload limits, not an unlimited-size or constant-latency promise.
