create or replace function password.change(
    _user_id          int, 
    _current_password text,
    _new_password     text
) returns boolean as $$
    declare
         _salt text;
    begin 

        IF password.check(_user_id, _current_password) THEN 

            _salt = postgres_ci.sha1(gen_salt('md5') || current_timestamp);

            UPDATE postgres_ci.users 
                SET
                    hash  = encode(digest(_salt || _new_password, 'sha1'), 'hex'),
                    salt  = _salt
            WHERE user_id = _user_id; 

        END IF;

        return true;
    end;
$$ language plpgsql security definer;