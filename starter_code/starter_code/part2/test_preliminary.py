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

This file contains preliminary tests for A2.
"""
import pytest
from a2 import *
from psycopg2 import sql
from psycopg2.extras import execute_values


# TODO: Change the values of the following variables to connect to your
#  own database:
DB_NAME = "csc343h-username"
USER = "username"
PASSWORD = ""
# The following uses the relative paths to the schema file and the data file
# we have provided. For your own tests, you will want to make your own data
# files to use for testing.
SCHEMA_FILE = "../schema.ddl"
SAMPLE_DATA = "../data.sql"


def setup(schema_path: str, data_path: str) -> None:
    """Set up the testing environment by importing the schema file
    at <schema_path> and the file containing the data at <data_path>.

    <schema_path> and <data_path> are the relative/absolute paths to the files
    containing the schema and the data respectively.
    """
    connection, cursor, schema_file, data_file = None, None, None, None
    try:
        connection = pg.connect(
            dbname=DB_NAME, user=USER, password=PASSWORD,
            options="-c search_path=markus"
        )
        cursor = connection.cursor()

        with open(schema_path, "r") as schema_file:
            cursor.execute(schema_file.read())

        with open(data_path, "r") as info_file:
            cursor.execute(info_file.read())

        connection.commit()
    except Exception as ex:
        connection.rollback()
        raise Exception(f"Couldn't set up environment for tests: \n{ex}")
    finally:
        if cursor and not cursor.closed:
            cursor.close()
        if connection and not connection.closed:
            connection.close()


def get_rows(table_name: str) -> Optional[list[tuple]]:
    """Return the contents of the table <table_name> under our Markus
    schema.
    """
    conn, cur = None, None
    try:
        conn = pg.connect(
            dbname=DB_NAME, user=USER, password=PASSWORD,
            options="-c search_path=markus"
        )
        cur = conn.cursor()
        cur.execute(sql.SQL("SELECT * FROM {}").format(
            sql.Identifier(table_name.lower())))
        return [elem for elem in cur.fetchall()]
    except pg.Error as ex:
        conn.rollback()
        raise Exception(f"Couldn't retrieve data from table {table_name}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


def insert_rows(table_name: str, rows: list[tuple]) -> bool:
    """Insert the tuples <rows> in table <table_name> under our Markus
    schema. Return False if an error occurs.
    """
    conn, cur = None, None
    try:
        conn = pg.connect(
            dbname=DB_NAME, user=USER, password=PASSWORD,
            options="-c search_path=markus"
        )
        cur = conn.cursor()
        insert_query = sql.SQL("INSERT INTO {} VALUES %s").format(
            sql.Identifier(table_name.lower()))
        execute_values(cur, insert_query, rows)
    except pg.Error:
        conn.rollback()
        raise Exception(f"Couldn't populate table {table_name}")
    else:
        conn.commit()
        return True
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


def test_remove_student() -> None:
    """Test basic aspects of the A2 remove_student method.
    """
    a2 = Markus()
    try:
        # The following function call will set up the testing environment by
        # loading a fresh copy of the schema and the sample data we have
        # provided into your database. You can create more sample data files
        # and call the same function to load them into your database.
        setup(SCHEMA_FILE, SAMPLE_DATA)

        connected = a2.connect(DB_NAME, USER, PASSWORD)

        # The following is an assert statement. It checks that the value for
        # connected is True. The message after the comma will be printed if
        # that is not the case (that is, if connected is False).
        # Use the same notation throughout your testing.
        assert connected, f"[Connect] Expected True | Got {connected}."

        # TODO: Add more test cases here, or better yet, make more testing
        #   functions, each testing a different aspect of the code.

        # ---------------------- Testing remove_student ---------------------- #

        # Note: These results assume that the instance has already been
        # populated with the provided data e.g., using the setup function.

        # TEST: Invalid Student.
        before = get_rows("Membership")
        num_removed = a2.remove_student('hagrid', dt.date(2025, 10, 1))
        assert num_removed == -1, \
            f"[Remove Student] Expected: -1. Got {num_removed}."

        # You can manually compare the contents of each relation before and
        # after the update. Here, I am instead using the provided function
        # get_rows to compare relation Membership only before and after
        # the method call to provide an example of how to use it.
        after = get_rows("Membership")
        assert sorted(before) == sorted(after), \
            f"[Remove Student] Content of Membership table changed."

        # TEST: Valid Student, but not a member of any relevant groups.
        before = get_rows("Membership")
        num_removed = a2.remove_student('potterh3', dt.date(2025, 12, 5))
        assert num_removed == 0, \
            f"[Remove Student] Expected: 0. Got {num_removed}."

        after = get_rows("Membership")
        assert sorted(before) == sorted(after), \
            f"[Remove Student] Content of Membership table changed."

        # TEST: Valid Student, and a member of a relevant group.
        num_removed = a2.remove_student('potterh3', dt.date(2025, 11, 12))
        assert num_removed == 1, \
            f"[Remove Student] Expected: 1. Got {num_removed}."

        expected_after = [
            # A1 - unchanged
            ('potterh3', 1), ('grangerh1', 2), ('malfoyd1', 3),
            ('lovegoodl4', 4), ('diggoryc2', 5),
            # A2
            ('weaslyr30', 6), ('grangerh1', 6), ('lovegoodl4', 7)]
        actual_after = get_rows("Membership")
        assert sorted(actual_after) == sorted(expected_after), \
            "[Remove Student] Membership content is incorrect."
    finally:
        a2.disconnect()


def test_create_groups() -> None:
    """Test basic aspects of the A2 create_groups method.
    """
    a2 = Markus()
    try:
        # The following function call will set up the testing environment by
        # loading a fresh copy of the schema and the sample data we have
        # provided into your database. You can create more sample data files
        # and call the same function to load them into your database.
        setup(SCHEMA_FILE, SAMPLE_DATA)

        connected = a2.connect(DB_NAME, USER, PASSWORD)

        # The following is an assert statement. It checks that the value for
        # connected is True. The message after the comma will be printed if
        # that is not the case (that is, if connected is False).
        # Use the same notation throughout your testing.
        assert connected, f"[Connect] Expected True | Got {connected}."

        # TODO: Add more test cases here, or better yet, make more testing
        #   functions, each testing a different aspect of the code.

        # ----------------------- Testing create_groups ---------------------- #

        # TEST: Invalid target assignment to group.
        # You should check that no modifications were made to the db, either
        # manually or using the provided get_rows function, as shown in
        # the remove_student tests.
        groups_created = a2.create_groups(40, 1, 'markus343f')
        assert groups_created is False, \
            f"[Create Groups] Expected: False. Got {groups_created}."

        # TEST: Valid assignment IDs.
        before_groups = get_rows("AssignmentGroup")
        before_membership = get_rows("Membership")

        groups_created = a2.create_groups(3, 1, 'markus343f')
        assert groups_created is True, \
            f"[Create Groups] Expected: True. Got {groups_created}."

        new_groups = [
            (9, 3, "markus343f/group_9"), (10, 3, "markus343f/group_10"),
            (11, 3, "markus343f/group_11")]
        expected_groups = before_groups + new_groups
        actual_groups = get_rows("AssignmentGroup")
        assert sorted(actual_groups) == sorted(expected_groups), \
            f"[Create Groups] AssignmentGroup content is incorrect."

        new_membership = [
            ("grangerh1", 9), ("potterh3", 9),
            ("diggoryc2", 10), ("malfoyd1" ,10),
            ("lovegoodl4", 11), ("weaslyr30", 11)
        ]
        expected_membership = before_membership + new_membership
        actual_membership = get_rows("Membership")
        assert sorted(actual_membership) == sorted(expected_membership), \
            f"[Create Groups] Membership content is incorrect."
    finally:
        a2.disconnect()


if __name__ == "__main__":
    pytest.main()