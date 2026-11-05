-- Steady work

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS Q4 CASCADE;

CREATE TABLE Q4 (
	group_id integer NOT NULL,
	first_file varchar(25) DEFAULT NULL,
	first_time timestamp DEFAULT NULL,
	first_submitter varchar(25) DEFAULT NULL,
	last_file varchar(25) DEFAULT NULL,
	last_time timestamp DEFAULT NULL,
	last_submitter varchar(25) DEFAULT NULL,
	elapsed_time interval DEFAULT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS IntermediateStep CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW IntermediateStep AS ... ;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO Q4
