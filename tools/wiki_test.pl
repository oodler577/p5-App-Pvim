#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use File::Path qw(make_path);
use File::Find qw(find);
use File::Copy qw(copy);
use Cwd qw(abs_path getcwd);
use FindBin;
my $root=abs_path("$FindBin::Bin/..");
my $perl=$ENV{PVIM_PERL} || $^X;
my $base=tempdir(CLEANUP=>1);
sub bytes { open my $f,'<',$_[0] or die $!; binmode $f; local $/; my $data=<$f>; return defined($data) ? $data : q{} }
sub write_file { open my $f,'>',$_[0] or die $!; print {$f} $_[1]; close $f or die $! }
sub run {
    my ($cwd,@cmd)=@_;
    my ($fh)=tempfile(); my ($out,$err);
    open $out,'>&',\*STDOUT or die $!; open $err,'>&',\*STDERR or die $!;
    my $old=getcwd(); chdir $cwd or die $!;
    open STDOUT,'>&',$fh or die $!; open STDERR,'>&',$fh or die $!;
    my $status=system @cmd;
    open STDOUT,'>&',$out or die $!; open STDERR,'>&',$err or die $!;
    chdir $old or die $!; seek($fh,0,0) or die $!; local $/; my $text=<$fh>;
    return ($status,$text);
}
sub success {
    my @args=@_; my ($status,$out)=run(@args);
    die "Command failed (@args):\n$out" if $status;
    return $out;
}
sub pages {
    my ($dir)=@_; opendir my $d,$dir or die $!;
    return {map { $_=>bytes("$dir/$_") } grep { -f "$dir/$_" } readdir $d};
}
sub generate { success($root,$perl,"$root/tools/wiki.pl",'--output',$_[0]) }
subtest 'idempotence and managed cleanup'=>sub {
    my $out="$base/pages"; generate($out); my $first=pages($out);
    is(scalar(grep {/\.md$/} keys %$first),22,'22 generated pages');
    unlike($first->{'Home.md'},qr/\@\@/,'version marker expanded');
    for my $name (sort grep {/\.md$/} keys %$first) { unlike($first->{$name},qr/perl pvim/,"executable examples in $name") }
    like($first->{'Full-Manual.md'},qr/pvim -v/,'version documented');
    like($first->{"Quick-Start.md"},qr{\Q:%s/hello/world/g\E},"substitution documented");
    like($first->{'Full-Manual.md'},qr/--no-splash/,'splash option documented');
    generate($out); is_deeply(pages($out),$first,'generation is idempotent');
    write_file("$out/Personal.md",'keep this unmanaged page'); write_file("$out/Old-Generated.md",'obsolete');
    open my $f,'>>',"$out/.pvim-wiki-manifest" or die $!; print {$f} "Old-Generated.md\n"; close $f;
    generate($out); ok(-e "$out/Personal.md",'unmanaged page retained'); ok(!-e "$out/Old-Generated.md",'stale generated page removed');
};
subtest 'bad links fail before output'=>sub {
    my $source="$base/source"; make_path("$source/tools");
    for (qw(pvim Changes tools/wiki.pl)) { copy("$root/$_","$source/$_") or die $! }
    find({no_chdir=>1,wanted=>sub {
        my $path=$File::Find::name; my $rel=substr($path,length($root)+1);
        if (-d $path) { make_path("$source/$rel") }
        else { copy($path,"$source/$rel") or die $! }
    }},"$root/docs");
    open my $f,'>>',"$source/docs/wiki/Home.md" or die $!; print {$f} "\n[Broken](No-Such-Page)\n"; close $f;
    my $out="$base/bad-output";
    my ($status,$text)=run($root,$perl,"$source/tools/wiki.pl",'--output',$out);
    isnt($status,0,'bad link rejected'); like($text,qr/Broken wiki link/,'broken link diagnosed'); ok(!-e $out,'no partial output');
};
subtest 'guarded local Git publishing'=>sub {
    my $bare="$base/remote.git"; my $wiki="$base/wiki";
    success($base,'git','init','--bare',$bare); success($base,'git','clone',$bare,$wiki);
    success($wiki,'git','checkout','-b','master'); success($wiki,'git','config','user.name','Test');
    success($wiki,'git','config','user.email','test@example.invalid'); write_file("$wiki/Home.md",'initial');
    success($wiki,'git','add','Home.md'); success($wiki,'git','commit','-m','Initialize wiki'); success($wiki,'git','push','-u','origin','master');
    success($root,'sh',"$root/tools/publish-wiki.sh",$wiki);
    my $first=success($wiki,'git','rev-parse','HEAD');
    is($first,success($bare,'git','rev-parse','refs/heads/master'),'publish pushed to local bare remote');
    ok(-e "$wiki/Full-Manual.md",'manual published');
    like(success($root,'sh',"$root/tools/publish-wiki.sh",$wiki),qr/already current/,'no-op publication detected');
    is(success($wiki,'git','rev-parse','HEAD'),$first,'no unnecessary commit');
    write_file("$wiki/Home.md",'uncommitted user edit');
    my ($status,$text)=run($root,'sh',"$root/tools/publish-wiki.sh",$wiki);
    isnt($status,0,'dirty tree rejected'); like($text,qr/dirty/,'dirty tree diagnosed');
    is(bytes("$wiki/Home.md"),'uncommitted user edit','dirty page preserved');
};
done_testing;
