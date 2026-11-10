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
DROP VIEW IF EXISTS tWeight CASCADE;
DROP VIEW IF EXISTS sPerc CASCADE;
DROP VIEW IF EXISTS GraderStats CASCADE;
DROP VIEW IF EXISTS Qualifying CASCADE;
DROP VIEW IF EXISTS Decreasing CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW tWeight AS
SELECT assignment_id, SUM(weight) AS total_weight
FROM RubricItem
GROUP BY assignment_id;

CREATE VIEW sPerc AS
SELECT gr.username AS grader, g.assignment_id, g.group_id, (r.mark / w.total_weight) * 100 AS percent
FROM Grader gr
	JOIN AssignmentGroup g ON g.group_id = gr.group_id
	JOIN tWeight w ON w.assignment_id = g.assignment_id
	JOIN Membership m ON m.group_id = g.group_id
	JOIN Result r ON r.group_id = g.group_id;

CREATE VIEW GraderStats AS
SELECT grader, assignment_id,
       count(DISTINCT group_id) AS num_groups,
       avg(percent) AS avg_percent
FROM sPerc
GROUP BY grader, assignment_id;

CREATE VIEW Qualifying AS
SELECT s.grader, s.assignment_id, s.avg_percent,
       lag(s.avg_percent) OVER (PARTITION BY s.grader
                                ORDER BY a.due_date) AS prev_avg
FROM GraderStats s 
	JOIN Assignment a ON a.assignment_id = s.assignment_id
WHERE s.num_groups >= 10;

CREATE VIEW Decreasing AS
SELECT DISTINCT grader
FROM Qualifying
WHERE prev_avg IS NOT NULL AND avg_percent <= prev_avg;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO Q2
SELECT u.username as grader_username, 
	   u.firstname || ' ' || u.surname,
	   avg(q.avg_percent),
	   max(q.avg_percent) - min(q.avg_percent)
FROM Qualifying q
     JOIN MarkusUser u ON u.username = q.grader
WHERE q.grader NOT IN (SELECT grader FROM Decreasing)
GROUP BY u.username, u.firstname, u.surname
HAVING count(*) = (SELECT count(*) FROM Assignment);