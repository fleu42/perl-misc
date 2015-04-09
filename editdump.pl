#!/usr/bin/env perl
#
# Edit a mysql dump to remove DROP and CREATE
# statements.
# Also change the INSERT to INSERT IGNORE.
#
# Usage example:
#
# cat mydump.sql | ./editdump.pl | mysql -B mybase
#
use strict;
use warnings;

my @trash;

while (<>) {
    s/\b(INSERT)\b/INSERT IGNORE/g;
    next if /^DROP/;
    if (/^CREATE/) {
        push @trash, $_;
        while (<>) {
            last if /^$/; 
            push @trash, $_;
        }
    }
    print (STDOUT $_);
}
