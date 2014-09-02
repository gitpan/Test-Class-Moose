
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::PodSpelling 2.006008
use Test::Spelling 0.12;
use Pod::Wordlist;


add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( bin lib  ) );
__DATA__
API
AnnoCPAN
Beresford
CPAN
Corneliu
DEPRECATIONS
Extensibility
OO
Oji
Oschwald
Otsuka
Petrea
Refactor
Rolsky
STDOUT
Stuckdownawell
TCM
TODO
Udo
arisdottle
distro
hardcode
hashrefs
invocant
metadata
munge
munges
namespace
ok
online
parallelizable
parallelize
parallelized
parameterized
prereq
rebless
runtime
startup
strawman
subtest
subtests
teardown
xUnit
Curtis
Ovid
Poe
ovid
Dave
autarch
Doug
Bell
doug
madcityzen
Gregory
goschwald
Jonathan
djgoku
Karen
Etheridge
ether
Neil
Bowers
neil
Olaf
Alders
olaf
curtis
curtis_ovid_poe
Paul
Boyd
pboyd
Stefan
stefan
Steven
Humphrey
catchgithub
stuckdownawell
Tom
tom
Heady
Velti
lib
Test
Class
Moose
Load
Role
Executor
Report
Config
Runner
Time
ParameterizedInstances
Reporting
Tutorial
Instance
Parallel
Timing
Method
Sequential
AutoUse
AttributeRegistry