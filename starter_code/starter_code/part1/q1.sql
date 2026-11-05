-- Distributions.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS Q1 CASCADE;

CREATE TABLE Q1 (
	assignment_id integer NOT NULL,
	average_mark_percent real DEFAULT NULL,
	num_80_100 integer NOT NULL,
	num_60_79 integer NOT NULL,
	num_50_59 integer NOT NULL,
	num_0_49 integer NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS IntermediateStep CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW IntermediateStep AS ... ;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO Q1
