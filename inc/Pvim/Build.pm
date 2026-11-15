package inc::Pvim::Build;
use Moose;
use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::VersionProvider', 'Dist::Zilla::Role::FileGatherer';

sub runtime_source {
    my ($self) = @_;
    my $path = $self->zilla->root . '/pvim';
    open my $fh, '<', "$path" or die "Read $path: $!";
    local $/;
    my $source = <$fh>;
    close $fh or die $!;
    return $source;
}
sub provide_version {
    my ($self) = @_;
    my ($version) = $self->runtime_source =~ /our\s+\$VERSION\s*=\s*'([^']+)'/;
    $self->log_fatal('Cannot determine version from standalone pvim') unless defined $version;
    return $version;
}
sub gather_files {
    my ($self) = @_;
    my $version = $self->provide_version;
    $self->add_file(Dist::Zilla::File::InMemory->new(
        name => 'script/pvim', content => $self->runtime_source, mode => 0755,
    ));
    my $module = <<'MODULE';
package App::Pvim;
use 5.010;
use strict;
use warnings;
our $VERSION = '__VERSION__';
1;
__END__

=head1 NAME

App::Pvim - install the portable Perl-centric pvim editor

=head1 SYNOPSIS

  pvim file.pl
  printf 'hi\n' | pvim
  pvim -v
  pvim --help
  pvim --manual

=head1 DESCRIPTION

This application distribution installs the single-file pvim command. This module
provides its CPAN namespace and version metadata; it does not expose an editor
library API. All editor runtime code and its complete manual are in the installed
pvim executable, which can also be copied and run independently with Perl 5.10+.

The editor uses the standard Perl library. Perl::Tidy is optional for formatting.
Interactive use requires a POSIX tty and ANSI terminal; native Windows supports
batch mode. See C<man pvim> or C<pvim --manual> for the complete controls,
stdin import, shell filters, file safety and current limits. This is an
experimental, byte-oriented editor with no crash recovery, visual mode or tabs.

=head1 BUGS AND SUPPORT

Report bugs at L<https://github.com/oodler577/pvim/issues>, including C<pvim -v>,
operating system, terminal and a minimal reproduction without private data.

=head1 LINKS

L<https://github.com/oodler577/pvim>

L<https://github.com/oodler577/pvim/wiki>

=head1 AUTHOR

Brett Estrade E<lt>OODLER@cpan.orgE<gt>

=head1 LICENSE

Copyright 2026 Brett Estrade. Available under the same terms as Perl 5 itself.

=cut
MODULE
    $module =~ s/__VERSION__/$version/g;
    $self->add_file(Dist::Zilla::File::InMemory->new(
        name => 'lib/App/Pvim.pm', content => $module,
    ));
}
__PACKAGE__->meta->make_immutable;
1;
