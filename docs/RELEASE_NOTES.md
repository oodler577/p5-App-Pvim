pvim 0.1.11 is the documentation pass for the first App::Pvim trial release.

pvim is for accounts where Perl is there and Vim isn't: restricted or cheap
shared web hosting, minimal Unix installs, and other systems where you can't
install packages and may not have gcc or make. The goal is a highly capable,
Perl-centric Vim replacement you can copy into your own account and use.

The POD, App::Pvim description, README and wiki now lead with that purpose.
Standalone installation comes first: one file, Perl 5.10+ and core modules,
no root, compiler or build step. The docs distinguish those runtime requirements
from installing the CPAN tarball, which still needs standard Perl build tools
including make. The installed man page is generated from the revised POD.

Existing features include undo/redo, search/substitution, shell commands and
filters, optional perltidy, stdin import and disk-backed large files. Visual
selection, tabs, splits, dot-repeat, Vimscript, plugins and crash recovery aren't
implemented yet. Editing is byte oriented. Interactive testing covers Linux and
macOS; native Windows supports batch and engine use.

The splash keeps its versionless title and support message, with a shorter
purpose-focused description. Editing behavior is unchanged. The CPAN archive
allowlist and audits remain in place. No upload to PAUSE is performed by CI or
this GitHub release; review the tarball before the first CPAN trial upload.
