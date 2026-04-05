package FILE_TOOLS::ARCHIVE;

=head1 NAME

FILE_TOOLS::ARCHIVE.pm - archiving files

=head1 UUID

UUID: 0fb1br9e-d2cb-8a2f-b695-755af5aew73f

=cut

use strict;
use warnings;

# no critic (Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings);
no warnings 'utf8';
no warnings 'once';

use FILE_TOOLS;
use File::Basename;
use File::Spec;
use File::Path qw(make_path);
use Data::Dumper;
use PROC;

local $ENV{'LOCALE'} = 'us_EN.utf8';

BEGIN {
    require Exporter;

    # set the version for version checking
    our $VERSION = 1.00;

    # Inherit from Exporter to export functions and variables
    our @ISA = qw(Exporter);

    # Functions and variables which are exported by default
    our @EXPORT = qw(
        zip_separate
        zip_file
    );

    # Functions and variables which can be optionally exported
}

=head1 NAME

=cut


sub zip_file{
    my $params = shift;
    my $file_in     = $params->{file_in};
    my $dir_out     = $params->{dir_out};      

    my $result = {
        errno     => 0,
        errstr    => 'The file was zipped successfully',
        zip_parts => []
    };

    while (1)
    {
        # X. Input data checks
        if (!-e $file_in) {
            $result->{errno}  = 1;
            $result->{errstr} = "Input file not found: $file_in";
            last;
        }

        # X. If there is no such directory, make it.
        if (!-d $dir_out) {
            my $err;
            make_path($dir_out, { error => \$err });

            if ($err && @$err) {
                my ($path, $message) = %{ $err->[0] };
                $result->{errno}  = 2;
                $result->{errstr} = "Failed to create directory: $path. Error: $message";
                last;
            }
        }

        my $basename      = basename($file_in); # Getting only name from file, without dir
        my $zip_name      = $basename . ".archive";
        my $full_zip_path = File::Spec->catfile($dir_out, $zip_name);

        # X. Delete old zip archives if they exist
        if (opendir(my $DIR, $dir_out)) {
            my @files_to_delete = readdir($DIR);
            closedir($DIR);

            foreach my $file (@files_to_delete) {
                if ($file !~ /^$zip_name/) {
                    next;
                }
                unlink(File::Spec->catfile($dir_out, $file));
            }
        }
        else {
            $result->{errno}  = 3;
            $result->{errstr} = "Can't open $dir_out: $!";
            last;
        }

        # X. Archiving
        my $cmd = "zip -j $full_zip_path.zip $file_in";
        $result->{cmd} = $cmd;
        my @zip_output = PROC::ipc_open3($cmd);
        foreach my $line (@zip_output) {
            if ($line =~ /adding/x ) {
                $result->{errno}  = 0;
                $result->{errstr} = '';
                last;
            }
            $result->{errno}  = 4;
            $result->{errstr} = "ZIP error: " . Dumper( @zip_output );
        }


        # X. get file list
        my @checked_zip_list = glob(File::Spec->catfile($dir_out, $zip_name . '.z*'));

        # X. Sorting
        @checked_zip_list = sort @checked_zip_list;

        # X. Filling $result->{zip_parts}
        foreach my $full_path (@checked_zip_list) {
            chomp($full_path);

            # Pass clean strings
            if ($full_path =~ /^\s*$/) {
                next;
            }

            my $filename = basename($full_path);

            # Adding new hash into array
            push @{ $result->{zip_parts} }, {
                basename => $filename,
                fullpath => $full_path
            };
        }

        # X. Checking for emptiness
        if (! @{ $result->{zip_parts} }) {
            $result->{errno}  = 6;
            $result->{errstr} = 'Something wrong, zip has not produced any parts';
            last;
        }
        last;
    }
    return $result;
}    

sub zip_separate{
    my $params = shift;
    my $file_in     = $params->{file_in};
    my $zip_size_mb = $params->{zip_size_mb} || 20;  # File we need to archive with full path
    my $dir_out     = $params->{dir_out};            # Archive chunk size
                                                    # Directory where to put

    my $result = {
        errno     => 0,
        errstr    => 'it is ok',
        zip_list => []
    };

    while (1)
    {
        # X. Input data checks
        if (!-e $file_in) {
            $result->{errno}  = 1;
            $result->{errstr} = "Input file not found: $file_in";
            last;
        }

        # X. If there is no such directory, make it.
        if (!-d $dir_out) {
            my $err;
            make_path($dir_out, { error => \$err });

            if ($err && @$err) {
                my ($path, $message) = %{ $err->[0] };
                $result->{errno}  = 2;
                $result->{errstr} = "Failed to create directory: $path. Error: $message";
                last;
            }
        }

        my $basename      = basename($file_in); # Getting only name from file, without dir
        my $zip_name      = $basename . ".archive";
        my $full_zip_path = File::Spec->catfile($dir_out, $zip_name);

        # X. Delete old zip archives if they exist
        if (opendir(my $DIR, $dir_out)) {
            my @files_to_delete = readdir($DIR);
            closedir($DIR);

            foreach my $file (@files_to_delete) {
                if ($file !~ /^$zip_name/) {
                    next;
                }
                unlink(File::Spec->catfile($dir_out, $file));
            }
        }
        else {
            $result->{errno}  = 3;
            $result->{errstr} = "Can't open $dir_out: $!";
            last;
        }

        # X. Archiving
        my $cmd = "zip -s $zip_size_mb"."m"." -j $full_zip_path.zip $file_in";
        $result->{cmd} = $cmd;
        my @zip_output = PROC::ipc_open3($cmd);
        foreach my $line (@zip_output) {
            if ($line =~ /adding/x ) {
                $result->{errno}  = 0;
                $result->{errstr} = '';
                last;
            }
            $result->{errno}  = 4;
            $result->{errstr} = "ZIP error: " . Dumper( @zip_output );
        }

        # X. get file list
        my @checked_zip_list = glob(File::Spec->catfile($dir_out, $zip_name . '.z*'));

        # X. Sorting
        @checked_zip_list = sort @checked_zip_list;

        # X. Filling $result->{zip_parts}
        foreach my $full_path (@checked_zip_list) {
            chomp($full_path);

            # Pass clean strings
            if ($full_path =~ /^\s*$/) {
                next;
            }

            my $filename = basename($full_path);

            # Adding new hash into array
            push @{ $result->{zip_parts} }, {
                basename => $filename,
                fullpath => $full_path
            };
        }

        # X. Checking for emptiness
        if (! @{ $result->{zip_parts} }) {
            $result->{errno}  = 6;
            $result->{errstr} = 'Something wrong, zip has not produced any parts';
            last;
        }

        last;
    }

    return $result;
}

1;