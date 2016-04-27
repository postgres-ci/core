create or replace function task.new(
    _commit_id  int,
    out task_id int
) returns int as $$
    begin 

        INSERT INTO postgres_ci.tasks (
            commit_id,
            status
        ) VALUES (
            _commit_id,
            'pending'
        ) RETURNING tasks.task_id INTO task_id;

        PERFORM pg_notify('postgres-ci', (
                SELECT to_json(T.*) FROM (
                    SELECT 
                        new.task_id       AS task_id,
                        CURRENT_TIMESTAMP AS created_at
                ) T
            )::text
        );
    end;
$$ language plpgsql security definer;