create or replace function notification.test_update_method() returns void as $$
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

                        IF assert.equal(42::bigint, (SELECT int_id FROM postgres_ci.user_notification_method WHERE user_id = _user_id)) THEN 
                            PERFORM notification.update_method(_user_id, 'none', 'nonenone');
                            PERFORM 
                                assert.equal('none', method),
                                assert.equal('', text_id),
                                assert.equal(0::bigint, int_id) 
                            FROM postgres_ci.user_notification_method WHERE user_id = _user_id;
                        END IF;
                        
                    END IF;

                END IF;
        END IF;

    end;
$$ language plpgsql security definer;