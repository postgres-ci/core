create schema auth;
create schema hook;
create schema users;
create schema build;
create schema project;

grant usage on schema auth    to public;
grant usage on schema hook    to public;
grant usage on schema users   to public;
grant usage on schema build   to public;
grant usage on schema project to public;
grant usage on schema postgres_ci to public;
grant execute on all functions in schema auth    to public;
grant execute on all functions in schema hook    to public;
grant execute on all functions in schema users   to public;
grant execute on all functions in schema build   to public;
grant execute on all functions in schema project to public;
