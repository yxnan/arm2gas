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
    -r, --return-code           Print return code definitions
    -s, --strict                Error on directives that have no equivalent counterpart
    -v, --version               Show version info
    -w, --no-warning            Suppress all warning messages
    -x, --suffix=<string>       Suffix(no dot) of the output filename [default: out]

Cautions:
    By default (without --strict), for those directives that have no equivalent
    in GNU format, arm2gas will try best to convert and generate warning information
    on the specific line. Therefore, a 'warning' does NOT necessarily mean no issue,
    please check the conversion result to ensure it works as expected.

    Note that arm2gas will assume that the input file is in the correct syntax,
    otherwise, the conversion result is UNEXPECTED

Issues and Bugs:
    https://github.com/typowritter/arm2gas
    mailto:yxnan\@pm.me
USAGE

#--------------------------------
# return code definitions
#--------------------------------
my $ERR_NO_INPUT        = 1;
my $ERR_AMBIGUOUS_INOUT = 2;

my $rvalmsg = <<"RETVAL";
armgas may return one of several error code if it encounters problems.

    0       No problems occurred.
    1       No input file specified.
    2       Input and output files doesn't match one-to-one.
    255     Generic error code.

RETVAL


#--------------------------------
# misc definitions
#--------------------------------



#--------------------------------
# function definitions
#--------------------------------

# @args: line, file, err_msg
sub msg_error {
    print "\e[01;31mERROR\e[0m: $_[2]. Stop at line $_[0] in $_[1]\n";
}


#--------------------------------
# command-line arguments parsing
#--------------------------------
my @input_files     = ();
my @output_files    = ();
my $inplace_conv    = '';
my $output_suffix   = 'out';
my $opt_compatible  = 0;
my $opt_verbose     = 0;
my $opt_strict      = 0;
my $opt_lowercase   = 0;
my $opt_nocomment   = 0;
my $opt_nowarning   = 0;

GetOptions(
    "output=s"      => \@output_files,
    "x|suffix=s"    => \$output_suffix,
    "e=s"           => \$inplace_conv,
    "help"          => sub { print $helpmsg; exit },
    "return-code"   => sub { print $rvalmsg; exit },
    "v|version"     => sub { print "$ver\n"; exit },
    "compatible"    => \$opt_compatible,
    "i|verbose"     => \$opt_verbose,
    "s|strict"      => \$opt_strict,
    "lowercase"     => \$opt_lowercase,
    "n|no-comment"  => \$opt_nocomment,
    "w|no-warning"  => \$opt_nowarning
) or die("I'm die.\n");

@input_files = @ARGV;

# debug
# say "ARGV:              |@ARGV| ($#ARGV)";
# say "input_files:       |@input_files| ($#input_files)";
# say "output_files:      |@output_files| ($#output_files)";
# say "inplace_conv:      |$inplace_conv|";
# say "output_suffix:     |$output_suffix|";
# say "opt_compatible:    |$opt_compatible|";
# say "opt_verbose:       |$opt_verbose|";
# say "opt_strict:        |$opt_strict|";
# say "opt_lowercase:     |$opt_lowercase|";
# say "opt_nocomment:     |$opt_nocomment|";
# say "opt_nowarning:     |$opt_nowarning|";

if (@input_files == 0) {
    msg_error(__LINE__, $0, "No input file");
    exit($ERR_NO_INPUT);
}
elsif (@output_files > 0 && $#input_files != $#output_files) {
    msg_error(__LINE__, $0, "Input and output files must match one-to-one");
    exit($ERR_AMBIGUOUS_INOUT);
}
