-- migrate:up

-- Space objects
CREATE TYPE validation_status AS ENUM('Pending', 'Verified');

CREATE TABLE registered_objects
(
  id                    SERIAL PRIMARY KEY,  
  -- mandatory properties
  organisation_id       INT                 NOT NULL,
  data_sharing_policy   DATA_SHARING_POLICY NULL DEFAULT 'Public',
  name                  VARCHAR(50)         NOT NULL,
  manoeuvrable          BOOLEAN             NOT NULL,
  manoeuvre_latency     INT                 NOT NULL,
  -- optional properties
  defunct               BOOLEAN,
  avoidance_strategy    VARCHAR(255),
  manoeuvring_strategy  VARCHAR(255),
  three_axis_control    BOOLEAN,
  object_mass           DOUBLE PRECISION,
  ballistic_coefficient DOUBLE PRECISION,
  remaining_fuel        DOUBLE PRECISION,
  manned                BOOLEAN,
  dimensions            VARCHAR(255),
  created_at            TIMESTAMP           NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMP           NOT NULL DEFAULT NOW(),
  -- Approvals
  validation_status     validation_status NOT NULL DEFAULT 'Pending',
  original_id           INT ,
  CONSTRAINT fk_organisation FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE CASCADE
);

CREATE INDEX idx_registered_object_org ON registered_objects (organisation_id);

COMMENT ON COLUMN registered_objects.manoeuvre_latency IS
  'Time between manoeuvre assignment and execution in seconds, assuming nominal ground station availability';
COMMENT ON COLUMN registered_objects.defunct IS
  'Space object is no longer functional';
COMMENT ON COLUMN registered_objects.object_mass IS
  'Mass in kg';
COMMENT ON COLUMN registered_objects.ballistic_coefficient IS
  'Ballistic coefficient in m^2/kg';
COMMENT ON COLUMN registered_objects.remaining_fuel IS
  'Remaining fuel in kg';
COMMENT ON COLUMN registered_objects.data_sharing_policy IS
  'Data sharing policy to apply for this specific object. Overwrites the globally defined data sharing policy.';
COMMENT ON COLUMN registered_objects.validation_status IS
  'Objects need to be validated by a system adminsitrator.';
COMMENT ON COLUMN registered_objects.original_id IS
  'If this row is an update to an existing object, reference that object.';

CREATE TYPE catalogue_name AS ENUM ('Cospar', 'Satcat', 'Almanac', 'NasaDsn', 
  'EsaEsac', 'Ison', 'Russia', 'Unoosa', 'Leolabs', 'Comspoc');

COMMENT ON TYPE catalogue_name IS 'Registered catalogues according to https://sanaregistry.org/r/cdm_catalog/.'
  'COSPAR: International designator assigned by USSPACECOM (aka NSSDCA ID/COSPAR ID).'
  'SATCAT: United States Strategic Command (USSTRATCOM) satellite catalog (aka NORAD).'
  'ALMANAC: French satellite catalog.'
  'NASA_DSN: NASA Deep Space Network listing of spacecraft numbers.'
  'ESA_ESAC: European Space Agency catalog of space objects.'
  'ISON: International Scientific Optical Network.'
  'RUSSIA: Russian Military catalog of space objects.'
  'UNOOSA: United Nations Office for Outer Space Affairs register of space objects.'
  'LEOLABS: LeoLabs catalog of space objects.'
  'COMSPOC: Commercial Space Operations Center, operated by Analytical Graphics, Inc.';

CREATE TABLE object_designators
(
  id                   SERIAL PRIMARY KEY,
  registered_object_id INT,
  catalogue            catalogue_name NOT NULL,
  designator           VARCHAR(50)  NOT NULL,
  name                 varchar(255) NOT NULL DEFAULT '',
  CONSTRAINT fk_registered FOREIGN KEY (registered_object_id) REFERENCES registered_objects (id),
  CONSTRAINT uq_catalogue UNIQUE (catalogue, designator)
);

COMMENT ON COLUMN object_designators.registered_object_id IS
  'Mapped if the space object has been registered, otherwise NULL';
COMMENT ON COLUMN object_designators.designator IS
  'Space object designator used by the catalogue';


-- Give access to the application user, the application user has no access to 
-- The sessions table and therefore cannot fake a login.
GRANT SELECT, INSERT, UPDATE ON registered_objects, object_designators TO trace_application;
GRANT USAGE, SELECT ON registered_objects_id_seq, object_designators_id_seq TO trace_application;

-- Give access to the readonly user
GRANT SELECT ON registered_objects, object_designators TO trace_readonly;
GRANT SELECT ON registered_objects_id_seq, object_designators_id_seq TO trace_readonly;

-- Manage the updated_at column
SELECT updated_at('registered_objects');

-- migrate:down
DROP TABLE object_designators;
DROP TABLE registered_objects;
DROP TYPE catalogue_name;
DROP TYPE validation_status;