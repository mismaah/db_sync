#!/bin/bash

# get params
while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        declare $v="$2"
   fi
  shift
done

PS3="Select source: "
sources=`ls ./sources`
echo ""
if [[ $s ]]; then
    source=$s
else
    select source in $sources
    do
        echo "Selected source: $source"
        break
    done
fi
source ./sources/$source
source_pwd=$password
export PGPASSWORD=$source_pwd
db_string=postgresql://$user@$host:$port
echo $db_string

PS3="Select source db: "
source_dbs=$(psql --dbname=$db_string/postgres -t -c 'SELECT datname FROM pg_database;')

echo ""
if [[ $sd ]]; then
    source_db=$sd
else
    select source_db in $source_dbs
    do
        echo "Selected source db: $source_db"
        break
    done
fi

date=$(date +"%Y-%m-%dT%H-%M-%S")
file=./backups/$source/$source_db/$date.dump
mkdir -p "${file%/*}"
export PGPASSWORD=$source_pwd
pg_dump -Fc -v --dbname=$db_string/$source_db > $file
date=$(date +"%Y-%m-%dT%H:%M:%S")
echo $date
echo "$date Backed up $source_db in $source" >> sync.log

PS3="Select target: "

echo ""
if [[ $t ]]; then
    target=$t
else
    select target in $sources
    do
        echo "Selected target: $target"
        break
    done
fi

if [[ $td ]]; then
    target_db=$td
else
    target_db=$source_db
fi

source ./sources/$target
target_pwd=$password
export PGPASSWORD=$target_pwd
target_db_string=postgresql://$user@$host:$port
target_dbs=$(psql --dbname=$target_db_string/postgres -t -c 'SELECT datname FROM pg_database;')
if ! [[ $target_dbs == *"$target_db"* ]]; then
    echo "Database $target_db does not exist in $target"
    exit 100
fi
if [[ "$modify" == "false" ]]; then
    echo "Source $target is read only"
    exit 100
fi

echo "This will copy $source_db in $source into $target_db in $target"

read -p "Are you sure? (y/N)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    export PGPASSWORD=$target_pwd
    pg_restore -Fc -v --no-privileges --no-owner --role=$to --clean --dbname=$target_db_string/$target_db $file
    # pg_restore -Fc -v --clean --dbname=$target_db_string/$source_db $file
    date=$(date +"%Y-%m-%dT%H:%M:%S")
    echo "$date Restored backup from $source_db in $source into $target_db in $target" >> sync.log
fi
echo "Exiting"