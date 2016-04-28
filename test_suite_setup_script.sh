#!/bin/sh

env PGPASSWORD=$POSTGRES_PASSWORD psql -q -U $POSTGRES_USER -d $TEST_DATABASE <<-SQL
	CREATE SCHEMA postgres_ci;
	CREATE EXTENSION pgcrypto;
SQL

cat postgres_ci--0.0.1.sql | sed '/CREATE EXTENSION postgres_ci/d' > dump.sql

env PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $TEST_DATABASE -f dump.sql

echo "Grant privileges to Tester"

env PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $TEST_DATABASE -f tests/grants.sql

echo "Create test functions"

cd tests && env PGPASSWORD=$TEST_PASSWORD psql -U $TEST_USERNAME -d $TEST_DATABASE -f tests.sql