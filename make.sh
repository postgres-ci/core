#!/bin/bash

VERSION="0.3"

echo "
\echo Use \"CREATE EXTENSION postgres_ci\" to load this file. \quit

set statement_timeout     = 0;
set client_encoding       = 'UTF8';
set client_min_messages   = warning;
set escape_string_warning = off;
set standard_conforming_strings = on;

" > "postgres_ci--$VERSION.sql"


FILES="src/schema.sql
src/packages.sql
src/pg_extension_config_dump.sql
src/functions/auth/*.sql
src/functions/build/*.sql
src/functions/project/*.sql
src/functions/hook/*.sql
src/functions/password/*.sql
src/functions/notification/*.sql
src/functions/users/*.sql"

for file in $FILES
do

echo "

/* source file: $file */
" >> "postgres_ci--$VERSION.sql"

	cat $file >> "postgres_ci--$VERSION.sql"
done

