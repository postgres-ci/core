create or replace function project.test_github_name() returns void as $$
    declare 
        repo_url  text;
        repo_name text;
    begin 

        FOR repo_url, repo_name IN WITH assets(url, github_name) AS (
            VALUES 
                ('https://github.com/postgres/postgres.git',  'postgres/postgres'),
                ('git@github.com:postgres/postgres.git',      'postgres/postgres'),
                ('git@github.com:postgres-ci/assert.git',     'postgres-ci/assert'),
                ('https://github.com/postgres-ci/assert.git', 'postgres-ci/assert'),
                ('https://not_github.com/postgres-ci/assert.git', ''),
                ('https://github.net/postgres-ci/assert.git',     '')
        ) SELECT url, github_name FROM assets LOOP 

            IF NOT assert.equal(repo_name, project.github_name(repo_url)) THEN 
                return;
            END IF;

        END LOOP;

    end;
$$ language plpgsql;

