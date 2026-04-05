package FILE_TOOLS;

=head1 NAME

FILE_TOOLS.pm - perl module work with files

=head1 UUID

UUID: dfalb19e-d2cb-4a1f-b691-765951a34e66

=cut

use strict;
use warnings;
use File::Basename;

BEGIN {
    require Exporter;

    our $VERSION = 1.00;
    our @ISA     = qw(Exporter);
    our @EXPORT  = qw();
    our @EXPORT_OK = qw(
        get_file_stat
    );
}

=head1 SUBROUTINES \I<get_file_stat> - get file statistics

=cut
sub get_file_stat {
    my $params      = shift;
    my $fullname    = $params->{filename};
    my $suffix_mask = $params->{suffix_mask};

    my $result = {
        errno  => 0,
        errstr => ''
    };

    my $time_str = sub{
        my ( $time ) = @_;
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( $time );
        return sprintf('%04d.%02d.%02d %02d:%02d:%02d', $year+1900, $mon+1, $mday, $hour, $min, $sec );
    };

    while(1)
    {
        if (!-e $fullname ) {
            $result->{errno}  = 0;
            $result->{errstr} = "Error: file: [$fullname] not found.";
            last;
        }

        my ( $dev
           , $ino
           , $mode
           , $nlink
           , $uid
           , $gid
           , $rdev
           , $size
           , $atime
           , $mtime
           , $ctime
           , $blksize
           , $blocks
           ) = stat $fullname;

        $result->{dev}     = $dev;
        $result->{ino}     = $ino;
        $result->{mode}    = $mode;
        $result->{nlink}   = $nlink;
        $result->{uid}     = $uid;
        $result->{gid}     = $gid;
        $result->{rdev}    = $rdev;
        $result->{size}    = $size;
        $result->{atime}   = $atime;
        $result->{mtime}   = $mtime;
        $result->{ctime}   = $ctime;
        $result->{blksize} = $blksize;
        $result->{blocks}  = $blocks;

        $result->{str_gid} = getgrgid $gid;
        $result->{str_uid} = getpwuid $uid;

        $result->{str_atime} = $time_str->( $atime );
        $result->{str_mtime} = $time_str->( $mtime );
        $result->{str_ctime} = $time_str->( $ctime );

        my $shortname = $fullname;
        $shortname =~ s|^.*[/\\]||ix;
        $result->{shortname} = $shortname;

        my($shortname_fp, $dirs, $suffix) = fileparse( $fullname );
        $result->{shortname} = $shortname_fp;
        $result->{path}      = $dirs;
        $result->{suffix}    = $suffix;
        $result->{basename}  = fileparse( $fullname, $suffix_mask );

        last;
    }

    return $result;
}

1;