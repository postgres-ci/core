create or replace function build.stop(_build_id int, _config text, _error text) returns void as $$
    begin 

        UPDATE postgres_ci.builds
            SET 
                config      = _config,
                error       = _error,
                status      = (
                    CASE 
                        WHEN _error = '' THEN 'success' 
                        ELSE 'failed' 
                    END
                )::postgres_ci.status,
                finished_at = current_timestamp
        WHERE build_id = _build_id
        AND   status   = 'running';

        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;

        PERFORM build.notify(_build_id);

        IF EXISTS(
            SELECT 
            FROM postgres_ci.parts 
            WHERE build_id = _build_id 
            AND success IS False
            LIMIT 1
        ) THEN 
            UPDATE postgres_ci.builds SET status = 'failed'::postgres_ci.status WHERE build_id = _build_id;
        END IF;

    end;
$$ language plpgsql security definer;
