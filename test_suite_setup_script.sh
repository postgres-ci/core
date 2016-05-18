#!/bin/sh

env PGPASSWORD=$POSTGRES_PASSWORD psql -v ON_ERROR_STOP=1 -q -U $POSTGRES_USER -d $TEST_DATABASE <<-SQL
	CREATE SCHEMA postgres_ci;
	CREATE EXTENSION pgcrypto;
	CREATE EXTENSION pg_trgm;
SQL

cat postgres_ci--0.0.1.sql | sed '/CREATE EXTENSION postgres_ci/d' > dump.sql

env PGPASSWORD=$POSTGRES_PASSWORD psql -v ON_ERROR_STOP=1 -q -U $POSTGRES_USER -d $TEST_DATABASE -f dump.sql

echo "Grant privileges to Tester"

env PGPASSWORD=$POSTGRES_PASSWORD psql -v ON_ERROR_STOP=1 -q -U $POSTGRES_USER -d $TEST_DATABASE -f tests/grants.sql

echo "Create test functions"

cd tests && env PGPASSWORD=$TEST_PASSWORD psql -v ON_ERROR_STOP=1 -q -U $TEST_USERNAME -d $TEST_DATABASE -f tests.sql