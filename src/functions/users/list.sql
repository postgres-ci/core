create or replace function users.list(
    _limit  int,
    _offset int,
    _query  text,

    out total bigint,
    out users jsonb
) returns record as $$ 
    declare
        _pattern text;
    begin 

        IF _query <> '' THEN 
            _pattern = '%' || array_to_string(string_to_array(lower(_query), ' '), '%') || '%';
        END IF;

        SELECT 
            (
                SELECT 
                    COUNT(*) 
                FROM postgres_ci.users
                WHERE is_deleted = false
                AND (
                    CASE WHEN _pattern IS NOT NULL 
                        THEN lower(user_name || user_login || user_email) LIKE _pattern
                        ELSE true
                    END
                )
            ),
            (
                SELECT 
                    COALESCE(array_to_json(array_agg(U.*)), '[]') 
                FROM (
                    SELECT 
                        user_id,
                        user_name,
                        user_login,
                        user_email,
                        is_superuser,
                        created_at,
                        updated_at
                    FROM postgres_ci.users
                    WHERE is_deleted = false
                    AND (
                        CASE WHEN _pattern IS NOT NULL 
                            THEN lower(user_name || user_login || user_email) LIKE _pattern
                            ELSE true
                        END
                    )
                    ORDER BY user_id 
                    LIMIT  _limit
                    OFFSET _offset
                ) U
            )
        INTO total, users;
    end;
$$ language plpgsql security definer;