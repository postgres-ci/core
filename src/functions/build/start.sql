create or replace function build.start(
    _task_id            int,
    out build_id       int,
    out repository_url text,
    out branch         text,
    out revision       text
) returns record as $$
    declare 
        _commit_id  int;
        _project_id int;
    begin 

        SELECT commit_id INTO _commit_id FROM postgres_ci.tasks WHERE task_id = _task_id;

        INSERT INTO postgres_ci.builds (
            commit_id,
            config,
            status
        ) VALUES (
            _commit_id,
            '',
            'running'
        ) RETURNING builds.build_id INTO build_id;

        UPDATE postgres_ci.tasks 
            SET 
                status   = 'running',
                build_id = start.build_id 
        WHERE task_id = _task_id;

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

        UPDATE postgres_ci.projects SET last_build_id = start.build_id  WHERE project_id = _project_id;
    end;
$$ language plpgsql security definer;