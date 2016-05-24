#!/bin/sh

echo "Create database owner"

env PGPASSWORD=$POSTGRES_PASSWORD psql -q -v ON_ERROR_STOP=1 -U $POSTGRES_USER -d $TEST_DATABASE <<-SQL
	CREATE USER ci_owner WITH PASSWORD 'password' LOGIN;
	GRANT ALL PRIVILEGES ON DATABASE "$TEST_DATABASE" TO ci_owner;
SQL

echo "Done!"
echo "Create required extensions"
env PGPASSWORD=$POSTGRES_PASSWORD psql -v ON_ERROR_STOP=1 -q -U $POSTGRES_USER -d $TEST_DATABASE <<-SQL
	CREATE EXTENSION pgcrypto;
	CREATE EXTENSION pg_trgm;
SQL
echo "Done!"

env PGPASSWORD=password psql -q -v ON_ERROR_STOP=1 -U ci_owner -d $TEST_DATABASE <<-SQL
	CREATE SCHEMA postgres_ci;
SQL

cat postgres_ci--0.1.sql | sed '/CREATE EXTENSION postgres_ci/d' | sed '/pg_extension_config_dump/d' > dump.sql

env PGPASSWORD=password psql -q -v ON_ERROR_STOP=1 -U ci_owner -d $TEST_DATABASE -f dump.sql

echo "Grant privileges to Tester"

env PGPASSWORD=password psql -q -v ON_ERROR_STOP=1 -U ci_owner -d $TEST_DATABASE -f tests/grants.sql

echo "Create test functions"

cd tests && env PGPASSWORD=$TEST_PASSWORD psql -v ON_ERROR_STOP=1 -q -U $TEST_USERNAME -d $TEST_DATABASE -f tests.sql