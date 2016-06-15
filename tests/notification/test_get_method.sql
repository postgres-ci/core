create or replace function notification.test_get_method() returns void as $$
    declare 
        _user_id int;
    begin 

        _user_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.true(EXISTS(SELECT null FROM postgres_ci.user_notification_method WHERE user_id = _user_id), 'Notification method doesn''t exists') THEN 


            PERFORM 
                assert.equal('email', method),
                assert.equal('samelephant82@gmail.com', text_id),
                assert.equal(0::bigint, int_id)
            FROM notification.get_method(_user_id);

            PERFORM assert.exception(
                $sql$ SELECT notification.get_method(-1) $sql$, 
                exception_message  := 'NOT_FOUND',
                exception_sqlstate := 'P0002'
            );

        END IF;

    end;
$$ language plpgsql security definer;