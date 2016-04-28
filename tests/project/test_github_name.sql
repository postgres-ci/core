create or replace function project.test_github_name() returns void as $$
    declare 
        repo_url  text;
        github_name text;
    begin 

        FOR repo_url, github_name IN VALUES 
            ('https://github.com/postgres/postgres.git',  'postgres/postgres'),
            ('git@github.com:postgres/postgres.git',      'postgres/postgres'),
            ('git@github.com:postgres-ci/assert.git',     'postgres-ci/assert'),
            ('https://github.com/postgres-ci/assert.git', 'postgres-ci/assert'),
            ('https://not_github.com/postgres-ci/assert.git', ''),
            ('https://github.net/postgres-ci/assert.git',     '')
        LOOP 

            IF NOT assert.equal(github_name, project.github_name(repo_url)) THEN 
                return;
            END IF;

        END LOOP;

    end;
$$ language plpgsql;

