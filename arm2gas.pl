#!/usr/bin/perl

use strict;
use warnings;

my $helpmsg = <<"USAGE";
arm2gas.pl - Convert legacy ARM assembly syntax (used by armasm) to GNU syntax (GAS)

Usage: arm2gas.pl [options] [--] file1 [file2...]
Options:
    -a, --armclang-compatible    Keeps compatibility with armclang assembler
    -d, --discard-comments       Discard all the comments in output
    -e <SRC>                     Perform a one-line convertion (inside '' or "")
    -h, --help                   Show this help text
    -l, --lowercase              Use lowercase for instructions [default: uppercase]
    -o, --output=<file>          Specify the output file name
    -v, --verbose                Show a message on every suspecious convertions
    -V, --version                Show version info

Cautions:
    By default, for some directives that have no equivalent in GCC format,
    arm2gas will try best to convert and generate warning information on
    the specific line. Therefore, a 'warning' does NOT necessarily mean no
    issue, please check the conversion result to ensure it works as expected.

    Note that arm2gas will assume that the input file is in the correct syntax,
    otherwise, the conversion result is UNEXPECTED
USAGE

print $helpmsg;