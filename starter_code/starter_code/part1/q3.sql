-- Solo superior

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS Q3 CASCADE;

CREATE TABLE Q3 (
	assignment_id integer NOT NULL,
	description varchar(100) NOT NULL,
	num_solo integer NOT NULL,
	average_solo real NOT NULL,
	num_collaborators integer NOT NULL,
	average_collaborators real NOT NULL,
	average_students_per_group real NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS IntermediateStep CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW IntermediateStep AS ... ;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO Q3
