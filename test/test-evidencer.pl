#!/usr/bin/perl
use Test::More; # https://metacpan.org/pod/Test::More
use feature say;
use Data::Dumper;

my $exe = "./evidencer";
ok( -f $exe , 'Evidencer binary found' );
ok( -x $exe , 'Evidencer binary is executable' );

system '/usr/bin/perl','-w','-c',$exe;
ok( $? == 0 , 'Perl Compiles the binary' );
exit if $?;


my $TDIR = "./suits/BUILDTEST";
my $cfg = "-c $TDIR/evidencer.cfg -s BUILDTEST";

print "d=".(-d $TDIR);
system "rm -rf $TDIR" if(-d $TDIR);

system $exe,'-C','-s','BUILDTEST';
ok( $? == 0 , 'BUILDTEST directory structure (re)created' );


sub createfile{
  my $fname = shift @_;
  print "creating $fname (with ".($#_+1)." lines)... ";
  open(my $FI,'>',$fname) or BAIL_OUT($fname." ".$!);
  say $FI $_ for @_;
  close($FI)  or BAIL_OUT($fname." ".$!);
  chmod 0755, $fname; # scripts need to be executable
  say " done."
}

my $cfgF = "$TDIR/evidencer.cfg";
createfile($cfgF,
  'RUN=echo "%{RUNSCRIPTFQ} on %{RUNSERVERFQ}"',
  'ALIAS ALTERNATIVE1=RUN=on %{RUNSERVERFQ} run %{RUNSCRIPTFQ}',
  'RUN_ARG=echo "%{RUNSCRIPTFQ} on %{RUNSERVERFQ} with argument %{ARG}"',
  '/show=&RUN:={,}&RUN_ARG:={,}&RUN_PRE:={,}&RUN_START:={,}&RUN_FINISH:={,}',
  '/norun=&RUN:={,}&RUN_ARG:=',
);


system $exe '-c',"$TDIR/evidencer.cfg",'-C','-s','BUILDTEST';
ok( $? == 0 , 'BUILDTEST directory structure' );

my %S = (
  'servers' => {
    'DUP-PR' =>[ qw(svr1pr svr2pr svr1pr) ],
    'VM-ET' => [ qw(svr1et svr1pr) ],
    'VM-PR' =>[ qw(svr1pr svr2pr) ],
    'VM-PR-DMZ' =>[ "svr1dmz Prod DMZ Primary", map{ "${_} Prod DMZ BACKUP"} glob("{svr}{2,3}{dmz}") ],
  },
  'scripts' => {
    'TEST1=++ET' => ['echo "Test1 for ET"'],
    'TEST1=++PR' => ['echo "Test1 for PR"'],
    'TEST2=++ET' => ['echo "Test2 for ET"'],
    'TEST2=++PR+' => ['echo "Test2 for PR"'],
    'HELPSCRIPT=NOMATCH' => [
		'# This is a normal comment',
		'#: This is a compact help comment',
		'#+: This is an extended help comment',
		'#=: This is an extended help comment',
		'#!: This is an extended help comment',
		'#?: This is confirmation prompt',
		'echo "HELPSCRIPT for NOMATCH"'
	]
  },
);

#say Dumper \%S;

sub execute{
	my($cmdstr) = @_;
	my $strlen = length $cmdstr;
	say;
	say "#" x ($strlen + 4);
	say "# " . $cmdstr ." #";
	say "#" x ($strlen + 4);
	say;
	return `$cmdstr`;
}

# Create datafiles
for my $d (keys %S){
  for my $f (keys %{$S{$d}}){
    my $FN="$TDIR/$d/$f";
    createfile($FN, @{$S{$d}{$f}} );
  }
}
say "Now creating PR file";
createfile("$TDIR/servers/PR",qw(svr3pr svr4pr));

say "=== Set up complete. Starting tests ===";

@_ = execute("$exe $cfg TEST1= -d -v |grep -v '# RUN:'|grep RUN|grep -v DUP");
say @_;
is($#_,2-1,'two lines 1');
like($_[0], qr/TEST1=\+\+ET on VM-ET/, 'TEST1 on ET');
like($_[1], qr/TEST1=\+\+PR on VM-PR/, 'TEST1 on PR');


@_ = execute("$exe $cfg =++ET -d -v |grep -v '# RUN:'|grep RUN");
say @_;
is($#_,2-1,'two lines 2');
like($_[0], qr/TEST1=\+\+ET on VM-ET/, 'TEST1 on ET');
like($_[1], qr/TEST2=\+\+ET on VM-ET/, 'TEST2 on ET');


@_ = execute("$exe $cfg TEST1=++PR -d -v |grep -v '# RUN:'|grep RUN |grep -v DUP");
say @_;
is($#_,1-1,'one line');
like($_[0], qr/TEST1=\+\+PR on VM-PR/, 'TEST1 on PR');

@_ = execute("$exe $cfg TEST2=++PR+ -d -v |grep -v '# RUN:'|grep RUN |grep -v DUP");
say @_;
is($#_,2-1,'two lines dmz');
like($_[0], qr/TEST2=\+\+PR\+ on VM-PR/, 'TEST2 on PR');
like($_[1], qr/TEST2=\+\+PR\+ on VM-PR-DMZ/, 'TEST2 on PR with dmz');

subtest 'Grouping' => sub {
  plan tests => 2;

  @_ = execute("$exe $cfg TEST2=++PR+ -g -d -v |grep -v '# RUN:'|grep RUN");
  say @_;
  is($#_,1-1,'one line grouped');
  like($_[0], qr/TEST2=\+\+PR\+ on DUP-PR  VM-PR  VM-PR-DMZ/, 'grouped');
};

subtest 'Folding1' => sub {
  plan tests => 3;

  @_ = execute("$exe $cfg =++ET -f -d -v |grep -v '# RUN:'|grep -e RUN -e echo");
  say @_;
  is($#_,2-1,'two lines folded');
  like($_[0], qr/TEST1=\+\+ET  TEST2=\+\+ET on VM-ET/, 'folded');
  like($_[1], qr!/.*/suits/BUILDTEST/scripts/TEST1=\+\+ET  /.*/suits/BUILDTEST/scripts/TEST2=\+\+ET on /.*/suits/BUILDTEST/servers/VM-ET"!i, 'folded run');
  
};


subtest 'bundling parameters' => sub {
  plan tests => 3;

  @_ = execute("$exe $cfg =++ET -fdv |grep -v '# RUN:'|grep -e RUN -e echo");
  say @_;
  is($#_,2-1,'two lines bundled');
  like($_[0], qr/TEST1=\+\+ET  TEST2=\+\+ET on VM-ET/, 'bundling');
  like($_[1], qr!/.*/suits/BUILDTEST/scripts/TEST1=\+\+ET  /.*/suits/BUILDTEST/scripts/TEST2=\+\+ET on /.*/suits/BUILDTEST/servers/VM-ET"!i, 'bundling run');
  
};

subtest 'scriptregexp' => sub {
  plan tests => 3;
  @_ = execute("$exe $cfg TEST+=VM-ET -d -v |grep -v '# RUN:'|grep RUN");
  is($#_,2-1,'two lines for scriptregexp');
  like($_[0], qr/BUILDTEST:TEST1=VM-ET.* on VM-ET/, 'scriptregexp1');
  like($_[1], qr/BUILDTEST:TEST2=VM-ET.* on VM-ET/, 'scriptregexp2');
  say @_;
};

subtest 'serverregexp' => sub {
  plan tests => 3;
  @_ = execute("$exe $cfg =++ET\@svr1et -d -v |grep -v '# RUN:'|grep RUN");
  say @_;
  is($#_,2-1,'two lines for serverregexp');
  like($_[0], qr/BUILDTEST:TEST1=\+\+ET on BUILDTEST#TEST1=\+\+ET#VM-ET/, 'newserverfile1');
  like($_[1], qr/BUILDTEST:TEST2=\+\+ET on BUILDTEST#TEST2=\+\+ET#VM-ET/, 'newserverfile2');
};

subtest 'redefine' => sub {
  plan tests => 2;
  @_ = execute("$exe $cfg =++ET\@svr1et -d -v -r ALTERNATIVE1 |grep ^on");
  say @_;
  like($_[0], qr!on /.*/BUILDTEST#TEST1=\+\+ET#VM-ET#\d+ run /.*/BUILDTEST/scripts/TEST1=\+\+ET!, 'alternative1a');
  like($_[1], qr!on /.*/BUILDTEST#TEST2=\+\+ET#VM-ET#\d+ run /.*/BUILDTEST/scripts/TEST2=\+\+ET!, 'alternative1b');
};

subtest 'argument1' => sub {
  plan tests => 2;
  @_ = execute("$exe $cfg TEST2=++ET\@svr1et -d -v -- --fantastic 4 |grep ^echo");
  say @_;
  like($_[0], qr!on /.*/BUILDTEST#TEST2=\+\+ET#VM-ET#\d+ with argument --fantastic  4!, 'argument1a');
  @_ = execute("$exe $cfg TEST2=++ET\@svr1et -d -v -a incredible |grep ^echo");
  say @_;
  like($_[0], qr!on /.*/BUILDTEST#TEST2=\+\+ET#VM-ET#\d+ with argument incredible!, 'argument2a');
};

@_ = execute("$exe $cfg =# -y -dv |grep -v '# RUN:'|grep RUN");
say @_;
is($#_,3-1,'hash is latest (DUP-PR) alfabetically');
like($_[1], qr/BUILDTEST:TEST1=\+\+ET on DUP-PR/, 'TEST1 on PR hash');
like($_[2], qr/BUILDTEST:TEST2=\+\+PR\+ on DUP-PR/, 'TEST2 on PR hash');

@_ = execute("$exe $cfg =# -dv -l VM-PR |grep -v '# RUN:'|grep RUN");
say @_;
is($#_,2-1,'Test --loop 1');
unlike($_[0], qr/DMZ/, 'TEST1 on PR through --loop 1 - no DMZ match');
unlike($_[0], qr/BUILDTEST:TEST1=\+\+ET on VM-PR/, 'TEST1 on PR through --loop 1');
like($_[1],   qr/BUILDTEST:TEST2=\+\+PR\+ on VM-PR/, 'TEST2 on PR through --loop 1');

@_ = execute("$exe $cfg =# -v -l VM-PR |grep -v '#('|grep RUN");
say @_;
is($#_,2-1,'Test --loop 2');
unlike($_[0], qr/DMZ/, 'TEST1 on PR through --loop 2 - no DMZ match');
unlike($_[0], qr/BUILDTEST:TEST1=\+\+ET on VM-PR/, 'TEST1 on PR through --loop 2 - no ET match');
like($_[1],   qr/BUILDTEST:TEST2=\+\+PR\+ on VM-PR/, 'TEST2 on PR through --loop 2');

subtest 'LOOPs are same as not using loops' => sub {
  plan tests => 6;
	my @ONE= execute("$exe $cfg =# -dv -l VM-PR |grep -v '# RUN:'|grep RUN");
	my @TWO= execute("$exe $cfg =VM-PR -dv  |grep -v '# RUN:'|grep RUN");
	while($a=shift(@ONE)){
		$b = shift @TWO;
		is($a,$b,"Loop v/s noloop one element is same");
	}

	my @ONE= execute("$exe $cfg =# -dv -l VM-PR,VM-ET |grep -v '# RUN:'|grep RUN");
	my @TWO= execute("$exe $cfg =VM-PR,VM-ET -dv  |grep -v '# RUN:'|grep RUN");
	while($a=shift(@ONE)){
		$b = shift @TWO;
		is($a,$b,"Loop v/s noloop two elements is same");
	}
};

subtest 'Test accuracy of new regexp' => sub {
  plan tests => 8;
	@_ = execute("$exe $cfg 'TEST[12]=+PR' -v |grep -v '#('|grep RUN| grep -v DUP");
	say @_;
	is($#_,2-1,'two lines for output accuracy');
	like($_[0], qr/BUILDTEST:TEST1=\+\+PR on VM-PR/, 'TEST1 accuracy test with new rexexp PR');
	like($_[1], qr/BUILDTEST:TEST2=\+\+PR\+ on VM-PR/, 'TEST2 accuracy test with new rexexp PR');
	@_ = execute("$exe $cfg 'TEST[12]=+PR,+ET' -v |grep -v '#('|grep RUN| grep -v DUP");
	say @_;
	is($#_,4-1,'four lines for output accuracy');
	like($_[1], qr/BUILDTEST:TEST1=\+\+PR on VM-PR/, 'TEST1 accuracy test with new rexexp PR - multiple');
	like($_[3], qr/BUILDTEST:TEST2=\+\+PR\+ on VM-PR/, 'TEST2 accuracy test with new rexexp PR - multiple');
	like($_[0], qr/BUILDTEST:TEST1=\+\+ET on VM-ET/, 'TEST1 accuracy test with new rexexp ET - multiple');
	like($_[2], qr/BUILDTEST:TEST2=\+\+ET on VM-ET/, 'TEST2 accuracy test with new rexexp ET - multiple');
};

subtest 'Test completion' => sub {
  plan tests => 8;
 	@_ = execute("COMP_CWORD=7 $exe --completion $cfg ./evidencer --complete evidencer +1 ="); # ./evidencer +1=
	say @_;
	is($#_,1-1,'Completion1: one lines of results');
	like($_[0], qr/^TEST1=DUP-PR TEST1=VM-ET TEST1=VM-PR$/, 'Completion1: test1 only matches 3');
 	@_ = execute("COMP_CWORD=7 $exe --completion $cfg ./evidencer --complete evidencer +2 ="); # ./evidencer +2=
	say @_;
	is($#_,1-1,'Completion2: one lines of results');
	like($_[0], qr/^TEST2=DUP-PR TEST2=VM-ET TEST2=VM-PR TEST2=VM-PR-DMZ$/, 'Completion2: test2 matches 3');
 	@_ = execute("COMP_CWORD=9 $exe --completion $cfg ./evidencer --complete evidencer +2 = +DMZ"); # ./evidencer +2=+DMZ
	say @_;
	is($#_,1-1,'Completion3: one lines of results');
	like($_[0], qr/^VM-PR-DMZ$/, 'Completion3: DMZ matches 1');
 	@_ = execute("COMP_CWORD=9 $exe --completion $cfg ./evidencer --complete evidencer TEST1 = VM-ET"); # ./evidencer TEST1=VM-ET
	say @_;
	is($#_,1-1,'Completion4: one lines of results');
	like($_[0], qr/^VM-ET$/, 'Completion4: VM-ET matches 1');
};


subtest 'Test Query' => sub {
  plan tests => 2;
 	@_ = `$exe $cfg -Q /show,/norun`;
	say @_;
	is($#_,2-1,'Query1: No regexp, despite two slashes');
	like($_[0], qr/^.norun=.RUN.=/, 'Query1: First line is /norun (alphabetical)');
};


subtest 'Named hosts' => sub {
  plan tests => 4;

	@_ = execute("$exe $cfg TEST2=VM-PR-DMZ\@BACK -Dvd |grep -i look ");
	say @_;
	is($#_,1-1,'one line - named hosts');
	like($_[0], qr{2/3}, 'Primary does not match');
	like($_[0], qr/2 matched/, 'Backup matches 2 servers');
	like($_[0], qr/match BACK/, 'We are matching BACK');
};

subtest 'Named hosts with range' => sub {
  plan tests => 8;

	@_ = execute("$exe $cfg TEST2=VM-PR-DMZ\@BACK#2 -Dvd |grep -i -e look -e From ");
	say @_;
	is($#_,2-1,'two lines - named hosts range');
	like($_[0], qr{2/3}, 'Two matches');
	like($_[1], qr/1 matched/, 'Backup matches 1 servers');
	like($_[0], qr/match BACK/, 'We are matching BACK');

	@_ = execute("$exe $cfg TEST2=VM-PR-DMZ\@BACK#-1 -Dvd |grep -i -e look -e From ");
	say @_;
	like($_[0], qr{2/3}, 'Two matches');
	like($_[1], qr/1 matched/, 'Backup matches 1 servers');
	
	@_ = execute("$exe $cfg TEST2=VM-PR-DMZ\@#1--1 -Dvd |grep -i -e look -e From ");
	say @_;
	like($_[0], qr{3/3}, 'Three matches');
	like($_[1], qr/3 matched/, 'Backup matches 3 servers');
};


subtest 'MAXMATCHES' => sub {
  plan tests => 8;

	@_ = execute("$exe $cfg = -v -r MAXMATCHES=3 2>&1 | grep FATAL:");
	say @_;
	is($#_,1-1,'one line - MAXMATCHES 1');
	like($_[0], qr/matches more tha/, 'Too many matches 1');

	@_ = execute("$exe $cfg TEST1= -v -r MAXMATCHES=1 2>&1 | grep FATAL:");
	say @_;
	is($#_,1-1,'one line - MAXMATCHES 2');
	like($_[0], qr/matches more tha/, 'Too many matches 2');

	@_ = execute("$exe $cfg =VM-PR+ -v -r MAXMATCHES=2 2>&1 | grep FATAL:");
	say @_;
	is($#_,1-1,'one line - MAXMATCHES 3');
	like($_[0], qr/matches more tha/, 'Too many matches 3');


	@_ = execute("$exe $cfg =VM-PR+ -v -r MAXMATCHES=6 2>&1 | grep FATAL:");
	say @_;
	is($#_,0-1,'zero lines - MAXMATCHES 4');
	unlike($_[0], qr/matches more tha/, '(Not) too many matches 4');
};


subtest 'duplicate hosts (-gb)' => sub {
  plan tests => 4;

	@_ = execute("$exe $cfg TEST1=+-PR -Dvd -gb|grep ^echo");
	is($#_,1-1,'one line - bundled');
	like($_[0], qr/BUNDLESERVER/, 'Servers are bundled');
	like($_[0], qr/ on /, 'the captured line is: echo "... on ..."');
	$_[0]=~s/.* on |"$//g;
	chomp $_[0];
	my $fn = $_[0];
	@_ = execute("wc -l $fn");
	like($_[0], qr/2/, 'We have 2 servers, deduplicated');
};

subtest 'scripthelp' => sub {
  plan tests => 5;

  @_ = execute("$exe $cfg HELPSCRIPT= -hv");
  say @_;
  is($#_,11-1,'11 lines of help');
  unlike(@_, qr/confirmation/, 'Not confirmation lines');

  @_ = execute("$exe $cfg HELPSCRIPT= -h");
  say @_;
  is($#_,5-1,'5 lines of help (padding and title)');
  like($_[1], qr/HELPSCRIPT/, 'help title');
  like($_[3], qr/compact/, 'Only compact lines');
};

subtest 'scriptconfirm' => sub {
  plan tests => 4;

  @_ = execute("yes | $exe $cfg HELPSCRIPT=NOMATCH");
  say @_;
  is($#_,1-1,'1 lines of output');
  like($_[0], qr/confirmation/, 'Confirmation line, approval through pipe');

  @_ = execute("$exe $cfg HELPSCRIPT=NOMATCH -y");
  say @_;
  is($#_,1-1,'1 lines of output');
  unlike($_[0], qr/confirmation/, 'Confirmation line, approval through option parameters');
};


subtest 'globlize' => sub {
  plan tests => 21;
  ok( open(my $EFH, '<', $exe) , 'read $exe globlize' );
  my @code;
  # https://www.aplawrence.com/Words2005/2005_06_12.html
  # https://perlhacks.com/2014/01/dots-perl/
  while(<$EFH>) {
    push( @code, $_ ) if /sub globlize/ .. /\}/;
  }
  chomp(@code);
  grep s/\s*#.*//, @code;
  eval join "", @code;
  my @P = qw(+ +A +-A A++B  ++  A+ A-+ A+- A-+B +-+-+ ++B A++ A+-B A-+B C--     --C C-   -C D--D  D++D); 
  my @R = qw(* *A *-A A-*-B *-* A* A-* A*-* A-*B *-*-* *-B A-* A*-B A-*B C-*-* *-*-C C-* *-C D-*-D D-*-D);
  for(my $i=0;$i<=$#P;++$i){
    my $v = $P[$i];
    globlize($v);
    ok( $v eq $R[$i], "globlize($P[$i]) = $R[$i] => $v ?");
  }
};

done_testing();



