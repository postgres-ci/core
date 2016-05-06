create or replace function build.list_by_branch(
    _project_id int,
    _branch_id  int,
    _limit      int,
    _offset     int,
    out total   bigint,
    out items   jsonb
) returns record as $$
    begin 

        SELECT 
            (
                SELECT 
                    COALESCE(SUM(counter), 0) 
                FROM postgres_ci.builds_counters
                WHERE project_id = _project_id
                AND   branch_id  = _branch_id
            ),
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(R.*), true), '[]') 
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
                        B.branch
                    FROM postgres_ci.builds   AS BD
                    JOIN postgres_ci.commits  AS C USING(commit_id) 
                    JOIN postgres_ci.branches AS B ON B.branch_id  = C.branch_id
                    WHERE 
                        BD.project_id = _project_id
                    AND BD.branch_id  = _branch_id
                    ORDER BY build_id DESC
                    LIMIT  _limit
                    OFFSET _offset
                ) AS R
            )
        INTO total, items;

    end;
$$ language plpgsql security definer;

