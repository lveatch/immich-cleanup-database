# immich-cleanup-database
This Perl script is to identify missing Immich files still found with in the Immich database.  This is meant to be independent of any Immich version and platform agnostic, other than tested on Immich running on docker and using only default libraries. This script must be placed in the ${UPLOAD_LOCATION}/backups.

External Library's are not supported as they should automatically keep the database clean.

!!! Please test on a non-production Immich installation before running on your productive environment.

## Overview
This script will identify orphand files by inspecting the built-in database backup file and create a new unzipped and zipped backup sql file which can then be used as a database restore removing all orphanded assets.

The only tables checked for missing files are the public.asset and public.asset_file. Missing asset id's and file name is written to missing.log file. Matching asset id's are then removed from all other tables.

A new backup sql file is written and then gzipped. You must manually perform the database restore in the Immich UI.

## Installing
Simply copy the Perl script to ${UPLOAD_LOCATION}/backups

## Executing
1. Ensure you have a recent backup of your database. Please note, that the database restore process will make a restore-point backup for you.
2. Once logged/ssh'd into your Immich docker host, execute the following command providing minimally the backup file name.
   - add <code>-backupPath /data/backups</code> if you have a different backup location.

> docker container exec -it immich_server bash -c  "perl  /data/backups/find.missing.files.pl  -backupFile immich-db-backup-20260210T020000-v2.3.1-pg14.18.sql.gz"

The newly created sql file and compressed file will append .orphanfix to their file names for clear identification.

Back in the Immich UI, perform a database restore.

## Sample output

<pre>docker container exec -it immich_server bash -c  "perl /data/backups/find.missing.files.pl -backupPath /data/backups -backupFile immich-db-backup-20260415T130000-v2.7.5-pg14.19.sql.gz"
   
        processing activity
        processing album
        processing album_asset
        processing album_asset_audit
        processing album_audit
        processing album_user
        processing album_user_audit
        processing api_key
        processing asset
        processing asset_audit
        processing asset_edit
        processing asset_edit_audit
        processing asset_exif
        processing asset_face
        processing asset_face_audit
        processing asset_file
        processing asset_job_status
        processing asset_metadata
        processing asset_metadata_audit
        processing asset_ocr
        processing audit
        processing face_search
        processing geodata_places
        processing kysely_migrations
        processing kysely_migrations_lock
        processing library
        processing memory
        processing memory_asset
        processing memory_asset_audit
        processing memory_audit
        processing migration_overrides
        processing migrations
        processing move_history
        processing naturalearth_countries
        processing notification
        processing ocr_search
        processing partner
        processing partner_audit
        processing person
        processing person_audit
        processing plugin
        processing plugin_action
        processing plugin_filter
        processing session
        processing session_sync_checkpoint
        processing shared_link
        processing shared_link_asset
        processing smart_search
        processing stack
        processing stack_audit
        processing system_metadata
        processing tag
        processing tag_asset
        processing tag_closure
        processing typeorm_metadata
        processing "user"
        processing user_audit
        processing user_metadata
        processing user_metadata_audit
        processing version_history
        processing workflow
        processing workflow_action
        processing workflow_filter


 missing assets = 1949

 compressing new backup file -> '/data/backups/immich-db-backup-20260415T130000-v2.7.5-pg14.19.sql.orphanfix.sql'
</pre>

## Backing out the change.
Simply perform another database restore using the backup manually taken before performing this procedure.
