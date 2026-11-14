#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin;
use File::Spec;
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use Pod::Text;
use Pod::Checker;
require "$FindBin::Bin/../pvim";
my ($check,$output);
GetOptions('check'=>\$check,'output=s'=>\$output) or die "Usage: wiki.pl [--check] [--output DIR]\n";
my $root=File::Spec->rel2abs("$FindBin::Bin/..");
sub read_file {
    open my $fh,'<',$_[0] or die "Read $_[0]: $!\n";
    local $/; my $text=<$fh>; close $fh or die $!; return $text;
}
my $script=read_file("$root/pvim");
die "POD validation failed\n" if Pod::Checker::podchecker("$root/pvim") > 0;
my $manual=''; open my $podout,'>',\$manual or die $!;
Pod::Text->new(width=>88)->parse_from_file("$root/pvim",$podout); close $podout;
my $commands='';
for my $section ('NORMAL MODE','EX COMMANDS') {
    my ($body)=$script =~ /^=head1 \Q$section\E\n(.*?)(?=^=head1|\z)/msg;
    die "Missing POD section $section\n" unless defined $body;
    my @listing=grep { /^  \S/ } split /\n/,$body;
    die "Missing command listing\n" unless @listing;
    $commands.="## $section\n\n```text\n".join("\n",@listing)."\n```\n\n";
}
my %pages;
for my $source (glob("$root/docs/wiki/*.md")) {
    my ($name)=$source =~ m{([^/]+)$};
    my $text=read_file($source);
    $text =~ s/\@\@VERSION\@\@/$main::VERSION/g;
    $text =~ s/\@\@COMMANDS\@\@/$commands/g;
    $pages{$name}=$text;
}
$pages{'Full-Manual.md'}="# Full embedded manual\n\nGenerated from `pvim --manual` for version $main::VERSION.\n\n```text\n$manual\n```\n";
$pages{'Change-History.md'}="# Change history\n\n```text\n".read_file("$root/Changes")."\n```\n";
for my $pair (['Testing.md','TESTING.md'],['Portability.md','PORTABILITY.md']) {
    $pages{$pair->[0]}=read_file("$root/docs/$pair->[1]");
}
for my $needed (qw(Home Quick-Start Installation Modes-and-Editing Navigation Command-Reference Search-and-Substitution Perl-Features Undo-and-Registers CLI-and-Batch Large-Files File-Safety-and-Encoding Vim-Differences Troubleshooting Testing Portability Full-Manual Releases Change-History Documentation-Maintenance _Sidebar _Footer)) {
    die "Missing page $needed\n" unless exists $pages{"$needed.md"};
}
for my $name (sort keys %pages) {
    my $text=$pages{$name};
    die "Unresolved template marker in $name\n" if $text =~ /\@\@[A-Z_]+\@\@/;
    # Current wiki links are simple Markdown destinations; skip external URLs.
    while ($text =~ /\]\(([^\s)]+)\)/g) {
        my $link=$1; next if $link =~ /^(?:https?:|#)/;
        $link =~ s/#.*//; $link =~ s/\.md$//;
        die "Broken wiki link in $name: $link\n" unless exists $pages{"$link.md"};
    }
}
if ($check) { print "Wiki validated: ".scalar(keys %pages)." pages, version $main::VERSION; POD and local links OK\n"; exit 0 }
$output=File::Spec->rel2abs(defined($output) ? $output : "$root/build/wiki");
make_path($output);
my $manifest="$output/.pvim-wiki-manifest";
if (-f $manifest) {
    for my $old (split /\n/,read_file($manifest)) {
        die "Invalid managed filename\n" unless $old =~ /^[A-Za-z0-9_-]+\.md$/;
        unlink "$output/$old" or die $! if !exists($pages{$old}) && -f "$output/$old";
    }
}
for my $name (sort keys %pages) {
    open my $fh,'>',"$output/$name" or die "Write $name: $!\n";
    print {$fh} $pages{$name} or die $!; close $fh or die $!;
}
open my $fh,'>',$manifest or die $!; print {$fh} join("\n",sort keys %pages),"\n" or die $!; close $fh or die $!;
print "Generated ".scalar(keys %pages)." wiki pages for pvim $main::VERSION in $output\n";
