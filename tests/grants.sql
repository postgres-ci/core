grant create on schema auth to tester;
grant create on schema hook to tester;
grant create on schema users to tester;
grant create on schema build to tester;
grant create on schema project to tester;
grant create on schema password to tester;
grant create on schema postgres_ci to tester;
grant create on schema notification to tester; 

grant select on all tables in schema postgres_ci to tester;
grant update on table postgres_ci.sessions to tester;


-- create user tester with password 'password' login;