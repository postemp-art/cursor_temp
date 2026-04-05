#!/usr/bin/env perl
use strict;
use warnings;


use lib '/home/postemp/cursor_temp';

use FILE_TOOLS::ARCHIVE qw(zip_separate);

my $file_in     = '/home/postemp/Downloads/cursor_1.7.33_amd64.deb';
my $zip_size_mb = 20;
my $dir_out     = '/home/postemp/Downloads/cursor_1.7.33_amd64.deb_zip_parts';

my $r = zip_separate({
    file_in     => $file_in,
    dir_out     => $dir_out,
    zip_size_mb => $zip_size_mb,
});

if ( $r->{errno} ) {
    die "zip_separate failed (errno=$r->{errno}): $r->{errstr}\n";
}

print "OK: $r->{errstr}\n";
print "Command: $r->{cmd}\n" if $r->{cmd};
print "Parts (" . scalar( @{ $r->{zip_parts} } ) . "):\n";
for my $p ( @{ $r->{zip_parts} } ) {
    print "  $p->{fullpath}\n";
}

exit 0;
