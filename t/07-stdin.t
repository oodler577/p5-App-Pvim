use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);
require "$FindBin::Bin/../pvim";
my $dir = tempdir(CLEANUP => 1);
sub invoke {
    my ($input, @args) = @_;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $^X, "$FindBin::Bin/../pvim", @args);
    binmode $in; print {$in} $input; close $in;
    local $/; my $stdout = <$out>; my $stderr = <$err>;
    waitpid($pid, 0);
    return ($?, $stdout, $stderr);
}
my $file = "$dir/import.txt";
for my $text ("hi\n", "one\r\ntwo\nlast", '', ":q!\n\x1b:w danger\n", "a\0b\n") {
    my ($status) = invoke($text, '--batch', '-c', "w! $file", '-');
    is($status, 0, 'explicit stdin batch import succeeds');
    open my $fh, '<', $file or die $!; binmode $fh; local $/;
    is(<$fh>, $text, 'stdin bytes and endings preserved, including empty input');
    close $fh;
}
my ($status, $out, $err) = invoke("old\n", '--batch', '-c', 's/old/new/', '-c', "w! $file", '-');
is($status, 0, 'batch commands operate on imported data');
open my $fh, '<', $file or die $!;
is(<$fh>, "new\n", 'batch import edited'); close $fh;
($status, $out, $err) = invoke("hi\n", '--batch', '-c', 'q', '-');
ok($status, 'import has unsaved quit guard'); like($err, qr/Unsaved/i, 'guard explained');
($status) = invoke('', '--batch', '-c', 'q', '-');
ok($status, 'empty import also has unsaved quit guard');
($status) = invoke("hi\n", '--batch', '-c', 'q!', '-');
is($status, 0, 'explicit discard works');
($status) = invoke("ignored\n", '--batch', '-c', 'q');
is($status, 0, 'batch does not auto-import stdin');
($status, $out, $err) = invoke("hi\n");
ok($status, 'redirected stdout refused for automatic interactive import');
like($err, qr/terminal/i, 'no-terminal diagnostic');
unlike($out, qr/\e\[/, 'no screen escapes in redirected stdout');
# Exercise the shared streaming indexer over many read boundaries without a slurp.
open $fh, '+>', "$dir/large" or die $!; binmode $fh;
my $block = ('x' x 65535) . "\r\n";
print {$fh} $block for 1..128;
print {$fh} 'tail'; seek($fh, 0, 0) or die $!;
my $store = PVim::Store->load(undef, $fh);
is($store->{count}, 129, 'stream input indexed across block boundaries');
is($store->line(0), 'x' x 65535, 'CR at chunk boundary handled');
is($store->term(0), 2, 'split CRLF retained');
is($store->line(128), 'tail', 'unterminated tail retained');
ok($store->dirty, 'stream is modified');
ok(!defined($store->{path}), 'stream stays unnamed');
ok(defined(fileno($fh)), 'borrowed input handle remains open');
close $fh;
done_testing;
