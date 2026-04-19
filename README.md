# immich-cleanup-database
This Perl script is to identify missing Immich files still found with in the Immich database.  This is meant to be independent of any Immich version and platform agnostic, other than tested on Immich running on docker and using only default libraries. This script must be placed in the ${UPLOAD_LOCATION}/backups.

External Library's are not supported as they should automatically keep the database clean.

> [!WARNING]
> Please test on a non-production Immich installation before running on your productive environment.

## Overview
This script will identify orphand files by inspecting the built-in database backup file and create a new unzipped and zipped backup sql file which can then be used as a database restore removing all orphanded assets.

The only tables checked for missing files are the public.asset and public.asset_file. Missing asset id's and file name is written to missing.log file. Matching asset id's are then removed from all other tables.

A new backup sql file is written and then gzipped. You must manually perform the database restore in the Immich UI.

## Installing
Simply copy the Perl script to ${UPLOAD_LOCATION}/backups

## Executing
1. Ensure you have a recent backup of your database. Please note, that the database restore process will make a restore-point backup for you.
2. Once logged/ssh'd into your Immich docker host, execute the following command providing minimally the backup file name.
   * `docker container exec -it immich_server bash -c  "perl  /data/backups/find.missing.files.pl  -backupFile immich-db-backup-20260210T020000-v2.3.1-pg14.18.sql.gz"`
   * add `-backupPath /data/backups` if you have a different backup location.

The newly created sql file will append .orphanfix to their file names for clear identification.

Back in the Immich UI, perform a [database restore](https://docs.immich.app/administration/backup-and-restore/#restoring-a-database-backup) - no need to gzip the sql file.

## Sample output

```
docker container exec -it immich_server bash -c  "perl /data/backups/find.missing.files.pl -backupPath /data/backups -backupFile immich-db-backup-20260415T130000-v2.7.5-pg14.19.sql.gz"
   
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


looking for foreign keys and related table columns
        crossrefferencing activity
        crossrefferencing album
                changed albumThumbnailAssetId (0d87a138-7d4e-419a-847e-9de5fe78121f) to null
        crossrefferencing album_asset
        crossrefferencing album_asset_audit
        crossrefferencing album_audit
        crossrefferencing album_user
        crossrefferencing album_user_audit
        crossrefferencing api_key
        crossrefferencing asset
        crossrefferencing asset_audit
        crossrefferencing asset_edit
        crossrefferencing asset_edit_audit
        crossrefferencing asset_exif
        crossrefferencing asset_face
        crossrefferencing asset_face_audit
        crossrefferencing asset_file
        crossrefferencing asset_job_status
        crossrefferencing asset_metadata
        crossrefferencing asset_metadata_audit
        crossrefferencing asset_ocr
        crossrefferencing audit
        crossrefferencing face_search
        crossrefferencing geodata_places
        crossrefferencing kysely_migrations
        crossrefferencing kysely_migrations_lock
        crossrefferencing library
        crossrefferencing memory
        crossrefferencing memory_asset
        crossrefferencing memory_asset_audit
        crossrefferencing memory_audit
        crossrefferencing migration_overrides
        crossrefferencing migrations
        crossrefferencing move_history
        crossrefferencing naturalearth_countries
        crossrefferencing notification
        crossrefferencing ocr_search
        crossrefferencing partner
        crossrefferencing partner_audit
        crossrefferencing person
        crossrefferencing person_audit
        crossrefferencing plugin
        crossrefferencing plugin_action
        crossrefferencing plugin_filter
        crossrefferencing session
        crossrefferencing session_sync_checkpoint
        crossrefferencing shared_link
        crossrefferencing shared_link_asset
        crossrefferencing smart_search
        crossrefferencing stack
        crossrefferencing stack_audit
        crossrefferencing system_metadata
        crossrefferencing tag
        crossrefferencing tag_asset
        crossrefferencing tag_closure
        crossrefferencing typeorm_metadata
        crossrefferencing "user"
        crossrefferencing user_audit
        crossrefferencing user_metadata
        crossrefferencing user_metadata_audit
        crossrefferencing version_history
        crossrefferencing workflow
        crossrefferencing workflow_action
        crossrefferencing workflow_filter
missing assets = 16

        filtering activity
        filtering album
                changed albumThumbnailAssetId (0d87a138-7d4e-419a-847e-9de5fe78121f) to null
        filtering album_asset
        filtering album_asset_audit
        filtering album_audit
        filtering album_user
        filtering album_user_audit
        filtering api_key
        filtering asset
        filtering asset_audit
        filtering asset_edit
        filtering asset_edit_audit
        filtering asset_exif
        filtering asset_face
        filtering asset_face_audit
        filtering asset_file
        filtering asset_job_status
        filtering asset_metadata
        filtering asset_metadata_audit
        filtering asset_ocr
        filtering audit
        filtering face_search
        filtering geodata_places
        filtering kysely_migrations
        filtering kysely_migrations_lock
        filtering library
        filtering memory
        filtering memory_asset
        filtering memory_asset_audit
        filtering memory_audit
        filtering migration_overrides
        filtering migrations
        filtering move_history
        filtering naturalearth_countries
        filtering notification
        filtering ocr_search
        filtering partner
        filtering partner_audit
        filtering person
        filtering person_audit
        filtering plugin
        filtering plugin_action
        filtering plugin_filter
        filtering session
        filtering session_sync_checkpoint
        filtering shared_link
        filtering shared_link_asset
        filtering smart_search
        filtering stack
        filtering stack_audit
        filtering system_metadata
        filtering tag
        filtering tag_asset
        filtering tag_closure
        filtering typeorm_metadata
        filtering "user"
        filtering user_audit
        filtering user_metadata
        filtering user_metadata_audit
        filtering version_history
        filtering workflow
        filtering workflow_action
        filtering workflow_filter

```

## Backing out the change.
Simply perform another database restore using the backup manually taken before performing this procedure.
