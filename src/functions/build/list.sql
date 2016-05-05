create or replace function build.list(
    _limit    int,
    _offset   int,
    out total bigint,
    out items jsonb
) returns record as $$
    begin 

        SELECT 
            (
                SELECT COALESCE(SUM(counter), 0) FROM postgres_ci.builds_counters
            ),
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(R.*), true), '[]') 
                FROM (
                    SELECT 
                        BD.build_id,
                        BD.status,
                        BD.error,
                        BD.created_at,
                        BD.started_at,
                        BD.finished_at,
                        C.commit_sha,
                        B.branch,
                        P.project_name,
                        P.project_id
                    FROM postgres_ci.builds   AS BD
                    JOIN postgres_ci.commits  AS C USING(commit_id) 
                    JOIN postgres_ci.branches AS B ON B.branch_id  = C.branch_id 
                    JOIN postgres_ci.projects AS P ON P.project_id = B.project_id  
                    ORDER BY build_id DESC
                    LIMIT  _limit
                    OFFSET _offset
                ) AS R
            )
        INTO total, items;

    end;
$$ language plpgsql security definer;

