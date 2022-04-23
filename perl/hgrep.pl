#!/usr/bin/env perl
# -*- Mode: cperl; cperl-indent-level:4; tab-width: 8; indent-tabs-mode: nil -*-
# -*- coding: utf-8 -*-
# vim: set tabstop=8 expandtab:

use strict; use warnings;
use feature qw(switch);
use OptArgs; # https://metacpan.org/dist/OptArgs/view/bin/optargs

my @grep_options = qw(-i);

for ( $ENV{'TERM'} ) {
    if ( $_ =~ /dumb/ ) { }
    default { push @grep_options, "--color=auto" }
}


# ref: https://metacpan.org/pod/OptArgs

## option parts ...
opt context =>
  ( isa => 'Num',
    alias => 'C',
    comment => 'print NUM lines of output context' );

opt nohead =>
  ( isa => 'Bool',
    alias => 'n',
    comment => 'DO NOT print head line' );

opt help =>
  ( isa => 'Bool',
    alias => 'h',
    comment => 'print a help message and exit',
    ishelp => 1 );

# argument parts ...
arg search =>
  ( isa => 'Str',
    required => 1,
    comment => 'string to search from file' );

arg file_name =>
  ( isa => 'Str',
    default => '-', # default input from stdin
    comment => 'file to scrab' );

my $opts = optargs;

if ( defined $opts->{'context'} and $opts->{'context'} > 0 ) {
    push @grep_options, '-C', $opts->{'context'};
}

my $fh;

if ( $opts->{'file_name'} ne '-' ) {
    open $fh, "<$opts->{file_name}",
      or die "Can't open `$opts->{file_name}'";
}
else {
    # http://perldoc.perl.org/functions/open.html
    open( $fh, "<&=", *STDIN );
}

if ( not $opts->{nohead} ) {
    my $head = <$fh>;
    # FIXME: colourising ....
    print "$head";
}

my $to_gh; # to grep handle
my $grep_pid = open( $to_gh, '|-' );

if ( not defined $grep_pid ) {
    die "Can't fork: $!";
}

if ( $grep_pid ) {
    while ( <$fh> ) { print $to_gh $_; }

    close $_ for $to_gh, $fh;
    waitpid $grep_pid, 0;
}
else {
    close $fh;
    exec 'grep', @grep_options, $opts->{'search'};
}

exit 0;
