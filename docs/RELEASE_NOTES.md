pvim 0.1.8 changes the opening title to **pvim - portable vim clone**, without a
version number. Use `pvim -v` or `pvim --version` for version details.

The portability documentation now records actual passed CI: six Perl versions on
Linux/macOS/Windows, four unprivileged Linux-distro jobs, standalone packaging and
App::Pvim build/install checks. Interactive coverage is Linux and macOS; native
Windows is batch/engine-only. BSD, 32-bit, vintage and other Unix environments
remain unverified. The editor is a limited vi-style subset, not full Vim compatibility.

The support message, centered layout, plain text and existing editing behavior
remain. No upload to CPAN/PAUSE is performed.
