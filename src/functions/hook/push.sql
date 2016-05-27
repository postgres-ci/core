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
