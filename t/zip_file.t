#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use FindBin;
use lib "$FindBin::Bin/..";

use FILE_TOOLS::ARCHIVE ();

BEGIN {
    if ( system('zip -v >/dev/null 2>&1') != 0 ) {
        plan skip_all => 'zip utility not available';
    }
}

sub _write_file {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die $!;
    print {$fh} $content // '';
    close $fh;
}

# --- success: cleanup of stale *.archive*, unrelated files, zip_parts, cmd ---

my $tmpdir = tempdir( 'zip_file_XXXXXX', TMPDIR => 1, CLEANUP => 0 );

my $input = File::Spec->catfile( $tmpdir, 'input.txt' );
_write_file( $input, "source\n" );

my $stale_archive = File::Spec->catfile( $tmpdir, 'input.txt.archive.stale.zip' );
_write_file( $stale_archive, "old archive chunk\n" );

my $other = File::Spec->catfile( $tmpdir, 'other_keep.txt' );
_write_file( $other, "do not delete\n" );

ok( -e $stale_archive, 'precondition: stale archive-like file exists' );
ok( -e $other,       'precondition: unrelated file exists' );

my $r = FILE_TOOLS::ARCHIVE::zip_file(
    {   file_in => $input,
        dir_out => $tmpdir,
    }
);

is( $r->{errno}, 0, 'zip_file success (errno)' )
    or diag("errstr=$r->{errstr}");

ok( !-e $stale_archive, 'file matching basename.archive* prefix removed' );
ok( -e $other,         'file not matching prefix left intact' );
ok( -e $input,         'input file still exists' );

like( $r->{cmd}, qr/\bzip\b.*\Q$input\E/s, 'result includes zip command with input path' );

ok( @{ $r->{zip_parts} } >= 1, 'zip_parts is non-empty' );
for my $p ( @{ $r->{zip_parts} } ) {
    ok( $p->{basename}, 'zip_part has basename' );
    ok( $p->{fullpath}, 'zip_part has fullpath' );
    ok( -e $p->{fullpath}, 'zip_part file exists on disk' );
    like( $p->{basename}, qr/^input\.txt\.archive\.z/i, 'zip part name matches archive prefix' );
}

# --- errno 1: missing input file ---

my $missing = File::Spec->catfile( $tmpdir, 'surely_absent_$$.txt' );
$r = FILE_TOOLS::ARCHIVE::zip_file(
    {   file_in => $missing,
        dir_out => $tmpdir,
    }
);
is( $r->{errno}, 1, 'missing file_in -> errno 1' );
like( $r->{errstr}, qr/Input file not found/, 'missing file_in -> errstr' );

# --- creates dir_out when it does not exist ---

my $parent = tempdir( 'zip_file_parent_XXXXXX', TMPDIR => 1, CLEANUP => 1 );
my $nested_out = File::Spec->catdir( $parent, 'nested', 'out' );
ok( !-d $nested_out, 'precondition: nested dir_out does not exist' );

my $input2 = File::Spec->catfile( $parent, 'data.bin' );
_write_file( $input2, 'x' x 100 );

$r = FILE_TOOLS::ARCHIVE::zip_file(
    {   file_in => $input2,
        dir_out => $nested_out,
    }
);
is( $r->{errno}, 0, 'zip_file with new dir_out succeeds' )
    or diag("errstr=$r->{errstr}");
ok( -d $nested_out, 'dir_out was created' );
ok( @{ $r->{zip_parts} } >= 1, 'nested dir_out: zip_parts non-empty' );

# --- errno 3: cannot opendir dir_out ---

my $locked = File::Spec->catdir( $parent, 'no_read_dir' );
mkdir $locked or die $!;
chmod 0000, $locked or die $!;

$r = FILE_TOOLS::ARCHIVE::zip_file(
    {   file_in => $input2,
        dir_out => $locked,
    }
);
chmod 0700, $locked or die $!;

is( $r->{errno}, 3, 'unreadable dir_out -> errno 3' );
like( $r->{errstr}, qr/Can't open/, 'unreadable dir_out -> errstr mentions opendir failure' );

done_testing();
