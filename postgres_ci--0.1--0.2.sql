alter extension postgres_ci drop function build.view(int);
drop function build.view(int);

create or replace function build.view(
    _build_id int, 

    out project_id      int,
    out project_name    text,
    out branch_id       int,
    out branch_name     text,
    out config          text, 
    out error           text,
    out status          postgres_ci.status,
    out commit_sha      text,
    out commit_message  text,
    out committed_at    timestamptz,
    out committer_name  text,
    out committer_email text,
    out author_name     text,
    out author_email    text,
    out created_at      timestamptz,
    out parts           jsonb
) returns record as $$
    begin 

        SELECT
            B.project_id,
            P.project_name, 
            B.branch_id, 
            BR.branch,
            B.config,
            B.error,
            B.status,
            C.commit_sha,
            C.commit_message,
            C.committed_at,
            C.committer_name,
            C.committer_email,
            C.author_name,
            C.author_email,
            B.created_at,
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(P.*)), '[]') 
                FROM (
                    SELECT 
                        part_id,
                        image,
                        version,
                        output,
                        success,
                        started_at,
                        finished_at,
                        (
                            SELECT 
                                COALESCE(array_to_json(array_agg(T.*)), '[]') 
                            FROM (
                                SELECT 
                                    function,
                                    errors,
                                    duration
                                FROM postgres_ci.tests 
                                WHERE part_id = parts.part_id
                                ORDER BY 
                                    jsonb_array_length(errors) DESC, 
                                    function
                            ) AS T
                        ) AS tests
                    FROM postgres_ci.parts 
                    WHERE build_id = B.build_id
                    ORDER BY part_id
                ) AS P 
            )
            INTO 
                project_id,
                project_name,
                branch_id,
                branch_name,
                config, 
                error,
                status,
                commit_sha,
                commit_message,
                committed_at,
                committer_name,
                committer_email,
                author_name,
                author_email,
                created_at,
                parts
        FROM postgres_ci.builds AS B 
            JOIN postgres_ci.projects AS P USING(project_id)
            JOIN postgres_ci.branches AS BR ON BR.branch_id = B.branch_id
            JOIN postgres_ci.commits  AS C  ON C.commit_id  = B.commit_id
        WHERE B.build_id = _build_id;

        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer;

alter extension postgres_ci drop function build.list(int,int,int,int);
drop function build.list(int,int,int,int);

create or replace function build.list(
    _project_id  int,
    _branch_id   int,
    _limit       int,
    _offset      int,
    out project_id   int,
    out project_name text,
    out total        bigint,
    out branches     jsonb,
    out items        jsonb
) returns record as $$
    begin 

        SELECT 
            P.project_id,
            P.project_name,
            (
                SELECT 
                    COALESCE(SUM(C.counter), 0) 
                FROM postgres_ci.builds_counters AS C
                WHERE C.project_id = _project_id
                AND (
                    CASE WHEN _branch_id <> 0 
                        THEN branch_id  = _branch_id
                        ELSE true 
                    END
                )
            ),
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(R.*)), '[]') 
                FROM (
                    SELECT 
                        B.branch_id,
                        B.branch
                    FROM postgres_ci.branches AS B
                    WHERE 
                        B.project_id = _project_id
                    ORDER BY branch
                ) AS R
            ),
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(R.*)), '[]') 
                FROM (
                    SELECT 
                        BD.build_id,
                        BD.project_id,
                        BD.status,
                        BD.error,
                        BD.created_at,
                        BD.started_at,
                        BD.finished_at,
                        C.commit_sha,
                        C.commit_message,
                        B.branch,
                        B.branch_id
                    FROM postgres_ci.builds   AS BD
                    JOIN postgres_ci.commits  AS C USING(commit_id) 
                    JOIN postgres_ci.branches AS B ON B.branch_id  = C.branch_id
                    WHERE 
                        BD.project_id = _project_id
                    AND (
                        CASE WHEN _branch_id <> 0 
                            THEN BD.branch_id  = _branch_id
                            ELSE true
                        END
                    )
                    ORDER BY build_id DESC
                    LIMIT  _limit
                    OFFSET _offset
                ) AS R
            )
            FROM postgres_ci.projects AS P
            WHERE P.project_id = _project_id 
            AND   P.is_deleted = false
        INTO project_id, project_name, total, branches, items;

    end;
$$ language plpgsql security definer;


create or replace function hook.github_push(
    _github_name text,
    _branch      text,
    _commits     jsonb
) returns table (
    commit_id int
) as $$
    declare
        _project_id int;
    begin 

        SELECT project_id INTO _project_id FROM postgres_ci.projects WHERE github_name = _github_name AND is_deleted = false;
        
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