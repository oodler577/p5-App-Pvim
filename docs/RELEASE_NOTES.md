pvim 0.1.6 adds **pvim -v** as a version shortcut (an explicitly confirmed
exception to Vim's flag semantics), while keeping --version.

Opening splash text is centered horizontally and vertically, recenters on terminal
resize/resume, and fits small terminals by removing spacers and clipping safely.

Help, POD, README, wiki, and CPAN-module documentation now show **pvim** as an
executable command. Standalone instructions include chmod and direct invocation.
The single-file runtime, plain-text display, yellow number gutter, shell tools,
and App::Pvim CPAN packaging remain. No upload to PAUSE is performed.
