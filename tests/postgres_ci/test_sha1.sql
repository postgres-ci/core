create or replace function postgres_ci.test_sha1() returns void as $$
    declare 
        _value text;
    begin 

        FOR _value IN SELECT 'value_' || v FROM generate_series(1, 100) v LOOP

            IF NOT assert.equal(encode(digest(_value, 'sha1'), 'hex'), postgres_ci.sha1(_value)) THEN 
                return;
            END IF;

        END LOOP;
    end;
$$ language plpgsql;