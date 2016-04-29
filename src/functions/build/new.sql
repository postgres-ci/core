create or replace function build.new(
    _commit_id  int,
    out build_id int
) returns int as $$
    begin 

        INSERT INTO postgres_ci.builds (
            commit_id,
            config,
            status
        ) VALUES (
            _commit_id,
            '',
            'pending'
        ) RETURNING builds.build_id INTO build_id;

        PERFORM pg_notify('postgres-ci::tasks', (
                SELECT to_json(T.*) FROM (
                    SELECT 
                        new.build_id      AS build_id,
                        CURRENT_TIMESTAMP AS created_at
                ) T
            )::text
        );

    end;
$$ language plpgsql security definer;