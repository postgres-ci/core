create or replace function notification.test_find_user_by_telegram_username() returns void as $$
    declare 
        _user_id int;
    begin 

        _user_id = users.add('login', 'password', 'Elephant Sam', 'samelephant82@gmail.com', true);

        IF assert.true(EXISTS(SELECT null FROM postgres_ci.user_notification_method WHERE user_id = _user_id), 'Notification method doesn''t exists') THEN 

            IF (
                SELECT 
                    assert.equal('email', method) AND
                    assert.equal('samelephant82@gmail.com', text_id) AND
                    assert.equal(0::bigint, int_id) 
                FROM postgres_ci.user_notification_method WHERE user_id = _user_id
            ) THEN 

                PERFORM notification.update_method(_user_id, 'telegram', 'telegram_username');

                IF (
                    SELECT 
                        assert.equal('telegram', method) AND
                        assert.equal('telegram_username', text_id) AND
                        assert.equal(0::bigint, int_id) 
                    FROM postgres_ci.user_notification_method WHERE user_id = _user_id
                ) THEN 

                    PERFORM notification.bind_with_telegram(_user_id, 'telegram_username', 42);

                    PERFORM 
                        assert.equal(_user_id, user_id),
                        assert.equal(42::bigint, telegram_id)
                    FROM notification.find_user_by_telegram_username('telegram_username');
                    
                END IF;

            END IF;
        END IF;

    end;
$$ language plpgsql security definer;