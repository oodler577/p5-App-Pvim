# pvim: Vim-style editing where Perl is available

pvim is for accounts where Perl is there and Vim isn't. No install privileges,
possibly no gcc or make, but still files to edit. Cheap shared web hosting and
minimal Unix installs are exactly the sort of places I have in mind.

The goal is a **highly capable, Perl-centric Vim replacement for restricted
environments**, in one Perl file using core modules and Perl 5.10+. Copy the
standalone file into your account, make it executable, and use it. No root,
compiler, build step or CPAN module installation needed.

Current documented version: **@@VERSION@@**. The editing modes, familiar motions,
search/substitution, undo/redo, shell filters and optional perltidy are here.
Large files use temporary disk storage. Visual selection, tabs, splits,
dot-repeat, Vimscript, plugins and crash recovery aren't implemented yet;
editing is byte oriented. The [full manual](Full-Manual) covers what's available.

You need a full Perl standard library, writable temporary space, a POSIX terminal
and permission to run your own scripts. Interactive testing covers Linux and
macOS; native Windows supports batch and engine use. See [Portability](Portability)
for the test record. The opening title remains **pvim - portable vim clone**.

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
