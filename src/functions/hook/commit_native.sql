create or replace function hook.commit_native(
    _token           uuid,
    _branch          text,
    _commit_sha      text,
    _commit_message  text,
    _committed_at    timestamptz,
    _committer_name  text,
    _committer_email text,
    _author_name     text,
    _author_email    text,
    out commit_id    int
) returns int as $$
    declare 
        _project_id int;
    begin 

        SELECT project_id INTO _project_id FROM postgres_ci.projects WHERE project_token = _token AND is_deleted = false;
        
        IF NOT FOUND THEN 
        
            SET log_min_messages to LOG;

            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

        SELECT project.add_commit(
            _project_id,
            _branch,
            _commit_sha,
            _commit_message,
            _committed_at,
            _committer_name,
            _committer_email,
            _author_name,
            _author_email
        ) INTO commit_id;

    end;
$$ language plpgsql security definer;