-- =============================================================================
-- Week 4 — LAB PRACTICE ASSIGNMENT (from the lab manual, "Experiment 3: DML COMMANDS")
-- Own database `lab_practice`; never touches `sentinel`.
-- Run:  mysql -uroot -p < lab-practice/dml_employee.sql
-- =============================================================================
DROP DATABASE IF EXISTS lab_practice;
CREATE DATABASE lab_practice;
USE lab_practice;

-- "Create a table EMPLOYEE with following schema: (Emp_no, E_name, E_address, E_ph_no, Dept_no, Dept_name, Job_id, Salary)"
CREATE TABLE EMPLOYEE (
    Emp_no    INT,
    E_name    VARCHAR(30),
    E_address VARCHAR(50),
    E_ph_no   VARCHAR(15),
    Dept_no   VARCHAR(5),
    Dept_name VARCHAR(20),
    Job_id    VARCHAR(10),
    Salary    DECIMAL(10,2)
);

-- 1. "Insert at least 5 rows in the table."
INSERT INTO EMPLOYEE VALUES
    (11, 'Alice', 'Pune',      '9000000011', 'D10', 'MECH',  'ENG', 55000),
    (12, 'Bob',   'Mumbai',    '9000000012', 'D20', 'SALES', 'REP', 42000),
    (13, 'James', 'Delhi',     '9000000013', 'D20', 'SALES', 'MGR', 70000),
    (14, 'Priya', 'Hyderabad', '9000000014', 'D10', 'MECH',  'ENG', 58000),
    (15, 'Ravi',  'Chennai',   '9000000015', 'D30', 'HR',    'HRM', 48000);

-- 2. "Display all the information of EMP table."
SELECT * FROM EMPLOYEE;

-- 3. "Display the record of each employee who works in department D10."
SELECT * FROM EMPLOYEE WHERE Dept_no = 'D10';

-- 4. "Update the city of Emp_no-12 with current city as Nagpur."   (the city lives in E_address)
UPDATE EMPLOYEE SET E_address = 'Nagpur' WHERE Emp_no = 12;
SELECT Emp_no, E_name, E_address FROM EMPLOYEE WHERE Emp_no = 12;

-- 5. "Display the Employee Id and Employee Name who works in department MECH."
SELECT Emp_no, E_name FROM EMPLOYEE WHERE Dept_name = 'MECH';

-- 6. "Delete the information of employee James."
DELETE FROM EMPLOYEE WHERE E_name = 'James';

-- 7. "Display the complete record of employees working in SALES Department."
SELECT * FROM EMPLOYEE WHERE Dept_name = 'SALES';

-- 8. "Create a dummy table Emp and copy the records of EMPLOYEE table."
CREATE TABLE Emp LIKE EMPLOYEE;
INSERT INTO Emp SELECT * FROM EMPLOYEE;
SELECT * FROM Emp;

-- 9. "Create another dummy table Emp_Dum and copy only specific columns (Emp_no, E_name, Job_id) of EMPLOYEE table."
CREATE TABLE Emp_Dum (Emp_no INT, E_name VARCHAR(30), Job_id VARCHAR(10));
INSERT INTO Emp_Dum (Emp_no, E_name, Job_id) SELECT Emp_no, E_name, Job_id FROM EMPLOYEE;
SELECT * FROM Emp_Dum;

DROP DATABASE lab_practice;
