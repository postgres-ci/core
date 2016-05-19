create or replace function password.check(_user_id int, _password text) returns boolean as $$ 
    declare
        _invalid_password boolean;
    begin 

        SELECT
            encode(digest(U.salt || _password, 'sha1'), 'hex') != U.hash
            INTO
                _invalid_password
        FROM  postgres_ci.users AS U
        WHERE user_id    = _user_id
        AND   is_deleted = false;

        CASE 
            WHEN NOT FOUND THEN
                RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE = 'no_data_found';
            WHEN _invalid_password THEN 
                RAISE EXCEPTION 'INVALID_PASSWORD' USING ERRCODE = 'invalid_password';
            ELSE 
                return true;
        END CASE;
        
    end;
$$ language plpgsql security definer;