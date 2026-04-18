#!/usr/bin/perl

use Getopt::Long;
use Data::Dumper;

my $backupPath = '/data/backups';
my $backupFile = '';
my $newBackupFile = '';
my $missingFile = 'missing.log';

my $result = GetOptions (
                           "backupPath=s" => \$backupPath,
                           "backupFile=s" => \$backupFile,
                           "newBackupFile=s" => \$newBackupFile,
                           "missingFile=s" => \$missingFile,
                        ) or die("Error in command line arguments\n");



my %missingId;
my @tableColumnNames;
my $idCheck = 'assetId';
my $table = '';

my $sqlBackup = "$backupPath/$backupFile";
if ($newBackupFile eq '') {
   ($newBackupFile = $backupFile) =~ s/\.gz$/.orphanfix.sql/;
}

open (Missing, '>', "$backupPath/$missingFile") or die "cannot open $backupPath/$missingFile for write, $!\n";
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
         next unless ($tableFields{'deviceId'} eq 'WEB');

         unless (-e "$tableFields{'path'}") {
            next if (exists $missingId{ $tableFields{$idCheck} });
            $missingId{ $tableFields{$idCheck} } = 1;
            print Missing "$idCheck\t$tableFields{$idCheck}\t$tableFields{'path'}\t$table\n";
         }

      } elsif ($table eq 'person') {
         unless (-e "$tableFields{'path'}") {
            next if (exists $missingId{ $tableFields{$idCheck} });
            $missingId{ $tableFields{$idCheck} } = 1;
            print Missing "$idCheck\t$tableFields{$idCheck}\t$tableFields{'path'}\t$table\n";
         }

      }

   }

}

close Backup;

print "\n\nlooking for foreign keys and related table columns\n";
findRelatedIds();
print Dumper(%missingId);

my $missingAssets = keys %missingId;
print "\n\nmissing assets = $missingAssets\n\n";

if ($missingAssets == 0) {
   print "\nexiting. no missing assets found.\n\n";
   exit 0;
}



# we have data to filter
filterTables();

exit 0;



sub findRelatedIds
{
   open (Missing, '>>', "$backupPath/$missingFile") or die "cannot open $backupPath/$missingFile for write, $!\n";
   open (Backup, "zcat --stdout $sqlBackup | ") or die "cannot open $sqlBackup file, $!\n";
   my @idCheck = ();

   while (my $line = <Backup>) {
      chomp $line;

      if ($line =~ m/^COPY / .. $line =~ m/^--/) { # only process COPY data rows
         next if ($line eq '');
         next if ($line =~ m/^\\./);
         next if ($line =~ m/^--/);

         # COPY public.activity (id, "createdAt", "updatedAt", "albumId", "userId", "assetId", comment, "isLiked", "updateId") FROM stdin;
         if ($line =~ m/^COPY public\.(.+?) \((.+)\) FROM/) {
            $table = $1;
            print "\tcrossrefferencing $table\n";

            (my $columnText = $2) =~ s/"//g;
            $columnText =~ s/\s//g;
            $columnText =~ s/originalPath/path/;
            @tableColumnNames = split(/,/, $columnText);

            @idCheck = ();
            if ($line =~ m/"albumThumbnailAssetId",/) {
               push @idCheck, 'albumThumbnailAssetId';
            }

            if ($line =~ m/"assetId",/) {
               push @idCheck, 'assetId';
            }

            if ($line =~ m/id,/) {
               push @idCheck, 'id';
            }

            if ($line =~ m/"faceId",/) {
               push @idCheck, 'faceId';
            }

            if ($line =~ m/"faceAssetId",/) {
               push @idCheck, 'faceAssetId';
            }

            next;
         }

         if (scalar(@idCheck) == 0) {
            next;
         } else {
            my $lineSkippedRc = checkLine($table, \@idCheck, $line, 'findRelatedIds');
         }

      }

   }

   close Backup;

}



sub filterTables {

   open (NewBackupFile, '>', "$backupPath/$newBackupFile") or die "cannot open $backupPath/$newBackupFile for write, $!\n";

   open (Backup, "zcat --stdout $sqlBackup | ") or die "cannot open $sqlBackup file, $!\n";
   my @idCheck = ();

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
            @tableColumnNames = split(/,/, $columnText);

            @idCheck = ();
            if ($line =~ m/"albumThumbnailAssetId",/) {
               push @idCheck, 'albumThumbnailAssetId';
            }

            if ($line =~ m/"assetId",/) {
               push @idCheck, 'assetId';
            }

            if ($line =~ m/id,/) {
               push @idCheck, 'id';
            }

            if ($line =~ m/"faceId",/) {
               push @idCheck, 'faceId';
            }

            if ($line =~ m/"faceAssetId",/) {
               push @idCheck, 'faceAssetId';
            }

            next;
         }

         if (scalar(@idCheck) == 0) {
            print NewBackupFile "$line\n";
            next;
         } else {
            my $lineSkippedRc = checkLine($table, \@idCheck, $line, 'filterTables');
            if ($lineSkippedRc == 0) {
               print NewBackupFile "$line\n";
               next;
            }
         }


      } else {
         print NewBackupFile "$line\n";
      }

   }

   close Backup;
   close Missing;
   close NewBackupFile;

}


sub checkLine
{
   my ($table, $idCheck_ref, $lineIn, $caller) = @_;

   my %tableFields;
   @tableFields{@tableColumnNames} = split(/\t/, $lineIn);
   my $skipped = 0;

   foreach my $id (@$idCheck_ref) {

      if (exists $missingId{ $tableFields{$id} }) {

         if ($id eq 'albumThumbnailAssetId') {
            print "\t\tchanged $id ($tableFields{$id}) to null\n";

            $lineIn =~ s/$tableFields{$id}/\\N/;
            print NewBackupFile "$lineIn\n" if ($caller eq 'filterTables');
            $skipped++;
         }

         if ($id eq 'id') {
            $skipped++;
            if (exists $tableFields{'assetId'}) {
               $missingId{ $tableFields{'assetId'} } = 1;
               print Missing "$id\t$tableFields{$id}\t$tableFields{'assetId'}\t$table\n" if ($caller eq 'findRelatedIds');

            }
         }

         if ($id eq 'assetId') {
            $skipped++;
            if (exists $tableFields{'id'}) {
               $missingId{ $tableFields{'id'} } = 1;
               print Missing "$id\t$tableFields{$id}\t$tableFields{'id'}\t$table\n" if ($caller eq 'findRelatedIds');
            }
         }

         $skipped++;

      }


   }

   return $skipped;

}
