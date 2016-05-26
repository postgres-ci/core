create or replace function build.gc() returns void as $$
    begin 
    
        WITH builds AS (
            SELECT 
                build_id 
            FROM postgres_ci.builds
            WHERE status IN ('accepted', 'running')
            AND created_at < (current_timestamp - '1 hour'::interval)
            ORDER BY build_id
        ),
        stop_containers AS (
            SELECT 
                pg_notify('postgres-ci::stop_container', (
                        SELECT to_json(T.*) FROM (
                            SELECT 
                                P.container_id,
                                current_timestamp AS created_at
                        ) T
                    )::text
                )
            FROM postgres_ci.parts AS P
            JOIN builds AS B ON P.build_id = B.build_id
        )
        UPDATE postgres_ci.builds AS B
            SET
                status      = 'failed',
                error       = 'Execution timeout',
                finished_at = current_timestamp
        WHERE B.build_id IN (SELECT build_id FROM builds);

    end;
$$ language plpgsql security definer;