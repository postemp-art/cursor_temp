package PROC;

=head1 NAME

PROC.pm - run shell commands and capture combined output

=head1 UUID

UUID: a1c2e3f4-d5b6-7890-abcd-ef1234567890

=cut

use strict;
use warnings;

use IPC::Open3 qw(open3);
use Symbol qw(gensym);

our $VERSION = 1.00;

=head1 SUBROUTINES

=head2 ipc_open3

  my @lines = PROC::ipc_open3($shell_command);

Runs I<$shell_command> via F</bin/sh -c>. Returns a list of lines (without
trailing newlines) from merged standard output and standard error, in that
order. On failure to start the process, returns a single line describing the
error.

=cut

sub ipc_open3 {
    my ($cmd) = @_;

    if ( !defined $cmd || $cmd eq '' ) {
        return ('PROC::ipc_open3: empty command');
    }

    my ( $in_fh, $out_fh, $err_fh ) = ( gensym, gensym, gensym );

    my $pid = eval {
        open3( $in_fh, $out_fh, $err_fh, '/bin/sh', '-c', $cmd );
    };

    if ( !$pid ) {
        my $err = $@ || 'unknown error';
        chomp $err;
        return ("PROC::ipc_open3: $err");
    }

    close $in_fh;

    local $/;
    my $stdout = readline $out_fh;
    my $stderr = readline $err_fh;
    close $out_fh;
    close $err_fh;

    waitpid $pid, 0;

    $stdout = defined $stdout ? $stdout : '';
    $stderr = defined $stderr ? $stderr : '';

    return _split_lines( $stdout . $stderr );
}

sub _split_lines {
    my ($text) = @_;
    return if $text eq '';

    my @lines;
    open my $fh, '<', \$text or return ('PROC::ipc_open3: cannot open scalar');
    while ( my $line = <$fh> ) {
        chomp $line;
        push @lines, $line;
    }
    close $fh;
    return @lines;
}

1;
