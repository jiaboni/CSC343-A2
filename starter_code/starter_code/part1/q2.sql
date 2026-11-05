-- Getting soft

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS Q2 CASCADE;

CREATE TABLE Q2 (
	grader_username varchar(25) NOT NULL,
	grader_name varchar(100) NOT NULL,
	average_mark_all_assignments real NOT NULL,
	mark_change_first_last real NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS IntermediateStep CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW IntermediateStep AS ... ;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO Q2
