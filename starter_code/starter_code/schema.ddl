-- This code is provided solely for the personal and private use of students
-- taking CSC343 at the University of Toronto. Copying for purposes other
-- than this use is expressly prohibited.  All forms of distribution of this
-- code, whether as given or with any changes, are expressly prohibited.

-- Author: Diane Horton and Marina Tawfik

-- All of the files in this directory and all subdirectories are:
-- Copyright (c) 2026 Diane Horton and Marina Tawfik.

-- NOTE: we have included some constraints in a comment in cases where
-- enforcing the constraint using SQL would be costly. For all parts of A2,
-- you may assume that these constraints hold, unless we explicitly specify
-- otherwise.

DROP SCHEMA IF EXISTS Markus CASCADE;
CREATE SCHEMA Markus;
SET SEARCH_PATH TO Markus;

-- The possible values for the type of a MarkUs user.
CREATE TYPE UserType AS ENUM ('instructor', 'TA', 'student');

CREATE DOMAIN positiveInt AS smallint
    DEFAULT NULL
    CHECK (VALUE > 0);

CREATE DOMAIN positiveFloat AS real
    DEFAULT NULL
    CHECK (VALUE > 0.0);

-- A person who is registered as a MarkUs user.
-- <usernamr> is their MarkUs username.
CREATE TABLE MarkusUser (
    username varchar(25) PRIMARY KEY,
    surname varchar(15) NOT NULL,
    firstname varchar(15) NOT NULL,
    type usertype NOT NULL
);

-- A piece of work that has been assigned to all students.
-- <group_min> and <group_max> are the minimum and maximum number of
-- students allowed to work together on a group for the assignment.
CREATE TABLE Assignment (
    assignment_id integer PRIMARY KEY,
    description varchar(100) NOT NULL,
    due_date timestamp NOT NULL,
    group_min positiveInt NOT NULL,
    group_max positiveInt NOT NULL,
    CHECK (group_max >= group_min)
);

-- For the assignment with id <assignment_id>, a file called <file_name>
-- must be submitted. <file_name> includes the filename extension
-- (e.g., "project.py" rather than just "project").
CREATE TABLE Required (
    assignment_id integer REFERENCES Assignment ON DELETE CASCADE,
    file_name varchar(25),
    PRIMARY KEY (assignment_id, file_name)
);

-- The sequence to be used to generate group_ids
CREATE SEQUENCE group_id_seq
    AS bigint
    INCREMENT BY 1
    MINVALUE 1;

-- Group <group_id> has been declared for assignment <assignment_id>.
-- <repo> is the URL of the shared repository where the group's
-- submitted files are stored.
--
-- You may assume that:
--   * each assignment group includes at least one member, that is,
--      AssignmentGroup[group_id] \subseteq Membership[group_id]
CREATE TABLE AssignmentGroup (
    group_id bigint PRIMARY KEY DEFAULT nextval('group_id_seq'),
    assignment_id integer REFERENCES Assignment ON DELETE CASCADE,  
    repo varchar(100) NOT NULL
);

-- Markus user <username> is a member of group <group_id> for
-- assignment <assignment_id>.
--
-- You may assume that:
--   * the number of members for a group is in the interval 
--     [group_min, group_max] for the assignment
--   * all <username>s in Membership belong to a MarkusUser of
--     type 'student'.
--   * a <username> can't be a member of more than 1 group in the
--     the same assignment. 
CREATE TABLE Membership (
    username varchar(25) REFERENCES MarkusUser ON DELETE CASCADE,
    group_id integer REFERENCES AssignmentGroup ON DELETE CASCADE,
    PRIMARY KEY (username, group_id)
);

-- A file with name <file_name> was submitted for group <group_id> by
-- student <username> on date <submission_date>. This submission has
-- id <submission_id>.
--
-- Note that a student may submit non-required files.
CREATE TABLE Submissions (
    submission_id integer PRIMARY KEY,
    file_name varchar(25) NOT NULL,
    username varchar(25) NOT NULL, 
    group_id integer NOT NULL, 
    submission_date timestamp NOT NULL,
    UNIQUE (file_name, username, submission_date),
    FOREIGN KEY (username, group_id) REFERENCES Membership ON DELETE CASCADE
);

