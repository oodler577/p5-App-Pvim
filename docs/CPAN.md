# App::Pvim distribution preparation

The distribution is **App::Pvim**, prepared for its first CPAN trial release.
Its purpose is a capable Vim replacement for restricted accounts where Perl is
available, Vim isn't, and root, gcc or make may be unavailable. The standalone
file is the option for those accounts; the CPAN tarball needs standard Perl build
tools including make, but pvim itself has no C code to compile.

The source of the editor remains the root `pvim` file. `dist.ini` loads the local
`inc::Pvim::Build` author plugin, which extracts its version and generates:

- `script/pvim`: the same complete runtime, installed as the `pvim` command.
- `lib/App/Pvim.pm`: CPAN namespace/version metadata and a command-oriented manual.

The module does not expose an editor library API. No second runtime source is
maintained, and changes to the root version automatically propagate into CPAN
metadata. Internal PVim packages and author tooling are not independently indexed.

## Author build and validation

Install Dist::Zilla using the author machine's chosen package/Perl environment.
The local plugin uses Moose and Dist::Zilla's standard roles. No additional plugin
bundle is required.

```sh
dzil build
python3 tools/cpan_audit.py App-Pvim-VERSION
dzil test
```

Build output includes `App-Pvim-VERSION.tar.gz`, `META.json`, `META.yml`, a generated
Makefile.PL, installed-script source and the metadata module. Dist::Zilla validates
the kit and metadata. Tests verify the namespace version and installed script
source against the standalone runtime. The full existing core suite also runs.

## Consumer installation without privilege

End users do not need Dist::Zilla, Moose or the local author plugin to install a
built tarball:

```sh
tar -xzf App-Pvim-VERSION.tar.gz
cd App-Pvim-VERSION
perl Makefile.PL INSTALL_BASE="$HOME/.local/pvim"
make test
make install
"$HOME/.local/pvim/bin/pvim" -v
```

At runtime the command requires Perl 5.10+ with its standard library, a POSIX
terminal for interactive editing, and writable temporary space. Perl::Tidy remains
an optional formatter. Native Windows supports batch mode; interactive use needs
a POSIX tty. Python/PTY tests and author tooling are not consumer install-time
requirements. The standalone GitHub asset still avoids the build/install step.

## Future publication checklist

1. Confirm App::Pvim namespace availability/PAUSE permissions for the releasing author.
2. Review the current feature/safety limits, Changes and release notes.
3. Pass the platform/version matrix, core and PTY suites, wiki validation, package
   generation and a real nonprivileged install test from the CPAN tarball.
4. Inspect META.json prerequisites: no accidental Dist::Zilla/Moose runtime dependency.
5. Align the root version and Git tag, and inspect final archive contents/checksums.
6. Only after explicit authorization, configure the intended PAUSE account and use
   the configured TestRelease/ConfirmRelease/UploadToCPAN release pipeline.

Normal CI and GitHub release workflows never run `dzil release` or upload to PAUSE.
The CPAN tarball is published as a GitHub asset for review and future use.

## Archive policy and POD

`GatherDir` allows the runtime, release/license files, author configuration and
source subtrees, with explicit cache/backup/build exclusions. CI seeds unwanted
root, log and bytecode files before building, then audits the actual kit against
an independent member allowlist and MANIFEST. It checks metadata, Perl licensing,
core-only runtime prerequisites, identical generated runtime and valid POD in
both executable copies and App::Pvim. Run the audit on a fresh build before
MakeMaker creates extra files. Python and Pod::Checker are author checks only.

The command POD supplies the installed `man pvim`, `--help` and `--manual`:
installation, options, full supported controls, stdin import, Perl tooling,
shell filters, large-file costs, byte-oriented encoding, save safety, unsupported
features, bug reporting, author and license. App::Pvim has a concise CPAN landing
manual pointing to the complete command manual and wiki.

Before a first PAUSE upload, verify the releasing account's App::Pvim namespace
permissions and explicitly authorize publication. No credentials or ownership
are inferred from a successful build. Broadly useful missing features (Unicode
editing, recovery, visual mode, tabs) are documented limitations rather than
packaging blockers; human terminal testing remains valuable before publishing.
