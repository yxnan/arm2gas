#!/usr/bin/perl

use warnings;
use feature 'say';
use Getopt::Long;
use Data::Dumper qw(Dumper);

my $ver = '0.1';
my $helpmsg = <<"USAGE";
arm2gas(v$ver) - Convert legacy ARM assembly syntax (used by armasm) to GNU syntax (GAS)

Usage: arm2gas.pl [options] file1 [file2...]
Options:
    -c, --compatible            Keeps compatibility with armclang assembler
    -h, --help                  Show this help text
    -i, --verbose               Show a message on every suspicious convertions
    -n, --no-comment            Discard all the comments in output
    -o, --output=<file>         Specify the output filename
    -r, --return-code           Print return code definitions
    -s, --strict                Error on directives that have no equivalent counterpart
    -v, --version               Show version info
    -w, --no-warning            Suppress all warning messages
    -x, --suffix=<string>       Suffix of the output filename [default: '.out']

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
my $ERR_ARGV        = 1;
my $ERR_IO          = 2;

my $rvalmsg = <<"RETVAL";
armgas may return one of several error code if it encounters problems.

    0       No problems occurred.
    1       Invalid or conflict command-line args.
    2       File I/O error.
    255     Generic error code.

RETVAL


#--------------------------------
# global definitions
#--------------------------------

# conversion result
%result = (
    res => '',
    inc => 1
);


#--------------------------------
# function definitions
#--------------------------------

# @args: exit_status, line, file, err_msg
sub exit_error {
    print "\e[01;31mERROR\e[0m: $_[1]\n";
    exit($_[0]);
}

sub msg_info {
    print "\e[01;34mINFO\e[0m: $_[0]\n";
}

sub msg_warn {
    print "\e[00;33mWARN\e[0m: $_[0]\n";
}


#--------------------------------
# command-line arguments parsing
#--------------------------------
my @input_files     = ();
my @output_files    = ();
my $output_suffix   = '.out';
my $opt_compatible  = 0;
my $opt_verbose     = 0;
my $opt_strict      = 0;
my $opt_nocomment   = 0;
my $opt_nowarning   = 0;

GetOptions(
    "output=s"      => \@output_files,
    "x|suffix=s"    => \$output_suffix,
    "help"          => sub { print $helpmsg; exit },
    "return-code"   => sub { print $rvalmsg; exit },
    "v|version"     => sub { print "$ver\n"; exit },
    "compatible"    => \$opt_compatible,
    "i|verbose"     => \$opt_verbose,
    "s|strict"      => \$opt_strict,
    "n|no-comment"  => \$opt_nocomment,
    "w|no-warning"  => \$opt_nowarning
) or die("I'm die.\n");

@input_files = @ARGV;

# validate input
if (@input_files == 0) {
    exit_error($ERR_ARGV, "$0:".__LINE__.
        ": No input file");
}
elsif (@output_files > 0 && $#input_files != $#output_files) {
    exit_error($ERR_ARGV, "$0:".__LINE__.
        ": Input and output files must match one-to-one");
}
elsif ($output_suffix !~ /^\.*\w+$/) {
    exit_error($ERR_ARGV, "$0:".__LINE__.
        ": Invalid suffix '$output_suffix'");
}

# pair input & output files
if (@output_files == 0) {
    @output_files = map {"$_$output_suffix"} @input_files;
}
my %in_out_files;
@in_out_files{@input_files} = @output_files;

# file processing
foreach (keys %in_out_files) {
    # global vars for diagnosis
    $in_file  = $_;
    $out_file = $in_out_files{$_};
    $line_n1 = 1;
    $line_n2 = 1;

    open(my $f_in, "<", $_)
        or exit_error($ERR_IO, "$0:".__LINE__.": $in_file: $!");
    open(my $f_out, ">", $out_file)
        or exit_error($ERR_IO, "$0:".__LINE__.": $out_file: $!");

    while (my $line = <$f_in>) {
        single_line_conv($line);
        print $f_out $result{res};
        $line_n1++;
        $line_n2 += $result{inc};
    }

    close $f_in  or exit_error($ERR_IO, "$0:".__LINE__.": $in_file: $!");
    close $f_out or exit_error($ERR_IO, "$0:".__LINE__.": $out_file: $!");
}

sub single_line_conv {
    my $line = shift;

    # warn if detect a string
    if ($line =~ m/"+/ && !$opt_nowarning) {
        msg_warn("$in_file:$line_n1 -> $out_file:$line_n2".
            ": Conversion containing strings is suspicious");
    }

    # ------ Conversion: comments ------
    # if has comments
    if ($line =~ m/;/) {
        if ($opt_nocomment) {
            $line =~ s/;.*$//;
        }
        else {
            $line =~ s/;/\/\//;
        }

    }

    # ------ Conversion: labels ------
    if ($line =~ m/^\w+\s*$/) {
        $line =~ s/(\w+)/$1:/;
    }


    if ($line =~ m/^\s*$/) {
        $result{res} = "";
        $result{inc} = 0;
    }
    else {
        $result{res} = $line;
        $result{inc} = 1;
    }
}