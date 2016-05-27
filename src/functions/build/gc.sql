create or replace function build.gc() returns void as $$
    declare 
        _build_id int;
    begin 

        FOR _build_id IN 
            SELECT 
                build_id 
            FROM postgres_ci.builds
            WHERE status IN ('accepted', 'running')
            AND created_at < (current_timestamp - '1 hour'::interval)
            ORDER BY build_id
        LOOP 
            UPDATE postgres_ci.builds AS B
                SET
                    status      = 'failed',
                    error       = 'Execution timeout',
                    finished_at = current_timestamp
            WHERE B.build_id = _build_id;

            PERFORM 
                pg_notify('postgres-ci::stop_container', (
                        SELECT to_json(T.*) FROM (
                            SELECT 
                                P.container_id,
                                current_timestamp AS created_at
                        ) T
                    )::text
                )
            FROM postgres_ci.parts AS P
            WHERE P.build_id = _build_id;
        END LOOP;
    end;
$$ language plpgsql security definer;
