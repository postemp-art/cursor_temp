#!/usr/bin/perl -w

use strict;
use warnings;

use lib '/home/postemp/cursor_temp';

use FILE_TOOLS qw(get_file_stat);

my $filename = '/home/postemp/Documents/qigong_20.12.2014_mpeg4.avi';

my $stat = FILE_TOOLS::get_file_stat({
    filename    => $filename,
    suffix_mask => qr{\.[^\.]+$},   # опционально
});

if ( $stat->{errno} ) {
    die "Ошибка при получении статистики файла: $stat->{errstr}\n";
}

my $size_bytes = $stat->{size};     # размер в байтах
my $size_mb    = $size_bytes / (1024 * 1024);

printf "Файл: %s\n",  $stat->{shortname};
printf "Путь: %s\n",  $stat->{path};
printf "Размер: %.2f Мб\n", $size_mb;
printf "mtime: %s\n", $stat->{str_mtime};

if ( $size_mb > 20 ) {
    print "Файл больше 20 Мб, надо архивировать.\n";
} else {
    print "Файл не превышает 20 Мб, можно не трогать.\n";
}