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
DROP VIEW IF EXISTS tWeight CASCADE;
DROP VIEW IF EXISTS gPercent CASCADE;



-- Define views for your intermediate steps here:
CREATE VIEW tWeight AS
SELECT assignment_id, SUM(weight) AS total_weight
FROM RubricItem
GROUP BY assignment_id;

CREATE VIEW gPercent AS
SELECT g.assignment_id, g.group_id, (r.mark / w.total_weight) * 100 AS percent
FROM AssignmentGroup g
	JOIN tWeight w ON w.assignment_id = g.assignment_id
	JOIN Result r ON r.group_id = g.group_id;



-- Your query that answers the question goes below the "insert into" line:
INSERT INTO Q1
SELECT a.assignment_id,
	   AVG(p.percent) AS average_mark_percent,
	   SUM(CASE WHEN p.percent >= 80 THEN 1 ELSE 0 END) AS num_80_100,
	   SUM(CASE WHEN p.percent >= 60 AND p.percent < 80 THEN 1 ELSE 0 END) AS num_60_79,
	   SUM(CASE WHEN p.percent >= 50 AND p.percent < 60 THEN 1 ELSE 0 END) AS num_50_59,
	   SUM(CASE WHEN p.percent < 50 THEN 1 ELSE 0 END) AS num_0_49
FROM Assignment a
	LEFT JOIN gPercent p ON p.assignment_id = a.assignment_id
GROUP BY a.assignment_id;
