#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use POSIX ();
my $perl=$ENV{PVIM_PERL} || $^X;
my $script=File::Spec->rel2abs("$FindBin::Bin/../pvim");

package PVimTest::Session;
use strict;
use warnings;
use IO::Pty;
use IO::Tty::Constant qw(TIOCSWINSZ TIOCSCTTY PENDIN);
use IO::Select;
use POSIX ();
use Errno qw(EIO EINTR EAGAIN EWOULDBLOCK ENOTTY);
use Time::HiRes qw(time);
sub attrs {
    my ($fh,$mask)=@_;
    my $t=POSIX::Termios->new;
    $t->getattr(fileno($fh)) or die "tcgetattr: $!\n";
    return [$t->getiflag,$t->getoflag,$t->getcflag,
        $t->getlflag & ($mask ? ~PENDIN : ~0),$t->getispeed,$t->getospeed,
        map { $t->getcc($_) } 0..POSIX::NCCS()-1];
}
sub resize { ioctl($_[0]{slave},TIOCSWINSZ,pack('S4',$_[1],$_[2],0,0)) or die "Resize: $!\n" }
sub new {
    my ($class,$opt)=@_;
    my $master=IO::Pty->new; my $slave=$master->slave;
    my $s=bless {master=>$master,slave=>$slave,output=>'',before=>attrs($slave,$^O eq 'darwin'),
        owns=>($opt->{shell} || (exists($opt->{piped}) && !exists($opt->{controlling})))},$class;
    $s->resize($opt->{rows} || 24,$opt->{cols} || 80);
    my ($reader,$writer);
    pipe($reader,$writer) or die "Pipe: $!\n" if exists $opt->{piped};
    my $pid=fork; die "Fork: $!\n" unless defined $pid;
    unless ($pid) {
        eval {
            if ($opt->{shell} || exists($opt->{piped})) {
                POSIX::setsid() != -1 or die "setsid: $!\n";
                unless (exists($opt->{controlling}) && !$opt->{controlling}) {
                    $SIG{TTOU}='IGNORE';
                    ioctl($slave,TIOCSCTTY,0) or die "Controlling tty: $!\n";
                    POSIX::tcsetpgrp(fileno($slave),getpgrp()) or die "Foreground tty: $!\n";
                    $SIG{TTOU}='DEFAULT';
                }
            } else { setpgrp(0,0) or die "setpgrp: $!\n" }
            if ($reader) { close $writer; open STDIN,'<&',$reader or die $!; close $reader }
            else { open STDIN,'<&',$slave or die $! }
            open STDOUT,'>&',$slave or die $!; open STDERR,'>&',$slave or die $!;
            # Close only the descriptor here; IO::Pty owns a cached slave handle.
            POSIX::close(fileno($master));
            my @cmd=$opt->{shell} ? ('/bin/sh','-i') : ($opt->{perl},$opt->{script},@{$opt->{args} || []});
            exec {$cmd[0]} @cmd; die "Exec: $!\n";
        };
        print STDERR $@; POSIX::_exit(127);
    }
    $s->{pid}=$pid; $master->blocking(0);
    if ($reader) { close $reader; binmode $writer; print {$writer} $opt->{piped}; close $writer }
    $s->{select}=IO::Select->new($master); $s->drain(.25);
    return $s;
}
sub drain {
    my ($s,$duration)=@_; $duration=.10 unless defined $duration;
    my $until=time()+$duration;
    while (time() < $until) {
        next unless $s->{select}->can_read($until-time() > 0 ? $until-time() : 0);
        my $n=sysread($s->{master},my $chunk,65536);
        if (!defined $n) { next if $! == EINTR; last if $! == EIO || $! == EAGAIN || $! == EWOULDBLOCK; die "PTY read: $!\n" }
        last unless $n; $s->{output}.=$chunk;
    }
    return $s->{output};
}
sub send {
    my ($s,$text)=@_; my $offset=0;
    while ($offset<length $text) {
        my $n=syswrite($s->{master},$text,length($text)-$offset,$offset);
        if (!defined $n) { next if $! == EINTR; if ($! == EAGAIN) { $s->drain(.01); next } die "PTY write: $!\n" }
        $offset+=$n;
    }
    $s->drain;
}
sub poll {
    my ($s)=@_; return $s->{status} if exists $s->{status};
    if (waitpid($s->{pid},POSIX::WNOHANG()) > 0) {
        my $status=$?; $s->{status}=($status & 127) ? 128+($status & 127) : $status >> 8;
    }
    return $s->{status};
}
sub wait_exit {
    my ($s)=@_; my $until=time()+5;
    while (!defined $s->poll) { die "Editor exit timed out\n" if time()>$until; $s->drain(.01) }
    $s->drain(.01); return $s->{status};
}
sub signal { kill $_[1],$_[0]{pid} or die "Signal $_[1]: $!\n" }
sub stopped {
    my ($s)=@_; my $until=time()+5;
    while (time()<$until) {
        my $pid=waitpid($s->{pid},POSIX::WNOHANG()|POSIX::WUNTRACED()); my $native=${^CHILD_ERROR_NATIVE};
        if ($pid>0) { my $v=$native; die "Editor exited instead of stopping: $v\n" unless POSIX::WIFSTOPPED($v); $s->drain; return POSIX::WSTOPSIG($v) }
        $s->drain(.02);
    }
    die "Editor did not enter kernel stopped state\n";
}
sub resume { $_[0]->signal('CONT'); $_[0]->drain(.15) }
sub lflag { my $t=POSIX::Termios->new; $t->getattr(fileno($_[0]{slave})) or die $!; return $t->getlflag }
sub close {
    my ($s)=@_; return 1 if $s->{closed};
    if (!defined $s->poll) { $s->signal('CONT'); $s->signal('TERM') }
    eval { $s->wait_exit; 1 } or do { $s->signal('KILL'); $s->wait_exit };
    $s->drain(.01);
    my $after=eval { attrs($s->{slave},$^O eq 'darwin') }; my $error=$@;
    my $restored;
    if ($error) {
        die $error unless $^O eq 'darwin' && $s->{owns} && $! == ENOTTY;
        $restored=index($s->{output},"\e[?2004l")>=0;
    } else { $restored=join(',',@$after) eq join(',',@{$s->{before}}) }
    close $s->{slave}; close $s->{master}; $s->{closed}=1;
    return $restored;
}
sub DESTROY { my ($s)=@_; local $@; eval { $s->close } if $s->{pid} && !$s->{closed} }

