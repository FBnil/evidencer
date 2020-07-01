#!/usr/bin/perl
use Test::More; # https://metacpan.org/pod/Test::More
use feature say;
use Data::Dumper;

my $exe = "./evidencer";

ok( -f $exe , 'Evidencer binary found' );
my $TDIR = "./suits/BUILDTEST";

print "d=".(-d $TDIR);
system "rm -rf $TDIR" if(-d $TDIR);

system $exe,'-C','-s','BUILDTEST';
ok( $? == 0 , 'BUILDTEST directory structure' );

my $cfgF = "$TDIR/evidencer.cfg";
createfile($cfgF,
  'RUN=echo "%{RUNSCRIPTFQ} on %{RUNSERVERFQ}"',
  'ALIAS ALTERNATIVE1=RUN=on %{RUNSERVERFQ} run %{RUNSCRIPTFQ}',
  'RUN_ARG=echo "%{RUNSCRIPTFQ} on %{RUNSERVERFQ} with argument %{ARG}"'
);

system $exe,'-C','-s','BUILDTEST';
ok( $? == 0 , 'BUILDTEST directory structure' );

my %S = (
  'servers' => {
    'VM-ET' => [ qw(svr1et svr2et) ],
    'VM-PR' =>[ qw(svr1pr svr2pr) ],
    'VM-PR-DMZ' =>[ qw(svr1dmz svr2dmz) ],
  },
  'scripts' => {
    'TEST1=++ET' => ['echo "Test1 for ET"'],
    'TEST1=++PR' => ['echo "Test1 for PR"'],
    'TEST2=++ET' => ['echo "Test2 for ET"'],
    'TEST2=++PR+' => ['echo "Test2 for PR"'],
  },
);

#say Dumper \%S;

# Create datafiles
for my $d (keys %S){
  for my $f (keys %{$S{$d}}){
    my $FN="$TDIR/$d/$f";
    createfile($FN, @{$S{$d}{$f}} );
  }
}

@_ = `$exe -s BUILDTEST TEST1= -d -v |grep -v '# RUN:'|grep RUN`;
say @_;
is($#_,2-1,'two lines 1');
like($_[0], qr/TEST1=\+\+ET on VM-ET/, 'TEST1 on ET');
like($_[1], qr/TEST1=\+\+PR on VM-PR/, 'TEST1 on PR');


@_ = `$exe -s BUILDTEST =++ET -d -v |grep -v '# RUN:'|grep RUN`;
say @_;
is($#_,2-1,'two lines 2');
like($_[0], qr/TEST1=\+\+ET on VM-ET/, 'TEST1 on ET');
like($_[1], qr/TEST2=\+\+ET on VM-ET/, 'TEST2 on ET');


@_ = `$exe -s BUILDTEST TEST1=++PR -d -v |grep -v '# RUN:'|grep RUN`;
say @_;
is($#_,1-1,'one line');
like($_[0], qr/TEST1=\+\+PR on VM-PR/, 'TEST1 on PR');

@_ = `$exe -s BUILDTEST TEST2=++PR+ -d -v |grep -v '# RUN:'|grep RUN`;
say @_;
is($#_,2-1,'two lines dmz');
like($_[0], qr/TEST2=\+\+PR\+ on VM-PR/, 'TEST2 on PR');
like($_[1], qr/TEST2=\+\+PR\+ on VM-PR-DMZ/, 'TEST2 on PR with dmz');

subtest 'Grouping' => sub {
  plan tests => 2;

  @_ = `$exe -s BUILDTEST TEST2=++PR+ -g -d -v |grep -v '# RUN:'|grep RUN`;
  say @_;
  is($#_,1-1,'one line grouped');
  like($_[0], qr/TEST2=\+\+PR\+ on VM-PR  VM-PR-DMZ/, 'grouped');
};

subtest 'Folding1' => sub {
  plan tests => 3;

  @_ = `$exe -s BUILDTEST =++ET -f -d -v |grep -v '# RUN:'|grep -e RUN -e echo`;
  say @_;
  is($#_,2-1,'two lines folded');
  like($_[0], qr/TEST1=\+\+ET  TEST2=\+\+ET on VM-ET/, 'folded');
  like($_[1], qr!/home/nilton/CODE/PERL/EVIDENCER/suits/BUILDTEST/scripts/TEST1=\+\+ET  /home/nilton/CODE/PERL/EVIDENCER/suits/BUILDTEST/scripts/TEST2=\+\+ET on /home/nilton/CODE/PERL/EVIDENCER/suits/BUILDTEST/servers/VM-ET"!, 'folded run');
  
};


subtest 'bundling parameters' => sub {
  plan tests => 3;

  @_ = `$exe -s BUILDTEST =++ET -fdv |grep -v '# RUN:'|grep -e RUN -e echo`;
  say @_;
  is($#_,2-1,'two lines bundled');
  like($_[0], qr/TEST1=\+\+ET  TEST2=\+\+ET on VM-ET/, 'bundling');
  like($_[1], qr!/home/nilton/CODE/PERL/EVIDENCER/suits/BUILDTEST/scripts/TEST1=\+\+ET  /home/nilton/CODE/PERL/EVIDENCER/suits/BUILDTEST/scripts/TEST2=\+\+ET on /home/nilton/CODE/PERL/EVIDENCER/suits/BUILDTEST/servers/VM-ET"!, 'bundling run');
  
};


subtest 'serverregexp' => sub {
  plan tests => 2;
  @_ = `$exe -s BUILDTEST =++ET\@svr1et -d -v |grep -v '# RUN:'|grep RUN`;
  say @_;
  like($_[0], qr/BUILDTEST:TEST1=\+\+ET on BUILDTEST#TEST1=\+\+ET#VM-ET/, 'newserverfile1');
  like($_[1], qr/BUILDTEST:TEST2=\+\+ET on BUILDTEST#TEST2=\+\+ET#VM-ET/, 'newserverfile2');
};

subtest 'redefine' => sub {
  plan tests => 2;
  @_ = `$exe -s BUILDTEST =++ET\@svr1et -d -v -r ALTERNATIVE1 |grep ^on`;
  say @_;
  like($_[0], qr!on /.*/BUILDTEST#TEST1=\+\+ET#VM-ET#\d+ run /.*/BUILDTEST/scripts/TEST1=\+\+ET!, 'alternative1a');
  like($_[1], qr!on /.*/BUILDTEST#TEST2=\+\+ET#VM-ET#\d+ run /.*/BUILDTEST/scripts/TEST2=\+\+ET!, 'alternative1b');
};

subtest 'argument1' => sub {
  plan tests => 2;
  @_ = `$exe -s BUILDTEST TEST2=++ET\@svr1et -d -v -- --fantastic 4 |grep ^echo`;
  say @_;
  like($_[0], qr!on /.*/BUILDTEST#TEST2=\+\+ET#VM-ET#\d+ with argument --fantastic 4!, 'argument1a');
  @_ = `$exe -s BUILDTEST TEST2=++ET\@svr1et -d -v -a incredible |grep ^echo`;
  say @_;
  like($_[0], qr!on /.*/BUILDTEST#TEST2=\+\+ET#VM-ET#\d+ with argument incredible!, 'argument2a');
};



done_testing();

sub createfile{
  my $fname = shift @_;
  say "creating $fname";
  open(FI,'>',$fname) or BAIL_OUT($fname." ".$!);
  say FI $_ for @_;
  close(FI)  or BAIL_OUT($fname." ".$!);
}