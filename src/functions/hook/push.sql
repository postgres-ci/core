create or replace function hook.push(
    _token   uuid,
    _branch  text,
    _commits jsonb
) returns table (
    commit_id int
) as $$
    declare
        _project_id int;
    begin 

        SELECT project_id INTO _project_id FROM postgres_ci.projects WHERE project_token = _token AND is_deleted = false;
        
        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

        return query 

            SELECT 
                project.add_commit(
                    _project_id,
                    _branch,
                    C.commit_sha,
                    C.commit_message,
                    C.committed_at,
                    C.committer_name,
                    C.committer_email,
                    C.author_name,
                    C.author_email
                ) 
            FROM jsonb_populate_recordset(null::postgres_ci.commits, _commits) AS C;
    end;
$$ language plpgsql security definer;

/*

select 
* 
from hook.push('764a340a-7230-4d5e-950e-de0727316e7c', 'master', '[{"commit_sha":"be60d1fbf2f6d18f9963e263ad8284217a8fcded","commit_message":"Test","committed_at":"2016-05-05T17:40:59.431696+03:00","committer_name":"kshvakov","committer_email":"shvakov@gmail.com","author_name":"kshvakov","author_email":"shvakov@gmail.com","created_at":"2016-05-05T17:40:59.431696+03:00"},{"commit_sha":"654fe21cd1874d3028bfbc84e1ff4b6245cfac9b","commit_message":"add list builds fn\n","committed_at":"2016-05-05T17:53:55+03:00","committer_name":"kshvakov","committer_email":"shvakov@gmail.com","author_name":"kshvakov","author_email":"shvakov@gmail.com","created_at":"2016-05-05T17:53:55.860997+03:00"},{"commit_sha":"ac4c4a78e4f0321d273c0502165c98f8b71d2eb0","commit_message":"misc\n","committed_at":"2016-05-06T11:45:03+03:00","committer_name":"kshvakov","committer_email":"shvakov@gmail.com","author_name":"kshvakov","author_email":"shvakov@gmail.com","created_at":"2016-05-06T11:45:03.421098+03:00"}]');

*/