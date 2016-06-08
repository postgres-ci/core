create schema notification;
grant usage   on schema notification to public;
grant execute on all functions in schema notification to public;
drop index postgres_ci.find_user;

create unlogged table postgres_ci.notification(
    build_id   int         not null references postgres_ci.builds(build_id) primary key,
    created_at timestamptz not null default current_timestamp
);

create type postgres_ci.notification_method as enum (
    'none',
    'email',
    'telegram'
);

create table postgres_ci.user_notification_method(
    user_id int not null references postgres_ci.users(user_id) primary key,
    method  postgres_ci.notification_method not null default 'none',
    text_id text   not null,
    int_id  bigint not null default 0
);

select pg_catalog.pg_extension_config_dump('postgres_ci.user_notification_method', '');

create unique index unique_user_notification_method 
    on postgres_ci.user_notification_method (method, lower(text_id))
where method <> 'none' and text_id <> '';

insert into postgres_ci.user_notification_method (user_id, method, text_id)
	select user_id, 'email', user_email from postgres_ci.users;

create table postgres_ci.settings (
    app_host       text not null,
    smtp_host      text not null,
    smtp_port      int  not null,
    smtp_username  text not null,
    smtp_password  text not null,
    telegram_token text not null
);
select pg_catalog.pg_extension_config_dump('postgres_ci.settings', '');
insert into postgres_ci.settings values('', '', 0, '', '', '');

create or replace function notification.fetch() returns table (
    build_id           int,
    build_status        postgres_ci.status,
    branch              text,
    build_error         text,
    build_created_at    timestamptz,
    build_started_at    timestamptz,
    build_finished_at   timestamptz,
    commit_sha          text,
    commit_message      text,
    committed_at        timestamptz,
    committer_name      text,
    committer_email     text,
    commit_author_name  text,
    commit_author_email text,
    send_to             jsonb
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
                B.build_id,
                B.status,
                BR.branch,
                B.error,
                B.created_at,
                B.started_at,
                B.finished_at,
                C.commit_sha,
                C.commit_message,
                C.committed_at,
                C.committer_name,
                C.committer_email,
                C.author_name,
                C.author_email,
                (
                    SELECT 
                        COALESCE(array_to_json(array_agg(P.*)), '[]') 
                    FROM (
                        SELECT 
                            U.user_name,
                            M.method   AS notify_method,
                            M.text_id  AS notify_text_id,
                            M.int_id   AS notify_int_id
                        FROM postgres_ci.users AS U 
                        JOIN postgres_ci.user_notification_method AS M ON U.user_id = M.user_id
                        WHERE U.user_id IN (
                            SELECT 
                                P.project_owner_id 
                        UNION ALL
                            SELECT 
                                U.user_id 
                            FROM postgres_ci.users AS U 
                            WHERE U.user_email IN (lower(C.author_email), lower(C.committer_email))
                        ) AND M.method <> 'none'
                    ) AS P 
                )::jsonb
            FROM postgres_ci.builds   AS B 
            JOIN postgres_ci.projects AS P  ON P.project_id = B.project_id
            JOIN postgres_ci.commits  AS C  ON C.commit_id  = B.commit_id
            JOIN postgres_ci.branches AS BR ON BR.branch_id = B.branch_id
            WHERE B.build_id = _build_id;

        DELETE FROM postgres_ci.notification AS N WHERE N.build_id = _build_id;
    end;
$$ language plpgsql security definer rows 1;

create or replace function users.add(
    _user_login   text,
    _password     text,
    _user_name    text,
    _user_email   text,
    _is_superuser boolean,
    out user_id   int
) returns int as $$
    declare
        _salt            text;
        _message         text;
        _column_name     text;
        _constraint_name text;
        _datatype_name   text;
        _table_name      text;
        _schema_name     text;
    begin 

        _salt = postgres_ci.sha1(gen_salt('md5') || current_timestamp);

        BEGIN 

            INSERT INTO postgres_ci.users (
                user_login,
                user_name,
                user_email,
                is_superuser,
                hash,
                salt
            ) VALUES (
                _user_login,
                _user_name,
                _user_email,
                _is_superuser,
                encode(digest(_salt || _password, 'sha1'), 'hex'),
                _salt
            ) RETURNING users.user_id INTO user_id;

            INSERT INTO postgres_ci.user_notification_method (user_id, method, text_id) VALUES (add.user_id, 'email', _user_email);

        EXCEPTION WHEN OTHERS THEN
        
            GET STACKED DIAGNOSTICS 
                _column_name     = column_name,
                _constraint_name = constraint_name,
                _datatype_name   = pg_datatype_name,
                _table_name      = table_name,
                _schema_name     = schema_name;

            CASE 
                WHEN _constraint_name = 'unique_user_login' THEN
                    _message = 'LOGIN_ALREADY_EXISTS';
                WHEN _constraint_name = 'unique_user_email' THEN 
                    _message = 'EMAIL_ALREADY_EXISTS';
                WHEN _constraint_name = 'check_user_email' THEN 
                    _message = 'INVALID_EMAIL';
                ELSE 
                    _message = SQLERRM;
            END CASE;

            RAISE EXCEPTION USING 
                MESSAGE    = _message,
                ERRCODE    = SQLSTATE,
                COLUMN     = _column_name,
                CONSTRAINT = _constraint_name,
                DATATYPE   = _datatype_name,
                TABLE      = _table_name,
                SCHEMA     = _schema_name;
        END;

    end;
$$ language plpgsql security definer;


create or replace function notification.update_method(
    _user_id int,
    _method  postgres_ci.notification_method,
    _text_id text
) returns void as $$
    begin 

        CASE 
            WHEN _method = 'none' THEN 
                UPDATE postgres_ci.user_notification_method
                    SET 
                        method  = _method,
                        text_id = '',
                        int_id  = 0
                WHERE user_id = _user_id;
            ELSE 
                UPDATE postgres_ci.user_notification_method
                    SET 
                        method  = _method,
                        text_id = _text_id,
                        int_id  = 0
                WHERE user_id = _user_id AND NOT (
                    text_id = _text_id AND method = _method
                );
        END CASE;

    end;
$$ language plpgsql security definer;

create or replace function notification.bind_with_telegram(
    _user_id           int, 
    _telegram_username text, 
    _telegram_id       bigint
) returns void as $$
    begin 

        UPDATE postgres_ci.user_notification_method 
            SET
                int_id = _telegram_id
        WHERE user_id = _user_id
        AND   text_id = _telegram_username;

        IF NOT FOUND THEN 
            RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
        END IF;
    end;
$$ language plpgsql security definer; 

create or replace function notification.find_user_by_telegram_username(_telegram_username text) returns table (
    user_id    int,
    telegram_id bigint
) as $$
    begin 

        return query 
            SELECT 
                N.user_id, 
                N.int_id 
            FROM postgres_ci.user_notification_method AS N
            WHERE N.method  = 'telegram'
            AND   N.text_id = _telegram_username;

    end;
$$ language plpgsql security definer rows 1;


create or replace function postgres_ci.update_settings(
    _app_host       text,
    _smtp_host      text,
    _smtp_port      int,
    _smtp_username  text,
    _smtp_password  text,
    _telegram_token text
) returns void as $$
    begin
        UPDATE postgres_ci.settings
            SET 
                app_host       = _app_host,
                smtp_host      = _smtp_host,
                smtp_port      = _smtp_port,
                smtp_username  = _smtp_username,
                smtp_password  = _smtp_password,
                telegram_token = _telegram_token;
    end;
$$ language plpgsql security definer;

