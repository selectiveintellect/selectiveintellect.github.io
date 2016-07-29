#!/usr/bin/env perl
use strict; 
use warnings;
use 5.10.0;
use feature 'say';
use Pegex;
use XXX;

my $grammar = <<EOF;
%grammar etchosts
%version 0.01

hosts: host | blanks | comments
comments: /- HASH ANY* EOL/
blanks: /- EOL/
host: ip - aliases /- EOL?/
ip: ipv4 | ipv6
aliases: alias+
alias: - /( ALNUM (: WORD | DOT | DASH )*)/ -

ipv4: /((: DIGIT{1,3} DOT ){3} DIGIT{1,3} )/
ipv6: /((: HEX* COLON{1,2} HEX* )+ )/

EOF

my @rows = ();
while (<>) {
    push @rows, pegex($grammar)->parse($_);
}
YYY \@rows;
