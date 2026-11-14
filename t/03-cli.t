use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
my $pvim="$FindBin::Bin/../pvim";
my $dir=tempdir(CLEANUP=>1);
my $file=File::Spec->catfile($dir,'file with spaces.pl');
open my $f,'>',$file or die $!; print {$f} "old old\n"; close $f;
is(system($^X,$pvim,'--batch','-c','%s/old/new/g','-c','w',$file),0,'batch editing process');
open $f,'<',$file or die $!; is(<$f>,"new new\n",'batch saved result'); close $f;
is(system($^X,$pvim,'--batch','-c','s/new/unsaved/',$file),0,'batch without write succeeds');
open $f,'<',$file or die $!; is(<$f>,"new new\n",'batch never implicitly writes'); close $f;
ok(system($^X,$pvim,'--batch','-c','s/[/bad/',$file)!=0,'invalid command nonzero');
is(system($^X,$pvim,'--version'),0,'version');
is(system($^X,$pvim,'--help'),0,'help');
is(system($^X,$pvim,'--manual'),0,'manual without perldoc');
# Invoke via pipe so accidental interactive startup fails promptly.
if ($^O eq 'MSWin32') { ok(system($^X,$pvim,$file)!=0,'native Windows UI rejected') }
else { open my $pipe,'-|',$^X,$pvim,$file or die $!; my @output=<$pipe>; close $pipe; ok($?!=0,'no tty rejected') }
done_testing;