-- <username> identifies the TA or instructor who has been assigned to grade
-- the group with ID <group_id>.
--
-- You may assume that all <username>s in Grader belong to a MarkusUser of
-- type 'instructor' or 'TA'.
CREATE TABLE Grader (
    group_id integer PRIMARY KEY REFERENCES AssignmentGroup ON DELETE CASCADE,
    username varchar(25) NOT NULL REFERENCES MarkusUser ON DELETE CASCADE
);

-- An item in the grading rubric for an assignment.
-- <rubric_id> is the ID of this rubric item, <assignment_id> is the ID of
-- the assignment it belongs to, <name> is the name of the rubric item
-- (e.g., "choice of variable names"), <out_of> is the total possible marks
-- available for this rubric item, and <weight> is how much this rubric item
-- contributes to the overall grade for the assignment.
-- The weights for an assignment's rubric items do not have to sum to
-- any particular value.  However, a typical scenario might be to have them
-- sum to 100 or to 1.0.
CREATE TABLE RubricItem (
    rubric_id integer PRIMARY KEY,
    assignment_id integer NOT NULL REFERENCES Assignment ON DELETE CASCADE,
    name varchar(50) NOT NULL,
    out_of positiveInt NOT NULL,
    weight positiveFloat NOT NULL,
    UNIQUE (assignment_id, name)
);

-- The group with ID <group_ID> earned <grade> for the rubric item with ID
-- <rubric_id>.
-- 
-- You may assume that:
--   * <group_id> is a valid group for the assignment associated with 
--     <rubric_id>.
--   * <grade> is <= the value of <out_of> associated with <rubric_id>.
CREATE TABLE Grade (
    group_id integer REFERENCES AssignmentGroup ON DELETE CASCADE,
    rubric_id integer REFERENCES RubricItem ON DELETE CASCADE,
    grade positiveFloat NOT NULL,
    PRIMARY KEY (group_id, rubric_id)
);

--  The "total mark" that a group earned on an assignment is the weighted sum
--  of the group's grades on the rubric items for that assignment:
--      \sum_{rubric items} [ (group's grade / out_of grade) * weight ]
--  For example, assume that an assignment is graded on correctness 
--  out of 10 with a weight of .75, and style out of 4 with a weight of .25.
--  If a group earned 8 on correctness (of the 10 that it was marked out of)
--  and 2 on style (of the 4 that it was marked out of), then their "total 
--  mark" is:
--      (8 / 10 * 0.75) + (2 / 4 * 0.25) = 0.725
--  You can calculate the grade as a percentage, by dividing the "total mark"
--  by the sum of the weights then multiplying by 100. 
--  In the above example, the sum of the weights is 0.75 + 0.25 = 1 and so
--  the grade as percentage is:
--      (0.725 / 1) * 100 = 72.5%
-- 
-- The group with ID <group_id> earned the "total mark" <mark> on the 
-- assignment for which they are a group. <released> indicates whether or 
-- not the result has been made available for the group members to see on 
-- Markus. We store the "total mark" (as defined above), not a percentage.
-- 
-- You may assume that if a group has a value for mark recorded in this
-- table, then:
--  * There is a grade recorded for every rubric item for <group_id> 
--    in the Grade table, and grading for <group_id> is considerd "complete"
--    (regardless of the released attribute's value). 
--  * The grade was computed correctly from tables RubricItem and Grade, 
--    and is therefore consistent with those tables.
--
-- NOTE: It is possible to have a garde recorded for every rubric item 
-- for a group, without having a corresponding row in Result for the same
-- group. The "total mark" is recorded in Result when the grader deems the
-- grading "complete". 
CREATE TABLE Result (
    group_id integer PRIMARY KEY REFERENCES AssignmentGroup ON DELETE CASCADE,
    mark positiveFloat NOT NULL,
    released boolean DEFAULT false
);

