create or replace function build.new(
    _project_id int, 
    _branch_id  int,
    _commit_id  int,
    out build_id int
) returns int as $$
    begin 

        INSERT INTO postgres_ci.builds (
            project_id, 
            branch_id,
            commit_id,
            config,
            status
        ) VALUES (
            _project_id, 
            _branch_id,
            _commit_id,
            '',
            'pending'
        ) RETURNING builds.build_id INTO build_id;

        INSERT INTO postgres_ci.builds_counters AS C (
            project_id, 
            branch_id,
            counter
        ) VALUES (
            _project_id, 
            _branch_id,
            1
        ) ON CONFLICT 
            ON CONSTRAINT unique_builds_counters DO UPDATE 
                SET counter = C.counter + 1;

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