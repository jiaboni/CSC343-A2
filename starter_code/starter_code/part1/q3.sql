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
DROP VIEW IF EXISTS details CASCADE;
DROP VIEW IF EXISTS incomplete CASCADE;
DROP VIEW IF EXISTS countMembers CASCADE;
DROP VIEW IF EXISTS tWeight CASCADE;


-- Define views for your intermediate steps here:

CREATE VIEW tWeight AS
SELECT assignment_id, SUM(weight) AS total_weight
FROM RubricItem
GROUP BY assignment_id;

CREATE VIEW countMembers AS
SELECT group_id,
	   COUNT(username) AS nMembers
FROM Membership m
GROUP BY group_id;

CREATE VIEW incomplete AS
SELECT DISTINCT g.assignment_id
FROM AssignmentGroup g
     LEFT JOIN Result r ON r.group_id = g.group_id
WHERE r.group_id IS NULL;

CREATE VIEW details AS
SELECT g.assignment_id,
       SUM(CASE WHEN m.nMembers = 1 THEN 1 ELSE 0 END) AS nSolo,
       AVG(CASE WHEN m.nMembers = 1 THEN (r.mark / w.total_weight) * 100 END) AS avgSolo,
       SUM(CASE WHEN m.nMembers > 1 THEN m.nMembers ELSE 0 END) AS nCollab,
       AVG(CASE WHEN m.nMembers > 1 THEN (r.mark / w.total_weight) * 100 END) AS avgGroup,
       AVG(m.nMembers) AS avgGroupSize
FROM countMembers m
     JOIN AssignmentGroup g ON g.group_id = m.group_id
     JOIN tWeight w ON w.assignment_id = g.assignment_id
     JOIN Result r ON r.group_id = g.group_id
WHERE g.assignment_id NOT IN (SELECT assignment_id FROM incomplete)
GROUP BY g.assignment_id
HAVING SUM(CASE WHEN m.nMembers = 1 THEN 1 ELSE 0 END) >= 1
   AND SUM(CASE WHEN m.nMembers > 1 THEN 1 ELSE 0 END) >= 1;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO Q3
SELECT a.assignment_id, a.description, d.nSolo, d.avgSolo,
       d.nCollab, d.avgGroup, d.avgGroupSize
FROM details d
     JOIN Assignment a ON a.assignment_id = d.assignment_id
WHERE d.avgSolo > d.avgGroup;