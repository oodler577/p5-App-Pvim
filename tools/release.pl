#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin;
use File::Path qw(make_path);
use File::Copy qw(copy);
use Digest::SHA qw(sha256_hex);
use Archive::Tar;
require "$FindBin::Bin/../pvim";
chdir "$FindBin::Bin/.." or die $!;
make_path('dist');
for my $old (glob('dist/pvim-*.tar.gz')) { unlink $old or die $! }
copy('pvim','dist/pvim') or die $!; chmod 0755,'dist/pvim' or die $!;
copy('pvim','dist/pvim-standalone.pl') or die $!; chmod 0755,'dist/pvim-standalone.pl' or die $!;
my $tar=Archive::Tar->new;
for my $file ('pvim','README.md','LICENSE','ARTISTIC','COPYING','Changes',glob('docs/*.md'),glob('docs/wiki/*.md'),'AGENTS.md',glob('t/*.t'),glob('tools/*.*'),'.github/workflows/ci.yml') {
    $tar->add_files($file);
    $tar->rename($file,"pvim-$main::VERSION/$file");
}
$tar->write("dist/pvim-$main::VERSION.tar.gz",1) or die 'Cannot create archive';
open my $sums,'>','dist/SHA256SUMS' or die $!;
for my $file ('pvim','pvim-standalone.pl',"pvim-$main::VERSION.tar.gz") {
    open my $fh,'<',"dist/$file" or die $!; binmode $fh;
    my $d=Digest::SHA->new(256); $d->addfile($fh); close $fh;
    print {$sums} $d->hexdigest,"  $file\n";
}
close $sums or die $!;
print "Built standalone pvim, source archive and SHA256SUMS in dist/\n";
