PRAGMA foreign_keys = ON;
PRAGMA synchronous = OFF;

CREATE TABLE censors (
	id		INTEGER PRIMARY KEY,
	entity		TEXT NOT NULL,
	location	TEXT
);
CREATE UNIQUE INDEX idx_censors_id ON censors(id);
CREATE UNIQUE INDEX idx_censors_entity_location ON censors(entity, location);

CREATE TABLE requests (
	id		INTEGER PRIMARY KEY,
	date		DATE,
	end		DATE,
	by		INTEGER NOT NULL
				REFERENCES censors(id)
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	description	TEXT,
	attachment	TEXT,
	notes		TEXT
);
CREATE UNIQUE INDEX idx_requests_id ON requests(id);

-- Useless "id" column added for the benefit of Dancer::Plugin::SimpleCRUD
CREATE TABLE domains (
	id		INTEGER PRIMARY KEY,
	request		INTEGER NOT NULL
				REFERENCES requests(id)
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	name		TEXT NOT NULL,
	also_ip		BOOLEAN,
	also_future_ip	BOOLEAN,
	notes		TEXT,
	test_url	TEXT
);
CREATE INDEX idx_domains_request ON domains(request);
CREATE INDEX idx_domains_name    ON domains(name);
CREATE UNIQUE INDEX idx_domains_request_name ON domains(request, name);

-- Useless "id" column added for the benefit of Dancer::Plugin::SimpleCRUD
CREATE TABLE links (
	id		INTEGER PRIMARY KEY,
	request		INTEGER NOT NULL
				REFERENCES requests(id)
				ON DELETE CASCADE
				ON UPDATE CASCADE,
	url		TEXT NOT NULL,
	description	TEXT
);
CREATE INDEX idx_links_request ON links(request);

-- BEGIN TRANSACTION;
-- INSERT INTO links2(request,url) SELECT request,url FROM links;
-- DROP TABLE links;
-- ALTER TABLE links2 RENAME TO links; 
-- COMMIT;

-- rm -f censorship.sqlite; sqlite3 censorship.sqlite < censorship.sql

