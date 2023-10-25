#!/bin/bash

PS3="Select source: "
sources=`ls ./sources`
echo ""
select source in $sources
do
    echo "Selected source: $source"
    break
done
source ./sources/$source
source_pwd=$password
export PGPASSWORD=$source_pwd
db_string=postgresql://$user@$host:$port
echo $db_string

PS3="Select source db: "
source_dbs=$(psql --dbname=$db_string/postgres -t -c 'SELECT datname FROM pg_database;')

echo ""
select source_db in $source_dbs
do
    echo "Selected source db: $source_db"
    break
done

date=$(date +"%Y-%m-%dT%H-%M-%S")
file=./backups/$source/$source_db/$date.dump
mkdir -p "${file%/*}"
export PGPASSWORD=$source_pwd
pg_dump -Fc -v --dbname=$db_string/$source_db > $file
date=$(date +"%Y-%m-%dT%H:%M:%S")
echo "$date Backed up $source_db in $source" >> sync.log

PS3="Select target: "

echo ""
select target in $sources
do
    echo "Selected target: $target"
    break
done
source ./sources/$target
target_pwd=$password
export PGPASSWORD=$target_pwd
target_db_string=postgresql://$user@$host:$port
target_dbs=$(psql --dbname=$target_db_string/postgres -t -c 'SELECT datname FROM pg_database;')
if ! [[ $target_dbs == *"$source_db"* ]]; then
    echo "Database $source_db does not exist in $target"
    exit 100
fi
if [[ "$modify" == "false" ]]; then
    echo "Source $target is read only"
    exit 100
fi

echo "This will copy $source_db in $source into $target"

read -p "Are you sure? (Y/n)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    export PGPASSWORD=$target_pwd
    pg_restore -Fc -v --no-privileges --no-owner --clean --dbname=$target_db_string/$source_db $file
    date=$(date +"%Y-%m-%dT%H:%M:%S")
    echo "$date Restored $source_db into $target" >> sync.log
fi
echo "Exiting"