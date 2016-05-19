create or replace function project.update(
    _project_id       int,
    _project_name     text,
    _project_owner_id int,
    _repository_url   text,
    _github_secret    text
) returns void as $$
    begin 

        UPDATE postgres_ci.projects 
            SET
                project_name     = _project_name,
                project_owner_id = _project_owner_id,
                repository_url   = _repository_url,
                github_name      = project.github_name(_repository_url),
                github_secret    = _github_secret
        WHERE project_id = _project_id;

        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer;
