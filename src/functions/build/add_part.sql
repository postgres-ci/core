create or replace function build.add_part(
    _build_id     int,
    _version      text,
    _image        text,
    _container_id text,
    _output       text,
    _started_at   timestamptz,
    _tests        jsonb,
    out part_id   int
) returns int as $$
    declare 
        _test postgres_ci.tests;
    begin 

        INSERT INTO postgres_ci.parts (
            build_id,
            version,
            image,
            container_id,
            output,
            success,
            started_at,
            finished_at
        ) VALUES (
            _build_id,
            _version,
            _image,
            _container_id,
            _output,
            true,
            _started_at,
            CURRENT_TIMESTAMP
        ) RETURNING parts.part_id INTO add_part.part_id;

        INSERT INTO postgres_ci.tests (
            part_id,
            function,
            errors,
            duration
        )
        SELECT 
            add_part.part_id, 
            E.function,
            E.errors, 
            E.duration 
        FROM jsonb_populate_recordset(null::postgres_ci.tests, _tests) AS E;

        IF EXISTS(
            SELECT 
            FROM postgres_ci.tests 
            WHERE tests.part_id = add_part.part_id 
            AND jsonb_array_length(errors) > 0 
            LIMIT 1
        ) THEN 
            UPDATE postgres_ci.parts SET success = false WHERE parts.part_id = add_part.part_id;
        END IF;

    end;
$$ language plpgsql security definer;
