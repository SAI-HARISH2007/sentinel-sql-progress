-- =============================================================================
-- Week 2 — LAB PRACTICE ASSIGNMENT (from the lab manual, "Experiment 2: DDL COMMANDS")
-- Uses its own database `lab_practice`, so it never touches `sentinel`.
-- Run:  mysql -uroot -p < lab-practice/ddl_employee.sql
-- Manual wording in quotes. MySQL differences from the manual are marked  [MySQL].
-- =============================================================================
DROP DATABASE IF EXISTS lab_practice;
CREATE DATABASE lab_practice;
USE lab_practice;

-- 1. "Create a table EMPLOYEE with following schema:
--     (S.No, Emp_no, E_name, E_address, E_ph_no, Dept_no, Dept_name, Job_id, Salary)"
--    [MySQL] a column name cannot contain a dot, so S.No becomes S_No.
--    Job_id starts as CHAR because question 3 changes it. Dept_no is text because later questions use values like 'D10'.
CREATE TABLE EMPLOYEE (
    S_No      INT,
    Emp_no    INT,
    E_name    VARCHAR(30),
    E_address VARCHAR(50),
    E_ph_no   VARCHAR(15),
    Dept_no   VARCHAR(5),
    Dept_name VARCHAR(20),
    Job_id    CHAR(10),
    Salary    DECIMAL(10,2)
);
DESCRIBE EMPLOYEE;

-- 2. "Add a new column; HIREDATE to the existing relation."
ALTER TABLE EMPLOYEE ADD COLUMN HIREDATE DATE;

-- 3. "Change the datatype of JOB_ID from char to varchar2."
--    [MySQL] there is no VARCHAR2 (that is Oracle). Use VARCHAR.
ALTER TABLE EMPLOYEE MODIFY Job_id VARCHAR(10);

-- 4. "Change the name of column/field Emp_no to E_no."
ALTER TABLE EMPLOYEE RENAME COLUMN Emp_no TO E_no;

-- 5. "Modify the column width of the job field of emp table."
--    (the table is EMPLOYEE at this point; EMP does not exist yet)
ALTER TABLE EMPLOYEE MODIFY Job_id VARCHAR(25);

-- 6. "Remove the column S.No from the relation."
ALTER TABLE EMPLOYEE DROP COLUMN S_No;

-- 7. "Change the table name EMPLOYEE to EMP_INFO."
RENAME TABLE EMPLOYEE TO EMP_INFO;

-- 8. "Create a dummy table EMP like EMP_INFO table."
CREATE TABLE EMP LIKE EMP_INFO;

-- 9. "Test the truncate and drop command on EMP table."
INSERT INTO EMP (E_no, E_name) VALUES (1, 'temp');
SELECT * FROM EMP;          -- 1 row
TRUNCATE TABLE EMP;
SELECT * FROM EMP;          -- empty, structure still there
DESCRIBE EMP;
DROP TABLE EMP;
SHOW TABLES;                -- only EMP_INFO is left

DROP DATABASE lab_practice;
