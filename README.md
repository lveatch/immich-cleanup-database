# immich-cleanup-database
This Perl script is to identify missing Immich files still found with in the Immich database.  This is meant to be independent of any Immich version and platform agnostic, other than tested on Immich running on docker and using oly default libraries. This script must be placed in the ${UPLOAD_LOCATION}/backups.

External Library's are not supported as they should automatically keep the database clean.

!!! Please test on a non-production Immich installation before running on your productive environment.

## Overview
This script will identify orphand files by inspecting the built-in database backup file and create a new unzipped and zipped backup sql file which can then be used as a database restore removing all orphanded assets.

The only tables checked for missing files are the public.asset and public.asset_file. Missing asset id's and file name is written to missing.log file. Matching asset id's are then removed from all other tables.

A new backup sql file is written and must be gzipped. You must manually perform the database restore in the Immich UI.

## Installing
Simply copy the Perl script to ${UPLOAD_LOCATION}/backups

## Executing
1. Make a new manual backup of your database.
2. Once logged/ssh'd into your Immich docker host, execute the following command providing minimally the backup file name.
   - add <code>-backupPath /data/backups</code> if you have a different backup location.

> docker container exec -it immich_server bash -c  "perl  /data/backups/find.missing.files.pl  -backupFile immich-db-backup-20260210T020000-v2.3.1-pg14.18.sql.gz"

The newly created sql file and compressed file will append .orphanfix to their file names for clear identification.

Back in the Immich UI, perform a database restore.

## Backing out the change.
Simply perform another database restore using the backup manually taken before performing this procedure.
