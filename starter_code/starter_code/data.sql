SET SEARCH_PATH TO markus;


INSERT INTO 
	MarkusUser(username, surname, firstname, type) 
VALUES
	('potterh3', 'Harry', 'Potter', 'student'),
	('weaslyr30', 'Ron', 'Weasley', 'student'),
	('grangerh1', 'Hermoine', 'Granger', 'student'),
	('malfoyd1', 'Draco', 'Malfoy', 'student'),
	('lovegoodl4', 'Luna', 'Lovegood', 'student'),
	('diggoryc2', 'Cedric', 'Diggory', 'student'),
	('snapes', 'Severus', 'Snape', 'TA'),
	('lupinr4', 'Remus', 'Lupin', 'TA'),
	('dumbledore', 'Albus', 'Dumbledore', 'instructor'),
	('mcGonagall', 'Minerva', 'McGonagall', 'instructor');


INSERT INTO 
	Assignment(assignment_id, description, due_date, group_min, group_max)
VALUES
	(1, 'A1', '2025-10-10 23:59', 1, 1),
	(2, 'A2', '2025-11-13 23:59', 1, 3),
	(3, 'A3', '2025-12-05 23:59', 1, 2);


INSERT INTO
	Required(assignment_id, file_name)
VALUES
	(1, 'a1.py'),
	(2, 'a2.sql'),
	(2, 'a2.py'),
	(3, 'a3.txt');


INSERT INTO 
	AssignmentGroup(assignment_id, repo) 
VALUES
	-- A1
	(1, 'https://markus.teach.cs.toronto.edu/2025-09/courses/22/group_1'), -- group 1
	(1, 'https://markus.teach.cs.toronto.edu/2025-09/courses/22/group_2'), -- group 2
	(1, 'https://markus.teach.cs.toronto.edu/2025-09/courses/22/group_3'), -- group 3
	(1, 'https://markus.teach.cs.toronto.edu/2025-09/courses/22/group_4'), -- group 4
	(1, 'https://markus.teach.cs.toronto.edu/2025-09/courses/22/group_5'), -- group 5
	-- A2
	(2, 'https://markus.teach.cs.toronto.edu/2025-09/courses/22/group_6'), -- group 6
	(2, 'https://markus.teach.cs.toronto.edu/2025-09/courses/22/group_7'), -- group 7
	(2, 'https://markus.teach.cs.toronto.edu/2025-09/courses/22/group_8'); -- group 8
	 

INSERT INTO 
	Membership(username, group_id)
VALUES
	-- A1
	('potterh3', 1),
	('grangerh1', 2),
	('malfoyd1', 3),
	('lovegoodl4', 4),
	('diggoryc2', 5),
	-- A2
	('weaslyr30', 6),
	('grangerh1', 6),
	('lovegoodl4', 7),
	('potterh3', 8);


INSERT INTO
	Submissions(submission_id, file_name, username, group_id, submission_date)
VALUES
	-- A1
	(1, 'a1.py', 'potterh3', 1, '2025-10-07 11:00'),
	(2, 'a1.py', 'potterh3', 1, '2025-10-09 15:34'),
	(3, 'a1.py', 'grangerh1', 2, '2025-10-08 12:00'),
	(4, 'a1.py', 'malfoyd1', 3, '2025-10-10 23:30'),
	(5, 'a1.py', 'lovegoodl4', 4, '2025-10-10 18:05'),
	(6, 'a1.py', 'diggoryc2', 5, '2025-10-07 23:00'),
	(7, 'a1.py', 'diggoryc2', 5, '2025-10-11 11:00'),
	-- A2
	( 8, 'a2.py', 'weaslyr30',  6, '2025-11-01 17:30'),
	( 9, 'a2.sql', 'grangerh1', 6, '2025-11-01 17:30'),
	(10, 'a2.py', 'potterh3',  8, '2025-11-02 13:00');


INSERT INTO 
	Grader(group_id, username)
VALUES
	(1, 'snapes'),
	(2, 'lupinr4'),
	(3, 'dumbledore'),
	(4, 'lupinr4'),
	(5, 'snapes');


INSERT INTO
	RubricItem(rubric_id, assignment_id, name, out_of, weight)
VALUES
	-- A1
	(1, 1, 'Method 1', 10, 5),
	(2, 1, 'Method 2', 10, 4),
	(3, 1, 'Style', 15, 2),
	-- A2
	(4, 2, 'Query 1', 12, 0.25),
	(5, 2, 'Query 2', 12, 0.25),
	(6, 2, 'Methods', 12, 0.5);


INSERT INTO 
	Grade(group_id, rubric_id, grade)
VALUES
	-- A1
	-- Group 1
	(1, 1, 8),
	(1, 2, 9),
	(1, 3, 12),
	-- Group 2
	(2, 1, 10),
	(2, 2, 10),
	(2, 3, 12),
	-- Group 3
	(3, 1, 8),
	(3, 2, 7),
	(3, 3, 12),
	-- Group 4
	(4, 1, 8),
	(4, 2, 9);


INSERT INTO
	Result(group_id, mark, released)
VALUES
	(1, 9.2, true),
	(2, 10.6, false),
	(3, 8.4, true);
	



