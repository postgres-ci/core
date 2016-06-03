create or replace function notification.fetch() returns table (
    build_id int,
    send_to  jsonb
) as $$
    declare 
        _build_id int;
    begin 

        SELECT N.build_id INTO _build_id FROM postgres_ci.notification AS N ORDER BY N.build_id FOR UPDATE SKIP LOCKED;

        IF NOT FOUND THEN 
            return;
        END IF;

        return query 
            SELECT 
                _build_id,
                (
                    SELECT 
                        COALESCE(array_to_json(array_agg(P.*)), '[]') 
                    FROM (
                        SELECT 
                            U.user_name,
                            M.method,
                            M.text_id,
                            M.int_id
                        FROM postgres_ci.users AS U 
                        JOIN postgres_ci.user_notification_method AS M ON U.user_id = M.user_id
                        WHERE U.user_id IN (
                            SELECT 
                                P.project_owner_id 
                            FROM postgres_ci.projects AS P  
                            JOIN postgres_ci.builds   AS B USING(project_id)
                            WHERE B.build_id = _build_id
                        UNION ALL
                            SELECT 
                                U.user_id 
                            FROM postgres_ci.users AS U 
                            WHERE U.user_email IN (
                                SELECT 
                                    author_email 
                                FROM postgres_ci.commits AS C 
                                JOIN postgres_ci.builds AS B USING(commit_id)
                                WHERE B.build_id = _build_id
                            )
                        ) AND M.method <> 'none'
                    ) AS P 
                )::jsonb
            ;

        DELETE FROM postgres_ci.notification AS N WHERE N.build_id = _build_id;
    end;
$$ language plpgsql security definer;

