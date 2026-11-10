"""CSC343 Assignment 2

=== CSC343 Fall 2026 ===
Department of Computer Science,
University of Toronto

This code is provided solely for the personal and private use of
students taking the CSC343 course at the University of Toronto.
Copying for purposes other than this use is expressly prohibited.
All forms of distribution of this code, whether as given or with
any changes, are expressly prohibited.

Authors: Diane Horton and Marina Tawfik

All of the files in this directory and all subdirectories are:
Copyright (c) 2026

=== Module Description ===

This file contains the Markus class.
"""
import datetime as dt
import psycopg2 as pg
import psycopg2.extensions as pg_ext
import psycopg2.extras as pg_extras
from typing import Optional


class Markus:
    """A class that can work with data conforming to the schema in schema.ddl.

    === Instance Attributes ===
    connection: connection to a PostgreSQL database of Markus-related
        information.

    Representation invariants:
    - The database to which <connection> holds a reference conforms to the
      schema in schema.ddl.
    """
    connection: Optional[pg_ext.connection]

    def __init__(self) -> None:
        """Initialize this Markus instance, with no database connection
        yet.
        """
        self.connection = None

    def connect(self, dbname: str, username: str, password: str) -> bool:
        """Establish a connection to the database <dbname> using the
        username <username> and password <password>, and assign it to the
        instance attribute <connection>. In addition, set the search path
        to markus.

        Return True if the connection was made successfully, False otherwise.
        I.e., do NOT throw an error if making the connection fails.

        >>> a2 = Markus()
        >>> # The following example will only work if you change the dbname
        >>> # and password to your own credentials.
        >>> a2.connect("csc343h-marinat", "marinat", "")
        True
        >>> # In this example, the connection cannot be made.
        >>> a2.connect("invalid", "nonsense", "incorrect")
        False
        """
        try:
            self.connection = pg.connect(
                dbname=dbname, user=username, password=password,
                options="-c search_path=markus"
            )
            return True
        except pg.Error:
            return False

    def disconnect(self) -> bool:
        """Close this instance's connection to the database.

        Return True if closing the connection was successful, False otherwise.
        I.e., do NOT throw an error if closing the connection fails.

        >>> a2 = Markus()
        >>> # The following example will only work if you change the dbname
        >>> # and password to your own credentials.
        >>> a2.connect("csc343h-marinat", "marinat", "")
        True
        >>> a2.disconnect()
        True
        """
        try:
            if self.connection and not self.connection.closed:
                self.connection.close()
            return True
        except pg.Error:
            return False

    def remove_student(self, username: str, date: dt.date) -> int:
        """Remove the student identified by <username> from all groups on
        assignments that have due date greater than (i.e., after) <date>.

        Return the number of groups the user was removed from, or -1 if the
        operation was unsuccessful, i.e. do NOT throw an error.

        The operation is considered unsuccessful if <username> is an invalid
        user or is not a student. Note: if <username> is a valid student but
        is not a member of any group, the operation is considered successful,
        but no deletion will occur.

        Make sure to delete any empty group(s) that result(s) from deleting the
        target memberships of <username>.

        Note: Compare the due date of an assignment on the precision of days.
        E.g., if <date> is 2023-09-01, an assignment due on 2023-09-01 23:59
        is not considered to be "after" that because it is not due on a later
        day.
        """
        # TODO - complete this method
        deletions = 0
        if self.connection:
            curr = self.connection.cursor()
            curr2 = self.connection.cursor()
        else:
            return -1
        try:
            curr.execute("SELECT * FROM MarkusUser WHERE username = %s AND type = 'student';", [username])
            if curr.rowcount == 0:
                curr.close()
                curr2.close()
                return -1
            # curr.execute("CREATE OR REPLACE VIEW AssignmentMembership AS " \
            #             "SELECT * FROM membership NATURAL JOIN assignmentgroup NATURAL JOIN assignment;")
            # curr.execute("SELECT group_id FROM AssignmentMembership WHERE due_date::DATE > %s;", [date])
            curr.execute("SELECT Membership.group_id FROM Membership NATURAL JOIN AssignmentGroup NATURAL JOIN Assignment WHERE due_date::DATE > %s AND Membership.username = %s;", [date, username])
            for row in curr:
                id = row[0]
                curr2.execute("DELETE FROM Membership WHERE group_id = %s AND username = %s;", [id, username])
                deletions += curr2.rowcount

                curr2.execute("SELECT * FROM Membership WHERE group_id = %s;", [id])
                if curr2.rowcount == 0:
                    curr2.execute("DELETE FROM AssignmentGroup WHERE group_id = %s;", [id])

                # curr2.execute("SELECT * FROM Membership WHERE group_id = %s AND username = %s;", [id, username])
                # if curr2.rowcount > 0:
                #     deletions += 1
                # curr2.execute("DELETE FROM Membership WHERE group_id = %s AND username = %s;", [id, username])
                # curr2.execute("SELECT * FROM Membership WHERE group_id = %s;", [id])
                # if curr2.rowcount == 0:
                #     curr2.execute("DELETE FROM AssignmentGroup WHERE group_id = %s;", [id])
            self.connection.commit()

            curr.close()
            curr2.close()
            return deletions

        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            if self.connection:
                self.connection.rollback()
                curr.close()
                curr2.close()
            return -1

    def create_groups(
        self, assignment_to_group: int, other_assignment: int, repo_prefix: str
    ) -> bool:
        """Create student groups for <assignment_to_group> based on their
        performance in <other_assignment>. The repository URL of all created
        groups will start with <repo_prefix>.

        Find all students who are defined in the Users table and put each of
        them into a group for <assignment_to_group>.
        Suppose there are n. Each group will be of the maximum size allowed for
        the assignment (call that k), except for possibly one group of smaller
        size if n is not divisible by k.

        Note: k may be as low as 1.

        The choice of which students to put together is based on their grades on
        <other_assignment>, as recorded in table Result. (It makes no difference
        whether the grades were released or not.)  Starting from the
        highest grade on <other_assignment>, the top k students go into one
        group, then the next k students go into the next, and so on. The last
        n % k students form a smaller group.

        Students with no grade recorded for <other_assignment> come at the
        bottom of the list, after students who received zero. When there is a
        tie for grade (or non-grade) on <other_assignment>, take students in
        order by username, using alphabetical order from A to Z.

        When a group is created, its group ID is generated automatically because
        the group_id attribute of table AssignmentGroup uses the next value in
        a SQL SEQUENCE. The value of a group's attribute repo is
            repoPrefix + "/group_" + group_id

        Return True if the operation is successful, and False Otherwise.
        I.e., do NOT throw an error. If the operation is unsuccessful, no
        changes should be made to the database.

        The operation is considered unsuccessful if one or more of the following
        is True:
            * There is no assignment with ID <assignment_to_group> or
              no assignment with ID <other_assignment>.
            * One or more group(s) have already been defined for
              <assignment_to_group>.

        Note: If there are no students in the db, define no groups for
        <assignment_to_group>) and return True; the operation is considered
        successful. No changes should be made to the db in this case.

        Precondition: The group_min for <assignment_to_group> is 1.
        """
        # TODO - complete this method

        if self.connection:
            curr = self.connection.cursor()
            curr2 = self.connection.cursor()
        else:
            return False

        try:

            curr.execute("SELECT * FROM MarkusUser WHERE type = 'student';")
            if curr.rowcount == 0:
                curr.close()
                curr2.close()
                return True
            curr.execute("SELECT * FROM Assignment WHERE assignment_id = %s;", [assignment_to_group])
            if curr.rowcount == 0:
                curr.close()
                curr2.close()
                return False
            curr.execute("SELECT * FROM Assignment WHERE assignment_id = %s;", [other_assignment])
            if curr.rowcount == 0:
                curr.close()
                curr2.close()
                return False
            curr.execute("SELECT * FROM AssignmentGroup WHERE assignment_id = %s;", [assignment_to_group])
            if curr.rowcount > 0:
                curr.close()
                curr2.close()
                return False

            curr.execute("SELECT group_max FROM Assignment WHERE assignment_id = %s;", [assignment_to_group])
            k = 1
            for row in curr:
                k = int(row[0])

            curr.execute("SELECT MarkusUser.username, a.mark FROM MarkusUser LEFT JOIN (" \
                        "SELECT Membership.username, mark FROM Membership " \
                        "NATURAL JOIN AssignmentGroup " \
                        "LEFT JOIN Result USING(group_id) WHERE AssignmentGroup.assignment_id = %s) a USING(username)" \
                        "WHERE MarkusUser.type = 'student' ORDER BY mark DESC NULLS LAST, MarkusUser.username;", [other_assignment])

            counter = 0 

            curr2.execute("SELECT nextval('group_id_seq');")

            group_id = 1
            for row in curr2:
                group_id = row[0]

            curr2.execute("INSERT INTO AssignmentGroup (group_id, assignment_id, repo) values (%s, %s, %s);", [group_id, assignment_to_group, repo_prefix + "/group_" + str(group_id)])
            
            for row in curr:
                if counter >= k:
                    counter = 0
                    curr2.execute("SELECT nextval('group_id_seq');")
                    for gid in curr2:
                        group_id = gid[0]
                    curr2.execute("INSERT INTO AssignmentGroup (group_id, assignment_id, repo) VALUES (%s, %s, %s);", [group_id, assignment_to_group, repo_prefix + "/group_" + str(group_id)])

                curr2.execute("INSERT INTO Membership VALUES (%s, %s);", [row[0], group_id])

                counter += 1

            curr.close()
            curr2.close()
            self.connection.commit()
            return True
            

            

        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            if self.connection:
                curr.close()
                curr2.close()
                self.connection.rollback()
            return False


if __name__ == "__main__":
    # Un comment-out the next two lines if you would like all the doctest
    # examples (see ">>>" in the method and class docstrings) to be run
    # and checked.
    # import doctest
    # doctest.testmod()

    # You can add testing code here or even better, add your tests in a
    # separate file like we do in test_preliminary.py.
    pass