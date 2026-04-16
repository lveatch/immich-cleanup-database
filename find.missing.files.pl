#!/usr/bin/perl

use Getopt::Long;
use Data::Dumper;

my $backupPath = '/data/backups';
my $backupFile = '';
my $newBackupFile = '';
my $missingFile = 'missing.log';
my $test;

my $result = GetOptions (
                           "backupPath=s" => \$backupPath,
                           "backupFile=s" => \$backupFile,
                           "newBackupFile=s" => \$newBackupFile,
                           "missingFile=s" => \$missingFile,
                           "test"      => \$test,
                        ) or die("Error in command line arguments\n");


open (Missing, '>', "$backupPath/$missingFile") or die "cannot open $backupPath/$missingFile for write, $!\n";

my %missingId;
my @tableColumnNames;
my $idCheck = 'assetId';
my $table = '';

my $sqlBackup = "$backupPath/$backupFile";
if ($newBackupFile eq '') {
   ($newBackupFile = $backupFile) =~ s/\.gz$/.orphanfix.sql/;
}

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

      if ($table eq 'asset_file') {
         my %tableFields;
         @tableFields{@tableColumnNames} = split(/\t/, $line);

         next if ($tableFields{'type'} eq 'sidecar');

         unless (-e "$tableFields{'path'}") {
            next if (exists $missingId{ $tableFields{$idCheck} });
            $missingId{ $tableFields{$idCheck} } = 1;
            print Missing "$idCheck\t$tableFields{$idCheck}\t$tableFields{'path'}\t$table\n";
         }

      } elsif ($table eq 'asset') {
         my %tableFields;
         @tableFields{@tableColumnNames} = split(/\t/, $line);

         #next if ($tableFields{'deviceId'} eq 'Library Import');
         next unless ($tableFields{'deviceId'} eq 'WEB');

         unless (-e "$tableFields{'path'}") {
            next if (exists $missingId{ $tableFields{$idCheck} });
            $missingId{ $tableFields{$idCheck} } = 1;
            print Missing "$idCheck\t$tableFields{$idCheck}\t$tableFields{'path'}\t$table\n";
         }

      }

   }

}

close Backup;

my $missingAssets = keys %missingId;
print "\n\nmissing assets = $missingAssets\n\n";

if ($missingAssets == 0) {
   print "\nexiting. no missing assets found.\n\n";
   exit 0;
}

open (NewBackupFile, '>', "$backupPath/$newBackupFile") or die "cannot open $backupPath/$newBackupFile for write, $!\n";

open (Backup, "zcat --stdout $sqlBackup | ") or die "cannot open $sqlBackup file, $!\n";
$idCheck = '';

while (my $line = <Backup>) {
   chomp $line;

   if ($line =~ m/^COPY / .. $line =~ m/^--/) { # only process COPY data rows

      if ($line =~ m/^COPY public\.(.+?) \((.+)\) FROM/) {
         print NewBackupFile "$line\n";
         $table = $1;
         print "\tfiltering $table\n";

         (my $columnText = $2) =~ s/"//g;
         $columnText =~ s/\s//g;
         $columnText =~ s/originalPath/path/;
         #print "\t\tcolumn text = $columnText\n";
         @tableColumnNames = split(/,/, $columnText);

         $idCheck = '';
         if ($line =~ m/"albumThumbnailAssetId",/) {
            $idCheck = 'albumThumbnailAssetId';
         } elsif ($line =~ m/"assetId",/) {
               $idCheck = 'assetId';
         } elsif ($line =~ m/id,/) {
            $idCheck = 'id';
         }
         #print "\t\t\tid check is $idCheck\n";
         next;
      }

      if ($idCheck eq '') {
         print NewBackupFile "$line\n";
         next;
      }

      my %tableFields;
      @tableFields{@tableColumnNames} = split(/\t/, $line);

      if (exists $missingId{ $tableFields{$idCheck} }) {
         if ($idCheck eq 'albumThumbnailAssetId') {
            $line =~ s/$tableFields{$idCheck}/\\N/;
            print NewBackupFile "$line\n";
         }
         next;
      } else {
         print NewBackupFile "$line\n";
      }

   } else {
      print NewBackupFile "$line\n";
   }

}

close Backup;
close Missing;
close NewBackupFile;

exit 0 if ($test);

print "\n\ncompressing new backup file -> '$backupPath/$newBackupFile'\n";

open (Zip, "gzip --keep '$backupPath/$newBackupFile' | ") or die "cannot open $newBackupFile file, $!\n";
while (my $line = <Zip>) {
   print $line;
}
close Zip;

exit 0;
