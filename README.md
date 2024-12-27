# db_sync

Script to backup and restore postgres dbs.

To add a new source, add a file to the `./sources` directory following the format in `./sources/example_source`

The `modify` variable in the source can be set to `false` to ensure that the source is read only and not to be modified.

Backups are stored in `./backups`

The following arguments can be passed to the script.
- s: Source
- sd: Source database
- t: Target source
- td: Target source database
- to: Target source owner role

For example the below command will restore backup from database `db1` in source `s1` into database `db2` in source `s2` with the role `postgres` as the owner.
```bash
bash db_sync.sh --s s1 --sd db1 --t s2 --td db2 --to postgres
```
