#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use Time::HiRes qw(time);
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
require "$FindBin::Bin/../pvim";
my $mb = shift || 64;
die "Usage: benchmark.pl [MiB]\n" unless $mb =~ /^\d+$/ && $mb > 0;
my $dir = tempdir(CLEANUP=>1);
my $path = File::Spec->catfile($dir,'large.pl');
open my $fh,'>',$path or die $!; binmode $fh;
my $line = 'my $value = 123; # benchmark '.('x' x 227)."\n"; # 256 bytes
my $count = int($mb*1024*1024/length($line));
my $storelock = $line x 4096;
for (1 .. int($count/4096)) { print {$fh} $storelock or die $! }
print {$fh} $line x ($count%4096) or die $!; close $fh or die $!;
my $start=time; my $store=PVim::Store->load($path); my $open=time-$start;
die "Incorrect line count\n" unless $store->{count}==$count;
die "Initial buffer fragmented\n" unless @{$store->{pieces}}==1;
my $e=PVim::Editor->new($store); my @latencies;
srand 731;
for (1..1000) {
    my $r=int(rand($count)); my $t=time; $e->ex(''.($r+1)); $e->key('x'); $e->key('u');
    die "Undo mismatch\n" unless $store->line($r) eq substr($line,0,-1);
    push @latencies, (time-$t)*1000;
}
@latencies=sort {$a<=>$b} @latencies;
my $save=time; $store->save(File::Spec->catfile($dir,'copy')); $save=time-$save;
die "Round-trip digest mismatch\n" unless PVim::Store::fingerprint($path) eq PVim::Store::fingerprint(File::Spec->catfile($dir,'copy'));
printf "file_mib=%.2f lines=%d open_seconds=%.3f save_seconds=%.3f random_jump_edit_undo_p50_ms=%.3f p95_ms=%.3f p99_ms=%.3f pieces=%d\n", (-s $path)/1048576,$count,$open,$save,$latencies[499],$latencies[949],$latencies[989],scalar @{$store->{pieces}};
# RSS is reported by /usr/bin/time -v externally; assertions are semantic, not flaky timing limits.
