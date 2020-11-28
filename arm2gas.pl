#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use Getopt::Long;

my $ver = '0.1';
my $helpmsg = <<"USAGE";
arm2gas(v$ver) - Convert legacy ARM assembly syntax (used by armasm) to GNU syntax (GAS)

Usage: arm2gas.pl [options] file1 [file2...]
Options:
    -c, --compatible            Keeps compatibility with armclang assembler
    -e <SRC>                    Perform a one-line convertion (inside '' or "")
    -h, --help                  Show this help text
    -i, --verbose               Show a message on every suspicious convertions
    -l, --lowercase             Use lowercase for instructions [default: uppercase]
    -n, --no-comment            Discard all the comments in output
    -o, --output=<file>         Specify the output filename
    -s, --suffix=<string>       Suffix(no dot) of the output filename [default: out]
    -v, --version               Show version info
    -w, --no-warning            Suppress all warning messages

Cautions:
    By default, for some directives that have no equivalent in GCC format,
    arm2gas will try best to convert and generate warning information on
    the specific line. Therefore, a 'warning' does NOT necessarily mean no
    issue, please check the conversion result to ensure it works as expected.

    Note that arm2gas will assume that the input file is in the correct syntax,
    otherwise, the conversion result is UNEXPECTED

Issues and Bugs:
    https://github.com/typowritter/arm2gas
    mailto:yxnan\@pm.me
USAGE

#--------------------------------
# command-line arguments parsing
#--------------------------------
my @input_files     = ();
my @output_files    = ();
my $inplace_conv    = '';
my $output_suffix   = 'out';
my $opt_compatible  = 0;
my $opt_verbose     = 0;
my $opt_lowercase   = 0;
my $opt_nocomment   = 0;
my $opt_nowarning   = 0;

GetOptions(
    "output=s"      => \@output_files,
    "suffix=s"      => \$output_suffix,
    "e=s"           => \$inplace_conv,
    "help"          => sub { print $helpmsg; exit },
    "v|version"     => sub { print "$ver\n"; exit },
    "compatible"    => \$opt_compatible,
    "i|verbose"     => \$opt_verbose,
    "lowercase"     => \$opt_lowercase,
    "n|no-comment"  => \$opt_nocomment,
    "w|no-warning"  => \$opt_nowarning
) or die("I'm die.\n");

@input_files = @ARGV;

# debug
say "ARGV:              |@ARGV| ($#ARGV)";
say "input_files:       |@input_files| ($#input_files)";
say "output_files:      |@output_files| ($#output_files)";
say "inplace_conv:      |$inplace_conv|";
say "output_suffix:     |$output_suffix|";
say "opt_compatible:    |$opt_compatible|";
say "opt_verbose:       |$opt_verbose|";
say "opt_lowercase:     |$opt_lowercase|";
say "opt_nocomment:     |$opt_nocomment|";
say "opt_nowarning:     |$opt_nowarning|";