package main;
my ($session,$path);
sub bytes { open my $f,'<',$_[0] or die $!; binmode $f; local $/; my $v=<$f>; return defined($v)?$v:'' }
sub write_file { open my $f,'>',$_[0] or die $!; binmode $f; print {$f} $_[1]; close $f or die $! }
sub quote { my $v=$_[0]; $v =~ s/'/'"'"'/g; return "'$v'" }
sub start {
    my ($opt,@args)=@_;
    $session=PVimTest::Session->new({%$opt,args=>\@args,perl=>$perl,script=>$script});
    ok(!defined($session->poll),'editor running') or die $session->{output};
    return $session;
}
sub case {
    my ($name,$body)=@_;
    subtest $name=>sub {
        my $dir=tempdir(CLEANUP=>1); $path="$dir/sample.pl"; $session=undef;
        local $SIG{ALRM}=sub { die "PTY test timed out: $name\n" }; alarm 45;
        my $ok=eval { $body->(); 1 }; my $error=$@; alarm 0;
        fail($error) unless $ok;
        if ($session) { my $restored=eval { $session->close }; ok($restored,'terminal attributes restored') or diag $@; $session=undef }
        done_testing;
    };
}
sub quit_ok { my ($s,$keys)=@_; $s->send(defined($keys)?$keys:":q\r"); is($s->wait_exit,0,'clean exit') or diag $s->{output} }
sub contains { like($_[0]{output},qr/\Q$_[1]\E/,$_[2] || 'terminal output') }
sub canonical { ok(($_[0]->lflag & POSIX::ICANON()) ? $_[1] : !$_[1],$_[2] || 'canonical mode') }
sub centered {
    my ($s,$rows,$cols)=@_;
    my @frames=split /\e\[2J\e\[H/,$s->{output}; my $frame=$frames[-1];
    my @positions;
    while ($frame =~ /\e\[(\d+);(\d+)H([^\e]*)/g) { push @positions,[$1,$2,$3] }
    ok(@positions,'splash positions');
    my $first=int(($rows-@positions)/2)+1;
    is($positions[0][0],$first,'vertical centering');
    for my $i (0..$#positions) {
        my ($row,$col,$text)=@{$positions[$i]};
        is($row,$first+$i,'consecutive splash rows');
        is($col,int(($cols-length($text))/2)+1,'horizontal centering');
        cmp_ok($col+length($text)-1,'<=',$cols-1,'within width'); cmp_ok($row,'<=',$rows-1,'within height');
    }
    like($positions[0][2],qr/pvim/,'title visible');
}
case 'automatic and explicit stdin import'=>sub {
    for my $args ([],['-']) {
        my $s=start({piped=>"hi\r\n:q!\nlast"},@$args);
        unlike($s->{output},qr/Press any key/,'no splash'); contains($s,'hi');
        $s->send(":q\r"); ok(!defined($s->poll),'unsaved import guarded'); contains($s,'nsaved');
        $s->send(":.! tr h H\r"); contains($s,'Hi','filter inherits its input'); $s->send('u');
        $s->send(":! test -t 0 && printf KEYBOARD_TTY\r"); contains($s,"KEYBOARD_TTY\r\nPress ENTER",'shell inherits keyboard fd'); $s->send("\r");
        $s->send(":w $path\r"); quit_ok($s);
        like($s->{output},qr/\n\z/,'exit newline'); is(bytes($path),"hi\r\n:q!\nlast",'import bytes preserved');
        ok($s->close,'terminal restored'); $session=undef; unlink $path or die $!;
    }
};
case 'pipe requires controlling terminal'=>sub {
    my $s=PVimTest::Session->new({piped=>'hi',controlling=>0,perl=>$perl,script=>$script}); $session=$s;
    isnt($s->wait_exit,0,'no controlling tty rejected'); contains($s,'No controlling terminal');
    unlike($s->{output},qr/\e\[\?1049h/,'no terminal mode entered');
};
case 'real shell pipeline suspend and fg'=>sub {
    my $s=start({shell=>1});
    my $probe=quote($perl).' -MIO::Tty -MIO::Tty::Constant=PENDIN -MPOSIX -e '.quote(
        'my $t=POSIX::Termios->new; $t->getattr(0) or die $!; print join(q{,},$t->getiflag,$t->getoflag,$t->getcflag,$t->getlflag & ~PENDIN,$t->getispeed,$t->getospeed,map {$t->getcc($_)} 0..POSIX::NCCS()-1),qq{\n};');
    $s->send($probe.' > '.quote("$path.tty-before")."\r");
    $s->send("printf 'pipeline text\\n' | ".quote($perl).' '.quote($script)."\r"); $s->drain(.3); contains($s,'pipeline text');
    $s->send("A edited\e"); $s->send("\x1a"); $s->drain(.3);
    like($s->{output},qr/stopped|suspended/i,'shell observed stopped editor');
    $s->send("fg\r"); $s->drain(.3); $s->send(":w $path\r"); $s->send(":q\r");
    $s->send($probe.' > '.quote("$path.tty-after")."\r");
    is(bytes("$path.tty-after"),bytes("$path.tty-before"),'pipeline tty restored before shell resumed');
    quit_ok($s,"exit\r"); is(bytes($path),"pipeline text edited\n",'buffer survives suspend');
};
case 'empty pipe and signal restoration'=>sub {
    my $s=start({piped=>''}); contains($s,"\e[?1049h",'terminal mode entered');
    $s->send(":q\r"); ok(!defined($s->poll),'empty import guarded');
    $s->signal('TERM'); isnt($s->wait_exit,0,'signal exit'); like($s->{output},qr/\n\z/,'exit newline');
};
case 'Ctrl-Z preserves insert and unsaved text'=>sub {
    my $s=start({},'--no-splash',$path); $s->send('ifirst'); $s->send("\x1a");
    is($s->stopped,POSIX::SIGTSTP(),'kernel stopped state'); canonical($s,1);
    ok($s->lflag & POSIX::ECHO(),'echo restored'); contains($s,"\e[?1049l"); like($s->{output},qr/\n\z/,'suspend newline');
    $s->resume; canonical($s,0); contains($s,"\e[1;6H",'insert cursor restored');
    $s->send(' second'); $s->send("\e"); $s->send("\x1a"); $s->stopped; $s->resume;
    quit_ok($s,":wq\r"); like($s->{output},qr/\n\z/,'exit newline'); is(bytes($path),"first second\n",'insert preserved');
};
case 'prompt and external TSTP'=>sub {
    my $s=start({},'--no-splash',$path); $s->send('ihello'); $s->send("\e"); $s->send(':w');
    $s->send("\x1a"); $s->stopped; $s->resume; contains($s,':w','prompt preserved');
    $s->send("\r"); $s->signal('TSTP'); $s->stopped; $s->resume; quit_ok($s);
    is(bytes($path),"hello\n",'saved text');
};
case 'splash suspension'=>sub {
    my $s=start({}); my $initial=()=$s->{output}=~/pvim - portable vim clone/g;
    $s->send("\x1a"); $s->stopped; $s->resume;
    my $after=()=$s->{output}=~/pvim - portable vim clone/g; cmp_ok($after,'>',$initial,'splash redrawn');
    $s->send(' '); quit_ok($s);
};
case 'line numbers off by default and yellow'=>sub {
    write_file($path,"alpha\nbeta\n"); my $s=start({},$path);
    contains($s,"\e[1;1H\e[0malpha"); unlike($s->{output},qr/\e\[33m/,'numbers off');
    $s->send(":set number\r"); contains($s,"\e[33m  1\e[0m alpha"); contains($s,"\e[33m  2\e[0m beta"); contains($s,"\e[1;5H");
    my $before=length $s->{output}; $s->send(":set nonumber\r");
    like(substr($s->{output},$before),qr/\e\[1;1H\e\[0malpha/,'gutter removed'); quit_ok($s);
};
case 'number gutter widens'=>sub {
    write_file($path,"x\n" x 1000); my $s=start({},$path); $s->send(":set nu\r");
    contains($s,"\e[33m   1\e[0m x"); $s->send('G'); contains($s,"\e[33m1000\e[0m x"); quit_ok($s);
};
case 'tty EOF exit newline'=>sub {
    my $s=start({},'--no-splash'); my $t=POSIX::Termios->new; $t->getattr(fileno($s->{slave})) or die $!;
    $t->setcc(POSIX::VMIN(),0); $t->setcc(POSIX::VTIME(),1); $t->setattr(fileno($s->{slave}),POSIX::TCSANOW()) or die $!;
    $s->signal('WINCH'); is($s->wait_exit,0,'EOF exit'); like($s->{output},qr/\n\z/,'EOF newline');
};
case 'shell filter restoration and undo'=>sub {
    write_file($path,"one\ntwo\nthree\n"); my $s=start({},$path);
    $s->send(":2! tr a-z A-Z\r"); contains($s,'Filtered 1 lines'); canonical($s,0);
    $s->send('u'); $s->send(":%! tr a-z A-Z\r"); contains($s,'Filtered 3 lines');
    $s->send(":.! sh -c 'echo discarded; echo diagnostic >&2; exit 7'\r"); contains($s,'Filter failed (exit 7)'); canonical($s,0);
    quit_ok($s,":wq\r"); like($s->{output},qr/\n\z/,'exit newline'); is(bytes($path),"ONE\nTWO\nTHREE\n",'failed filter preserves text');
};
case 'shell display and read follow Vim'=>sub {
    write_file($path,"original\n"); my $s=start({},$path);
    $s->send(":! printf \"visible-output\"\r"); contains($s,'visible-output'); contains($s,'Press ENTER'); canonical($s,1);
    $s->send("\r"); canonical($s,0); $s->send(":r ! printf \"inserted\\n\"\r"); $s->send("!!tr a-z A-Z\r");
    quit_ok($s,":wq\r"); is(bytes($path),"original\nINSERTED\n",'read and filter');
};
case 'Perl text stays plain'=>sub {
    write_file($path,'my $x = "hello"; # comment'."\n"); my $s=start({},$path);
    contains($s,"\e[1;1H\e[0m".'my $x = "hello"; # comment'."\e[K"); quit_ok($s);
};
case 'centered splash and live resize'=>sub {
    my $s=start({rows=>24,cols=>80}); centered($s,24,80);
    for my $size ([40,120],[10,30],[4,12]) { $s->resize(@$size); $s->signal('WINCH'); $s->drain(.2); centered($s,@$size); ok(!defined($s->poll),'resize stays alive') }
    $s->send(' '); quit_ok($s);
};
case 'splash and writing'=>sub {
    my $s=start({}); contains($s,'pvim - portable vim clone'); $s->send(' ');
    $s->send("iuse strict;\rprint \"ok\";"); $s->send("\e"); quit_ok($s,":wq $path\r");
    is(bytes($path),"use strict;\nprint \"ok\";\n",'saved new file');
};
case 'escape decoding and arrows'=>sub {
    my $s=start({},'--no-splash',$path); $s->send("iabc\e0x"); $s->send("iZ\e[DQ"); $s->send("\e");
    quit_ok($s,":wq\r"); is(bytes($path),"QZbc\n",'arrows and queued keys decoded');
};
case 'bracketed paste cannot execute commands'=>sub {
    my $s=start({},'--no-splash',$path); $s->send("\e[200~hello\x1a\r:q!\rworld\e[201~");
    ok(!defined($s->poll),'paste did not quit'); $s->send("\e"); quit_ok($s,":wq\r");
    is(bytes($path),"hello\n:q!\nworld\n",'control discarded and commands kept as data');
};
case 'paste from prompt stays data'=>sub {
    my $s=start({},'--no-splash',$path); $s->send(':'); $s->send("\e[200~q!\rhello\e[201~");
    ok(!defined($s->poll),'prompt paste did not quit'); $s->send("\e"); quit_ok($s,":wq\r"); is(bytes($path),"q!\nhello\n",'prompt paste saved');
};
case 'escape and open above'=>sub {
    my $s=start({},'--no-splash',$path); $s->send("ione\eOzero"); $s->send("\e"); quit_ok($s,":wq\r"); is(bytes($path),"zero\none\n",'open above');
};
case 'quit guard and resize'=>sub {
    my $s=start({},'--no-splash',$path); $s->send('iunsaved'); $s->send("\e"); $s->send(":q\r"); contains($s,'Unsaved changes');
    $s->resize(12,40); $s->signal('WINCH'); $s->send("\x0c"); quit_ok($s,":q!\r"); ok(!-e $path,'discard did not create file');
};
case 'signal restores terminal'=>sub {
    my $s=start({},'--no-splash'); $s->signal('TERM'); isnt($s->wait_exit,0,'signal exit nonzero'); contains($s,'Terminated'); like($s->{output},qr/\n\z/,'signal newline');
};
case 'file bytes cannot control terminal'=>sub {
    write_file($path,"\e]52;c;evil\x07\n"); my $s=start({},$path); unlike($s->{output},qr/\e\]52/,'no terminal control from file');
    my $plain=$s->{output}; $plain =~ s/\e\[[0-9;?]*[A-Za-z]//g;
    like($plain,qr/\Q<1B>]52;c;evil<07>\E/,'control bytes escaped'); quit_ok($s);
};
done_testing;
