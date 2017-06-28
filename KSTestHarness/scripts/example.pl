#!/usr/bin/env perl

# Copyright 2017 KohaSuomi
#
# This file is part of Koha-Ansible-Pipeline.
#

use 5.22.0;
use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use English; #Use verbose alternatives for perl's strange $0 and $\ etc.
use Getopt::Long qw(:config no_ignore_case);
use Try::Tiny;
use Scalar::Util qw(blessed);

my ($help, $dryRun);
my ($verbose) = (0);
my ($clover, $tar, $resultsDir);
my ($testAll, $testUnit, $testXt, $testDb);


GetOptions(
    'h|help'                      => \$help,
    'v|verbose:i'                 => \$verbose,
    'dry-run'                     => \$dryRun,
    'results-dir=s'               => \$resultsDir,
    'clover'                      => \$clover,
    'tar'                         => \$tar,
    'a|all'                       => \$testAll,
    'u|unit'                      => \$testUnit,
    'x|xt'                        => \$testXt,
    'd|db'                        => \$testDb,
);

my $usage = <<USAGE;

Runs a ton of tests with other metrics if needed

  -h --help             This friendly help!

  -v --verbose          Integer, the level of verbosity

  --tar                 Create a testResults.tar.gz from all tests and deliverables

  --dry-run             Don't run tests or other metrics. Simply show what would happen.

  --results-dir         Where to gather test deliverables and archive. Defaults to the current dir

  --clover              Run Devel::Cover and output Clover-reports

  -a --all              Run all tests.

  -u --unit             Unit tests t/*.t

  -x --xt               XT tests

  -d --db               db_dependent tests

EXAMPLE

    ##First run unit test suite and archive the test deliverables
    example.pl --unit --tar
    ##Then run a big test suite, with code coverage metrics
    example.pl --all --tar --clover

    ##If you are interested in unit tests and db tests only...
    example.pl --unit --db -v 1

USAGE

if ($help) {
    print $usage;
    exit 0;
}

run();
sub run {
    my (@tests, $tests);
    push(@tests, @{_getAllTests()})         if $testAll;
    push(@tests, @{_getUnitTests()})        if $testUnit;
    push(@tests, @{_getXTTests()})          if $testXt;
    push(@tests, @{_getDbDependentTests()}) if $testDb;

    print "Selected the following test files:\n".join("\n",@tests)."\n" if $verbose;

    my $ksTestHarness = KSTestHarness->new({
        resultsDir => $resultsDir,
        tar        => $tar,
        clover     => $clover,
        testFiles  => \@tests,
        dryRun     => $dryRun,
        verbose    => $verbose,
    });
    $ksTestHarness->run();
}

sub _getAllTests {
    return _getTests('.', '*.t');
}
sub _getUnitTests {
    return _getTests('t', '*.t', 1); #maxdepth 1
}
sub _getXTTests {
    return _getTests('xt', '*.t');
}
sub _getSIPTests {
    return _getTests('C4/SIP/t', '*.t');
}
sub _getDbDependentTests {
    return _getTests('t/db_dependent', '*.t');
}
sub _getTests {
    my ($dir, $selector, $maxDepth) = @_;
    $maxDepth = 999 unless(defined($maxDepth));
    my $files = `/usr/bin/find $dir -maxdepth $maxDepth -name '$selector'`;
    my @files = split(/\n/, $files);
    return \@files;
}
