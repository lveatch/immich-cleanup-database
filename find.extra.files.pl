#!/usr/bin/perl

use Getopt::Long;
use Data::Dumper;
use File::Find;

my $libraryPath = '/data';
my $backupPath = '/data/backups';
my $backupFile = '';

my $result = GetOptions (
                           "libraryPath=s" => \$libraryPath,
                           "backupPath=s" => \$backupPath,
                           "backupFile=s" => \$backupFile,
                        ) or die("Error in command line arguments\n");



our %immichFile;
our %missingFile;
my @tableColumnNames;
my $idCheck = 'assetId';
my $table = '';

my $sqlBackup = "$backupPath/$backupFile";

open (Backup, "zcat --stdout $sqlBackup | ") or die "cannot open $sqlBackup file, $!\n";

while (my $line = <Backup>) {
   chomp $line;

   if ($line =~ m/^COPY / .. $line =~ m/^--/) { # only process COPY data rows
      next if ($line eq '');
      next if ($line =~ m/^\\./);
      next if ($line =~ m/^--/);

      # COPY public.activity (id, "createdAt", "updatedAt", "albumId", "userId", "assetId", comment, "isLiked", "updateId") FROM stdin;
      if ($line =~ m/^COPY public\.(.+?) \((.+)\) FROM/) {
         $table = $1;
         print "\tprocessing $table\n";

         (my $columnText = $2) =~ s/"//g;
         $columnText =~ s/\s//g;
         $columnText =~ s/originalPath/path/;
         $columnText =~ s/thumbnailPath/path/;
         @tableColumnNames = split(/,/, $columnText);

         $idCheck = '';
         if ($line =~ m/"assetId",/) {
            $idCheck = 'assetId';
         } elsif ($line =~ m/id,/) {
            $idCheck = 'id';
         }
         next;
      }

      next if ($idCheck eq '');

      my %tableFields;
      @tableFields{@tableColumnNames} = split(/\t/, $line);

      if ($table eq 'asset') {
         $immichFile{ $tableFields{'path'} } = 1;
      }

   }

}

close Backup;

our %realFile;
our $missingAssets = 0;
print "\n\ncollecting files located at $libraryPath/library .... this may take awhile ....\n\n";
find(\&wanted, "$libraryPath/library");

print "\ncollecting files located at $libraryPath/upload .... this may take awhile ....\n\n";
find(\&wanted, "$libraryPath/upload");


print "\n\nextra files = $missingAssets\n\n";

if ($missingAssets == 0) {
   print "\nexiting. no extra files found.\n\n";
   exit 0;
}




exit 0;



sub wanted {
   # $_ contains the current filename
   # $File::Find::dir contains the current directory path
   # $File::Find::name contains the full path
   if (-f "$_") {
   next if ($_ =~ m#\.xmp$#i);
   next if ($_ =~ m#^\.#i);

      # print "\tInfo: Found text file: $File::Find::name  ($_)\n";
      unless (exists $immichFile{ $File::Find::name } ) {
         print "Warning: extra file $File::Find::name\n";
         $missingAssets++;
      }

   }
}
