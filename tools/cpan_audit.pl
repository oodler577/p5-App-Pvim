#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use File::Find qw(find);
use File::Spec;
use JSON::PP qw(decode_json);
use Pod::Checker qw(podchecker);
my $root = shift or die "Usage: $0 App-Pvim-VERSION\n";
sub bytes { open my $f,'<',$_[0] or die "Read $_[0]: $!\n"; binmode $f; local $/; my $data=<$f>; return defined($data) ? $data : q{} }
my @manifest = grep { length && !/^#/ } map { my $line=$_; $line =~ s/^\s+|\s+$//g; $line } split /\n/,bytes("$root/MANIFEST");
my $allowed = qr{\A(?:pvim|README\.md|Changes|LICENSE|ARTISTIC|COPYING|dist\.ini|Makefile\.PL|META\.(?:json|yml)|MANIFEST|script/pvim|lib/App/Pvim\.pm|inc/Pvim/Build\.pm|t/[^/]+\.t|tools/[^/]+\.(?:pl|sh)|docs/(?:wiki/)?[^/]+\.md)\z};
my %manifest;
for (@manifest) {
    die "Unexpected archive member: $_\n" unless /$allowed/;
    die "Duplicate manifest member: $_\n" if $manifest{$_}++;
    die "Missing manifest member: $_\n" unless -f "$root/$_";
    die "Unwanted residue: $_\n" if /(?:\.bak|\.tdy|\.log|~)$/;
}
my %actual;
find({no_chdir=>1,wanted=>sub {
    return unless -f $_;
    my $name=File::Spec->abs2rel($File::Find::name,$root); $name =~ s{\\}{/}g;
    $actual{$name}=1;
}},$root);
for (keys %actual) { die "Unmanifested file: $_\n" unless $manifest{$_} }
my $meta=decode_json(bytes("$root/META.json"));
die "Wrong distribution name\n" unless $meta->{name} eq 'App-Pvim';
die "Wrong license\n" unless join(',',@{$meta->{license}}) eq 'perl_5';
die "App::Pvim excluded from index\n" if grep { $_ eq 'App::Pvim' } @{$meta->{no_index}{package} || []};
my $requires=$meta->{prereqs}{runtime}{requires};
die "Wrong Perl requirement\n" unless $requires->{perl} == 5.010;
my @expected=qw(perl Digest::SHA Errno File::Basename File::Spec File::Temp Getopt::Long IO::Select Pod::Usage POSIX);
die "Unexpected runtime prerequisites\n" unless join(',',sort keys %$requires) eq join(',',sort @expected);
for (keys %{$meta->{prereqs}{configure}{requires} || {}}) {
    die "Unexpected configure prerequisite: $_\n" unless $_ eq 'ExtUtils::MakeMaker';
}
for (qw(pvim script/pvim lib/App/Pvim.pm)) { die "Invalid POD: $_\n" if podchecker("$root/$_") > 0 }
die "Generated runtime differs\n" unless bytes("$root/pvim") eq bytes("$root/script/pvim");
print "CPAN audit passed: manifest allowlist, complete kit, core runtime prerequisites, license, POD and identical script\n";
