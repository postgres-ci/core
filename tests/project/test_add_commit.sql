create or replace function project.test_add_commit() returns void as $$
    declare 
        _project_id       int;
        _project_owner_id int;
        _commit_id        int;
        _commit_sha       text;
    begin 

        _project_owner_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.not_null(_project_owner_id) THEN 

            _project_id = project.add(
                'project',
                _project_owner_id,
                'https://github.com/postgres-ci/core.git', 
                ''
            );

            IF assert.not_null(_project_id) THEN 

                _commit_sha = encode(digest('commit' || CURRENT_TIMESTAMP, 'sha1'), 'hex');
                _commit_id  = project.add_commit(
                    _project_id,
                    'master',
                    _commit_sha,
                    'message',
                    CURRENT_TIMESTAMP - '1 day'::interval,
                    'Elephant Sam',
                    'samelephant82@gmail.com',
                    'Elephant Sam',
                    'samelephant82@gmail.com'
                );

                IF assert.not_null(_commit_id) THEN 

                    PERFORM 
                        assert.equal(project.get_branch_id(_project_id, 'master'), branch_id), 
                        assert.equal(_commit_sha, commit_sha),
                        assert.equal(CURRENT_TIMESTAMP - '1 day'::interval, committed_at),
                        assert.equal('Elephant Sam', committer_name),
                        assert.equal('samelephant82@gmail.com', committer_email)
                    FROM postgres_ci.commits 
                    WHERE commit_id = _commit_id;
                    
                END IF;

            END IF;

        END IF;
    end;
$$ language plpgsql security definer;

