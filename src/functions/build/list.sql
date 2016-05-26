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
