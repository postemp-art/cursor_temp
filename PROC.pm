package PROC;

use strict;
use warnings;
use IPC::Open3 'open3';
use IO::Select;

BEGIN {
    require Exporter;

    our $VERSION = 1.00;

    use base qw(Exporter);

    our @EXPORT = qw(i_am_not_alone already_running save_lock_file );

    our @EXPORT_OK = qw(
        ipc_open3

    );
}

sub ipc_open3 {
    my $command = shift;

    if ( !defined $command || $command eq '' ) {
        return ('PROC::ipc_open3: empty command');
    }

    my @out;
    my ( $wtr, $rdr, $err );

    my $pid = open3( $wtr, $rdr, $err, $command );
    close $wtr;

    my $sel = IO::Select->new( $rdr, $err );

    while ( $sel->count ) {
        foreach my $fh ( $sel->can_read ) {
            my $line = <$fh>;
            if ( !defined $line ) {
                $sel->remove($fh);
                next;
            }
            chomp $line;
            $line =~ s/\n//gx;
            if ( $fh == $rdr ) {
                push @out, $line;
            }
            elsif ( $fh == $err ) {
                push @out, $line;
            }
            else {
                die "Shouldn't be here\n";
            }
        }
    }

    waitpid( $pid, 0 );

    return @out;
}

1;
