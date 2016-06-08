create or replace function postgres_ci.test_update_settings() returns void as $$
    begin 

        IF assert.true(
            (
                SELECT  
                    assert.equal('', app_host)      AND
                    assert.equal('', smtp_host)     AND
                    assert.equal(0,  smtp_port)     AND
                    assert.equal('', smtp_username) AND
                    assert.equal('', smtp_password) AND
                    assert.equal('', telegram_token)
                FROM postgres_ci.settings
            )
        ) THEN 
            PERFORM postgres_ci.update_settings(
                'app_host',
                'smtp_host',
                25,
                'smtp_username',
                'smtp_password',
                'telegram_token'
            );
            
            PERFORM 
                assert.equal('app_host',       app_host),
                assert.equal('smtp_host',      smtp_host),
                assert.equal(25,               smtp_port),
                assert.equal('smtp_username',  smtp_username),
                assert.equal('smtp_password',  smtp_password),
                assert.equal('telegram_token', telegram_token)
            FROM postgres_ci.settings;
        END IF;
    end;
$$ language plpgsql security definer; 


