#!/usr/bin/env bash

set -eu

docker-compose build -q; 
./run.sh psql-user --debug

echo -e "\n#####################\n"

./run.sh psql-connect --root

echo -e "\n#####################\n"

./run.sh psql-user --delete-user --remove-db

#END
