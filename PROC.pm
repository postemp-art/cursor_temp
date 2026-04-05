package PROC;

use strict;
use warnings;
use IPC::Open3 'open3';
use IO::Select;

BEGIN {
    require Exporter;

    our $VERSION = 1.00;

    use base qw(Exporter);

    our @EXPORT_OK = qw(
        ipc_open3

    );
}


sub ipc_open3 {
    my $command = shift;

    my @out;
    my($wtr, $rdr, $err);

    my $pid = open3( $wtr, $rdr, $err, "$command" );
    waitpid( $pid, 0 );
    my $child_exit_status = $? >> 8;
    my $sel = IO::Select->new();
    $sel->add($rdr, $err);

    while( my @ready = $sel->can_read )
    {
        foreach my $fh (@ready)
        {
            my $line = <$fh>;
            if(not defined $line)
            {
                $sel->remove($fh);
                next;
            }
            chomp $line;
            $line =~ s/\n//gx;
            if(      $fh == $rdr ) { push @out, $line; }
            elsif(   $fh == $err ) { push @out, $line; }
            else                   { die "Shouldn't be here\n"; }
        }
    }
    return @out;
}

1;
