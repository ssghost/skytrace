-- migrate:up

CREATE TABLE api_keys (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR NOT NULL,
    api_key VARCHAR NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
   CONSTRAINT fk_user
      FOREIGN KEY(user_id) 
	  REFERENCES users(id)
      ON DELETE CASCADE
);

ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY api_keys_policy ON api_keys
    FOR ALL
    USING (user_id = current_setting('row_level_security.user_id')::integer);


GRANT SELECT, INSERT, UPDATE, DELETE ON api_keys TO trace_application;
GRANT USAGE, SELECT ON api_keys_id_seq TO trace_application;
GRANT SELECT ON api_keys TO trace_readonly;
GRANT SELECT ON api_keys_id_seq TO trace_readonly;


-- migrate:down

DROP TABLE api_keys;