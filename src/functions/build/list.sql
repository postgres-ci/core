create or replace function build.list(
    _project_id  int,
    _limit       int,
    _offset      int,
    out total    bigint,
    out branches jsonb,
    out items    jsonb
) returns record as $$
    begin 

        SELECT 
            (
                SELECT 
                    COALESCE(SUM(counter), 0) 
                FROM postgres_ci.builds_counters
                WHERE project_id = _project_id
            ),
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(R.*)), '[]') 
                FROM (
                    SELECT 
                        branch_id,
                        branch
                    FROM postgres_ci.branches 
                    WHERE 
                        project_id = _project_id
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
                    ORDER BY build_id DESC
                    LIMIT  _limit
                    OFFSET _offset
                ) AS R
            )
        INTO total, branches, items;

    end;
$$ language plpgsql security definer;

