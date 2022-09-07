# db_sync

Script to backup and restore postgres dbs.

To add a new source, add a file to the `./sources` directory following the format in `./sources/example_source`

The `modify` variable in the source can be set to `false` to ensure that the source is read only and not to be modified.

Backups are stored in `./backups`