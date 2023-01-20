#!/usr/bin/env bash

####
#Edit data below:
###

ORIGINAL_DB_URL=db.original_project_ref.supabase.co
REPLICA_DB_URL=db.replica_project_ref.supabase.co
ORIGINAL_DB_PASS=secret_password_here
REPLICA_DB_PASS=secret_new_password_here

####
#Script:
###

## Compability script:
# Default case for Linux sed, just use "-i"
sedi=(-i)
case "$(uname)" in
  # For macOS, use two parameters
  Darwin*) sedi=(-i "")
esac

####
#Schema download:
###

PGPASSWORD="$ORIGINAL_DB_PASS" pg_dump -d postgres -U postgres \
  --clean \
  --if-exists \
  --schema-only \
  --quote-all-identifiers \
  --exclude-schema 'extensions|graphql|tiger|storage|graphql_public|net|pgbouncer|pgsodium|pgsodium_masks|realtime|supabase_functions|pg_toast|pg_catalog|pg_*|information_schema' \
  --schema '*' \
  -h "$ORIGINAL_DB_URL" > dump.sql

sed "${sedi[@]}" -e 's/^DROP SCHEMA IF EXISTS "auth";$/-- DROP SCHEMA IF EXISTS "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/' dump.sql

####
#Schema push:
###

PGPASSWORD="$REPLICA_DB_PASS" psql -d postgres -U postgres \
  --variable ON_ERROR_STOP=1 \
  --file dump.sql \
  -h "$REPLICA_DB_URL" -p 6543
  
####
#Creating a list of tables:
###

grep -i "create table" dump.sql > list_of_tables.txt
sed "${sedi[@]}" -e 's/CREATE TABLE //g'  list_of_tables.txt
sed "${sedi[@]}" -e's/ (//g' list_of_tables.txt

####
#Create publication for each table:
#Note: for all tables requires superuser. 
###

cat yourdomainlist | xargs -L1 PGPASSWORD="$ORIGINAL_DB_PASS" psql -d postgres -U postgres \
  -c 'CREATE PUBLICATION my_publication FOR TABLE ${1};' \
  -h "$ORIGINAL_DB_URL" -p 6543

####
#Subscribe to publication:
###

PGPASSWORD="$REPLICA_DB_PASS" psql -d postgres -U postgres \
  -c 'CREATE SUBSCRIPTION my_subscription CONNECTION $$postgresql://postgres:${ORIGINAL_DB_PASS}@${ORIGINAL_DB_URL}:5432/postgres$$ PUBLICATION my_publication;' \
  -h "$REPLICA_DB_URL" -p 6543
