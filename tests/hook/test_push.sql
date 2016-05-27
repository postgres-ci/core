create or replace function hook.test_push() returns void as $$
    declare 
        _project_id       int;
        _project_owner_id int;
        _token            uuid;
        _push jsonb;
    begin 

        _push = '
            [
               {
                  "commit_sha":"fa7e3d5fc6b69309e2e8eb9e2af82da3cd96f383",
                  "commit_message":"Test",
                  "committed_at":"2016-05-05T17:40:59.431696+03:00",
                  "committer_name":"kshvakov",
                  "committer_email":"shvakov@gmail.com",
                  "author_name":"kshvakov",
                  "author_email":"shvakov@gmail.com",
                  "created_at":"2016-05-05T17:40:59.431696+03:00"
               },
               {
                  "commit_sha":"654fe21cd1874d3028bfbc84e1ff4b6245cfac9b",
                  "commit_message":"add list builds fn\n",
                  "committed_at":"2016-05-05T17:53:55+03:00",
                  "committer_name":"kshvakov",
                  "committer_email":"shvakov@gmail.com",
                  "author_name":"kshvakov",
                  "author_email":"shvakov@gmail.com",
                  "created_at":"2016-05-05T17:53:55.860997+03:00"
               },
               {
                  "commit_sha":"ac4c4a78e4f0321d273c0502165c98f8b71d2eb0",
                  "commit_message":"misc\n",
                  "committed_at":"2016-05-06T11:45:03+03:00",
                  "committer_name":"kshvakov",
                  "committer_email":"shvakov@gmail.com",
                  "author_name":"kshvakov",
                  "author_email":"shvakov@gmail.com",
                  "created_at":"2016-05-06T11:45:03.421098+03:00"
               }
            ]
        ';

        _project_owner_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.not_null(_project_owner_id) THEN 

            _project_id = project.add(
                'project',
                _project_owner_id,
                'https://github.com/postgres-ci/core.git', 
                ''
            );

            IF assert.not_null(_project_id) THEN 

                _token = (SELECT project_token FROM postgres_ci.projects WHERE project_id = _project_id);

                IF assert.equal(3, (SELECT COUNT(*) FROM (SELECT commit_id FROM hook.push(_token, 'master', _push)) _ )::int) THEN 

                    PERFORM assert.equal(3, (SELECT COUNT(*) FROM postgres_ci.commits WHERE project_id = _project_id)::int);

                END IF;

            END IF;

        END IF;
    end;
$$ language plpgsql security definer;
