-- Never solo by choice

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS Q5 CASCADE;

CREATE TABLE Q5 (
	username varchar(25) NOT NULL,
	group_average real DEFAULT NULL,
	solo_average real DEFAULT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS countMembers CASCADE;
DROP VIEW IF EXISTS tWeight CASCADE;
DROP VIEW IF EXISTS qualifying CASCADE;
DROP VIEW IF EXISTS grades CASCADE;



-- Define views for your intermediate steps here:
CREATE VIEW tWeight AS
SELECT assignment_id, SUM(weight) AS total_weight
FROM RubricItem
GROUP BY assignment_id;

CREATE VIEW countMembers AS
SELECT group_id,
	   COUNT(username) AS nMembers
FROM Membership
GROUP BY group_id;

CREATE VIEW qualifying AS 
SELECT s.username
FROM Submissions s
	JOIN AssignmentGroup g ON g.group_id = s.group_id
	JOIN Assignment a ON a.assignment_id = g.assignment_id
	JOIN countMembers c ON c.group_id = g.group_id
WHERE (a.group_max > 1 AND c.nMembers > 1) OR a.group_max = 1
GROUP BY s.username
HAVING 
	COUNT(DISTINCT g.assignment_id) = (SELECT COUNT(*) FROM Assignment);


CREATE VIEW grades AS
SELECT m.username, g.assignment_id,
       (r.mark / w.total_weight) * 100 AS percent
FROM Membership m
     JOIN AssignmentGroup g ON g.group_id = m.group_id
     JOIN Result r ON r.group_id = g.group_id
     JOIN tWeight w ON w.assignment_id = g.assignment_id;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO Q5
SELECT q.username,
       AVG(CASE WHEN a.group_max > 1 THEN g.percent END) AS group_average,
       AVG(CASE WHEN a.group_max = 1 THEN g.percent END) AS solo_average
FROM qualifying q
     LEFT JOIN grades g ON g.username = q.username
     LEFT JOIN Assignment a ON a.assignment_id = g.assignment_id
GROUP BY q.username;