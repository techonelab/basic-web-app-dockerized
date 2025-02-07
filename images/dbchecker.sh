#!/bin/bash

USER=$(echo $POSTGRES_USER)
PASSWORD=$(echo $POSTGRES_PASSWORD)
DATABASE=$(echo $POSTGRES_DB)

psql -h localhost -U $USER -d $DATABASE -p 5432 -c "\\conninfo" > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "Database connection successful!"
else
  echo "Database connection failed!"
  exit 1 
fi
