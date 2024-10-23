CREATE TABLE taxa (
    id INT PRIMARY KEY,
    is_active BOOL NOT NULL,
    name STRING NOT NULL,
    parent_id INT,
    preferred_common_name STRING,
    rank STRING NOT NULL
    -- FOREIGN KEY (parent_id) REFERENCES taxa (id)
);

CREATE TABLE observations (
    id INT PRIMARY KEY,
    created_at TIMESTAMP NOT NULL,
    description STRING,
    taxon_id INT,
    time_observed_at TIMESTAMPTZ,
    uri STRING NOT NULL,
    uuid UUID NOT NULL
    -- FOREIGN KEY (taxon) REFERENCES taxa (id)
);

CREATE TABLE observation_photos (
    id INT PRIMARY KEY,
    observation_id INT NOT NULL,
    position SMALLINT NOT NULL,
    
    attribution STRING NOT NULL,
    original_dimensions STRUCT(height USMALLINT, width USMALLINT),
    photo_id INT NOT NULL,
    url STRING NOT NULL
    -- FOREIGN KEY (observation_id) REFERENCES observations (id)
);
