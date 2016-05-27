create or replace function build.start(
    _build_id          int,
    out repository_url text,
    out branch         text,
    out revision       text
) returns record as $$
    declare 
        _commit_id  int;
        _project_id int;
    begin

        UPDATE postgres_ci.builds AS B
            SET 
                status     = 'running',
                started_at = current_timestamp
        WHERE B.build_id = _build_id 
        AND   B.status   = 'accepted'
        RETURNING B.commit_id INTO _commit_id;
        
        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

        SELECT 
            P.project_id,
            P.repository_url,
            B.branch,
            C.commit_sha 
                INTO 
                    _project_id,
                    repository_url,
                    branch,
                    revision
        FROM postgres_ci.projects AS P 
        JOIN postgres_ci.branches AS B USING(project_id)
        JOIN postgres_ci.commits  AS C ON C.branch_id = B.branch_id
        WHERE C.commit_id = _commit_id;

        UPDATE postgres_ci.projects SET last_build_id = _build_id  WHERE project_id = _project_id;
    end;
$$ language plpgsql security definer;