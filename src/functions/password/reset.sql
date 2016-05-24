create or replace function password.reset(_user_id int, _password text) returns void as $$
    declare 
        _salt text;
    begin 
        _salt = postgres_ci.sha1(gen_salt('md5') || current_timestamp);
        UPDATE postgres_ci.users 
            SET
                hash  = encode(digest(_salt || _password, 'sha1'), 'hex'),
                salt  = _salt
        WHERE user_id = _user_id; 
    end;
$$ language plpgsql security definer;