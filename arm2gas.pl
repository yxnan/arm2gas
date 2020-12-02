#!/usr/bin/perl

use strict;
use warnings;
use feature ":5.14";
no warnings qw(experimental);
use Getopt::Long;

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
my $ERR_UNSUPPORT   = 3;

my $rvalmsg = <<"RETVAL";
armgas may return one of several error code if it encounters problems.

    0       No problems occurred.
    1       Invalid or conflict command-line args.
    2       File I/O error.
    3       Unsupported conversion.
    255     Generic error code.

RETVAL


#--------------------------------
# global definitions
#--------------------------------

# conversion result
our %result = (
    res => '',
    inc => 0
);

# stack
our @symbols = ();

# command-line switches
our $opt_compatible  = 0;
our $opt_verbose     = 0;
our $opt_strict      = 0;
our $opt_nocomment   = 0;
our $opt_nowarning   = 0;

# directives to match
our @drctv_arg0 = (
    "CODE16", "CODE32", "ELSE", "ENDIF", "ENTRY", "ENDP",
    "LTORG", "MACRO", "MEND", "MEXIT", "NOFP", "WEND"
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
    if ($opt_verbose) {
        print "\e[01;34mINFO\e[0m: $_[0]\n";
    }
}

# @args: no_exact_conv?, msg
sub msg_warn {
    if ($opt_strict && $_[0]) {
        exit_error($ERR_UNSUPPORT, $_[1]);
    }
    elsif (! $opt_nowarning) {
        print "\e[00;33mWARN\e[0m: $_[1]\n";
    }
}


#--------------------------------
# command-line arguments parsing
#--------------------------------
my @input_files     = ();
my @output_files    = ();
my $output_suffix   = '.out';

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
    our $in_file  = $_;
    our $out_file = $in_out_files{$_};
    our $line_n1  = 1;
    our $line_n2  = 1;

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
    print $f_out "\n";  # required by as

    close $f_in  or exit_error($ERR_IO, "$0:".__LINE__.": $in_file: $!");
    close $f_out or exit_error($ERR_IO, "$0:".__LINE__.": $out_file: $!");
}

sub single_line_conv {
    our $in_file;
    our $out_file;
    our $line_n1;
    our $line_n2;
    my $line = shift;
    $result{inc} = 1;

    # empty line
    if ($line =~ m/^\s*$/) {
        $result{res} = "\n";    # just keep it
        return;
    }

    # warn if detect a string
    if ($line =~ m/"+/) {
        msg_warn(0, "$in_file:$line_n1 -> $out_file:$line_n2".
            ": Conversion containing strings needs a manual check");
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

    # remove special symbol delimiter
    $line =~ s/\|//;

    # ------ Conversion: labels ------
    given ($line) {
        # single label
        when (m/^([a-zA-Z_]\w*)\s*(\/\/.*)?$/) {
            my $label = $1;
            $line =~ s/$label/$label:/ unless ($label ~~ @drctv_arg0);
        }
        # numeric local labels
        when (m/^\d+\s*(\/\/.*)?$/) {
            $line =~ s/(\d+)/$1:/;
        }
        # scope is not supported in GAS
        when (m/^((\d+)[a-zA-Z_]\w+)\s*(\/\/.*)?$/) {
            my $full_label = $1;
            my $num_label  = $2;
            msg_warn(1, "$in_file:$line_n1 -> $out_file:$line_n2".
                ": Numeric local label with scope '$1' is not supported in GAS".
                ", converting to '$2'");
            $line =~ s/$full_label/$num_label:/;
        }
        # delete ROUT directive
        when (m/^(\w+\s*ROUT)/i) {
            my $rout = $1;
            msg_warn(1, "$in_file:$line_n1 -> $out_file:$line_n2".
                ": Scope of numeric local label is not supported in GAS".
                ", removing ROUT directives");
            $line =~ s/$rout//;
        }
        # branch jump
        when (m/^\s*B[A-Z]*\s+(%([FB]?)([AT]?)(\d+)(\w*))/i) {
            my $label        = $1;
            my $direction    = $2;
            my $search_level = $3;
            my $num_label    = $4;
            my $scope        = $5;
            ($search_level eq "")
                or msg_warn(1, "$in_file:$line_n1 -> $out_file:$line_n2".
                ": Can't specify label's search level '$search_level' in GAS".
                ", dropping");
            ($scope eq "")
                or msg_warn(1, "$in_file:$line_n1 -> $out_file:$line_n2".
                ": Can't specify label's scope '$scope' in GAS".
                ", dropping");
            $line =~ s/$label/$num_label$direction/;
        }
    }

    # ------ Conversion: functions ------
    if ($line =~ m/^\s*(\w+)\s+PROC/) {
        my $func_name = $1;
        if ($opt_compatible) {
            push @symbols, $func_name;
            $line =~ s/$func_name\s+PROC(.*)$/.type $func_name, "function"$1\n$func_name:/i;
            $result{inc}++;
        }
        else {
            $line =~ s/$func_name\s+PROC/.func $func_name/i;
        }
    }
    elsif ($line =~ m/^(\s*)ENDP/i) {
        if ($opt_compatible) {
            my $func_name = pop @symbols;
            my $func_end  = ".L$func_name"."_end";
            $line =~ s/^(\s*)ENDP(.*)$/$func_end:$2\n$1.size $func_name, $func_end-$func_name/i;
            $result{inc}++;
        }
        else {
            $line =~ s/ENDP/.endfunc/i;
        }
    }

    # ------ Conversion: sections ------
    if ($line =~ m/^\s*AREA\s+\|*([.\w]+)\|*([^\/]*?)(\s*\/\/.*)?$/i) {
        msg_warn(0, "$in_file:$line_n1 -> $out_file:$line_n2".
            ": Not all AREA attributes are supported".
            ", need a manual check");

        my $sec_name = $1;
        my @options  = split /,/, $2;

        my $flags = "a";
        my $args  = "";
        foreach (@options) {
            $flags .= "x"   if (m/CODE/i);
            $flags .= "w"   if (m/READWRITE/i);
            $flags =~ s/a// if (m/NOALLOC/i);
            $flags .= "M"   if (m/MERGE/i);
            $flags .= "G"   if (m/GROUP/i);

            $args .= ", \@progbits" if (m/DATA/i);
            $args .= ", $1" if (m/MERGE\s*=\s*(\d+)/i);
            $args .= ", $1" if (m/GROUP\s*=\s*\|*(\w+)\|*/i);
        }

        $line =~ s/^(\s*)AREA[^\/]+[^\/\s]/$1.section $sec_name, "$flags"$args/i;

        my $indent = $1;
        if (m/ALIGN\s*=\s*(\d+)/i ~~ @options) {
            $line .= "$indent.balign " . (2**$1) . "\n";
            $result{inc}++;
        }
    }


    if ($line =~ m/^\s*$/) {
        # delete empty line
        $result{res} = "";
        $result{inc}--;
    }
    else {
        $result{res} = $line;
    }
}