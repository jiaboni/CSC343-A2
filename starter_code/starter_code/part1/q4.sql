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
DROP VIEW IF EXISTS flTimes CASCADE;
DROP VIEW IF EXISTS participatingGroups CASCADE;



-- Define views for your intermediate steps here:
CREATE VIEW participatingGroups AS
SELECT group_id
FROM AssignmentGroup g
	 JOIN Assignment s ON s.assignment_id = g.assignment_id
WHERE 
	description = 'A1';

CREATE VIEW flTimes AS 
SELECT s.group_id,
	   MIN(submission_date) AS firstTime,
	   MAX(submission_date) AS lastTime
FROM Submissions s
	JOIN participatingGroups g ON g.group_id = s.group_id
GROUP BY s.group_id;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO Q4
SELECT g.group_id, 
	f.file_name AS first_file, 
	f.submission_date AS first_time, 
	f.username AS first_submitter,
	l.file_name AS last_file, 
	l.submission_date AS last_time, 
	l.username AS last_submitter,
	(l.submission_date - f.submission_date) AS elapsed_time
FROM participatingGroups g
	 LEFT JOIN flTimes flt ON flt.group_id = g.group_id 
	 LEFT JOIN Submissions f ON f.group_id = g.group_id 
	 	AND f.submission_date = flt.firstTime
	 LEFT JOIN Submissions l ON l.group_id = g.group_id 
	 	AND l.submission_date = flt.lastTime;