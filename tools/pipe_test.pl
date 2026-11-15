#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use Data::Dumper ();
my $perl=$ENV{PVIM_PERL} || $^X;
my $script="$FindBin::Bin/../pvim";
my $dir=tempdir('pvim pipe XXXXX',TMPDIR=>1,CLEANUP=>1);
sub bytes { open my $f,'<',$_[0] or die $!; binmode $f; local $/; my $data=<$f>; return defined($data) ? $data : q{} }
sub invoke {
    my ($input,@args)=@_;
    open my $out,'>',"$dir/stdout" or die $!;
    open my $err,'>',"$dir/stderr" or die $!;
    my ($saved_out,$saved_err);
    open $saved_out,'>&',\*STDOUT or die $!;
    open $saved_err,'>&',\*STDERR or die $!;
    open STDOUT,'>&',$out or die $!; open STDERR,'>&',$err or die $!;
    my ($status,$error);
    {
        local $SIG{PIPE}='IGNORE';
        local $SIG{ALRM}=sub { die "Pipe test timed out\n" };
        eval {
            alarm 30;
            # One real stdin pipe; output goes to files, so no output pipe can
            # fill while the parent writes. This also avoids Open3's Win32 EOF issue.
            my $pipe;
            if ($^O eq 'MSWin32' && $] < 5.022) {
                # Old Windows Perls have only string-form pipe opens. Keep the
                # real argv in a helper so cmd.exe never parses ex commands or
                # destination paths. The helper execs the same Perl and editor.
                my $helper="$dir/pipe-child.pl";
                open my $child,'>',$helper or die $!;
                my $argv=Data::Dumper->new([[$perl,$script,@args]])->Terse(1)->Dump;
                print {$child} 'my @cmd=@{'.$argv.'}; exec {$cmd[0]} @cmd; die "Exec: $!\n";';
                close $child or die $!;
                my $command=qq{"$perl" "$helper"};
                open $pipe,'|-',$command or die "Start editor: $!\n";
            } else {
                open $pipe,'|-',$perl,$script,@args or die "Start editor: $!\n";
            }

            binmode $pipe;
            print {$pipe} $input;
            close $pipe; $status=$?;
            alarm 0; 1;
        } or $error=$@;
        alarm 0;
    }
    open STDOUT,'>&',$saved_out or die $!; open STDERR,'>&',$saved_err or die $!;
    close $out; close $err;
    die $error if $error;
    return ($status,bytes("$dir/stdout"),bytes("$dir/stderr"));
}
my $target="$dir/result with spaces";
for my $text ("hi\n","one\r\ntwo\nlast",'',"\0:q!\n","x\r\n" x 50000) {
    my ($status,undef,$err)=invoke($text,'--batch','-c',"w! $target",'-');
    is($status,0,'real pipe import succeeds, '.length($text).' bytes') or diag $err;
    is(bytes($target),$text,'pipe preserves binary bytes and line endings');
}
my ($status,undef,$err)=invoke("old\n",'--batch','-c','s/old/new/','-c',"w! $target",'-');
is($status,0,'edit imported pipe') or diag $err;
is(bytes($target),"new\n",'substitution saved');
for my $text ('',"hi\n") {
    my ($status,undef,$err)=invoke($text,'--batch','-c','q','-');
    isnt($status,0,'pipe import has unsaved guard'); like($err,qr/nsaved/,'guard diagnosed');
}
my ($no_tty,$stdout,$stderr)=invoke("hi\n");
isnt($no_tty,0,'interactive output pipe refused'); like($stderr,qr/terminal/,'terminal diagnostic');
unlike($stdout,qr/\e\[/,'no screen escapes in redirected output');
done_testing;
