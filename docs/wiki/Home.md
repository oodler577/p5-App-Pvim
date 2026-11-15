# pvim: a Perl-centric vi-style editor

Opening title: **pvim - portable vim clone**.

Current documented version: **@@VERSION@@**. This is an experimental human-testing release implementing a small vi-style subset.
Interactive support is verified on Linux/macOS; Windows supports batch/engine use.
See [Portability](Portability) for the evidence and unverified platforms.

pvim runs from one Perl file with the standard Perl library. It needs no root access,
compiler, make, curses, or required CPAN packages. Its interactive interface uses a
POSIX tty and ANSI/VT100 terminal. The command set starts with the everyday controls
in [Retrodores XVI2](https://github.com/retrodores/XVI/blob/master/readme.txt), plus
Perl-regex search/substitution, undo/redo and Perl-focused conveniences.

**Start here:** [Quick Start](Quick-Start) · [Download and Installation](Installation) ·
[Command Reference](Command-Reference) · [Perl Features](Perl-Features).

For limits and practical expectations, read [Large Files](Large-Files),
[File Safety and Encoding](File-Safety-and-Encoding), and [Vim Differences](Vim-Differences).

| Task | Page |
| --- | --- |
| Try your first editing session | [Quick Start](Quick-Start) |
| Copy the standalone file into your account | [Installation](Installation) |
| Understand normal, insert and replace modes | [Modes-and-Editing](Modes-and-Editing) |
| Move, jump and page through files | [Navigation](Navigation) |
| Look up every documented control and ex command | [Command Reference](Command-Reference) |
| Search and substitute with Perl regexes | [Search-and-Substitution](Search-and-Substitution) |
| Use Perl tools and format code | [Perl Features](Perl-Features) |
| Undo changes, copy and paste text | [Undo-and-Registers](Undo-and-Registers) |
| Run commands without a terminal | [CLI-and-Batch](CLI-and-Batch) |
| Understand disk/RAM requirements | [Large Files](Large-Files) |
| Check file-write and byte-handling behavior | [File Safety and Encoding](File-Safety-and-Encoding) |
| Resolve terminal and installation problems | [Troubleshooting](Troubleshooting) |
| See verified platforms and benchmark results | [Portability](Portability) |
| Run the suite or conduct human testing | [Testing](Testing) |
| Read the executable's full embedded manual | [Full Manual](Full-Manual) |
| Review changes and release packaging | [Releases](Releases) · [Change History](Change-History) |
| Update and publish these pages | [Documentation Maintenance](Documentation-Maintenance) |

[Repository](https://github.com/oodler577/pvim) ·
[Downloads](https://github.com/oodler577/pvim/releases) ·
[Report an issue](https://github.com/oodler577/pvim/issues)
