-- migrate:up

-- Our data tables
CREATE TABLE conjunctions (
    id SERIAL PRIMARY KEY, 
    organisation_id INT NOT NULL, 
    protobuf BYTEA NOT NULL, 
    json JSONB NOT NULL, 
    signature BYTEA NOT NULL,
    sharing_policy data_sharing_policy NOT NULL DEFAULT 'Public',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_organisation
        FOREIGN KEY(organisation_id) 
        REFERENCES organisations(id)
        ON DELETE CASCADE
);

COMMENT ON TABLE conjunctions IS 'Contains CCSDS conjunction data messages';
COMMENT ON COLUMN conjunctions.protobuf IS 'CDM encoded in protocol buffer format';
COMMENT ON COLUMN conjunctions.json IS 'CDM encoded in the associated JSON format';
COMMENT ON COLUMN conjunctions.signature IS 'ECDSA signature of the CDM protobuf data';

CREATE TABLE orbit_data (
    id SERIAL PRIMARY KEY, 
    organisation_id INT NOT NULL, 
    protobuf BYTEA NOT NULL, 
    json JSONB NOT NULL, 
    signature BYTEA NOT NULL,
    sharing_policy data_sharing_policy NOT NULL DEFAULT 'Public',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_organisation
        FOREIGN KEY(organisation_id) 
        REFERENCES organisations(id)
        ON DELETE CASCADE
);

CREATE TABLE tracking_data (
    id SERIAL PRIMARY KEY, 
    organisation_id INT NOT NULL, 
    protobuf BYTEA NOT NULL, 
    json JSONB NOT NULL, 
    signature BYTEA NOT NULL,
    is_public BOOL NOT NULL DEFAULT 'false',
    sharing_policy data_sharing_policy NOT NULL DEFAULT 'Public',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_organisation
        FOREIGN KEY(organisation_id) 
        REFERENCES organisations(id)
        ON DELETE CASCADE
);

-- Manage the updated_at column
SELECT updated_at('conjunctions');
SELECT updated_at('orbit_data');
SELECT updated_at('tracking_data');

-- Give access to the application user, the application user has no access to 
-- The sessions table and therefore cannot fake a login.
GRANT SELECT, INSERT, UPDATE ON conjunctions, orbit_data, tracking_data TO trace_application;
GRANT USAGE, SELECT ON conjunctions_id_seq, orbit_data_id_seq, tracking_data_id_seq TO trace_application;

-- Give access to the readonly user
GRANT SELECT ON conjunctions, orbit_data, tracking_data TO trace_readonly;
GRANT SELECT ON conjunctions_id_seq, orbit_data_id_seq, tracking_data_id_seq TO trace_readonly;

-- migrate:down
DROP TABLE conjunctions;
DROP TABLE orbit_data;
DROP TABLE tracking_data;