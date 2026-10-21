# Lab exam cheat sheet — MySQL syntax for experiments 1–9 (closed book, 60 minutes, 26–30 Oct 2026)

Order follows the 2026-27 handout's lab list. The lab *manual* gives Oracle-flavoured examples; the exam runs on **MySQL**. Learn the right-hand column.

## Oracle-isms in the manual that FAIL in MySQL

| Manual says (Oracle) | MySQL needs |
|---|---|
| `ALTER TABLE t MODIFY (col VARCHAR(10), col2 INT);` | `ALTER TABLE t MODIFY col VARCHAR(10);`  *(no brackets; one column per MODIFY, comma-separate several)* |
| `ALTER TABLE t DROP COLUMN (col);` | `ALTER TABLE t DROP COLUMN col;` |
| `ALTER TABLE t RENAME COLUMN (old) TO (new);` | `ALTER TABLE t RENAME COLUMN old TO new;`  *(8.0+; older: `CHANGE old new <type>`)* |
| `VARCHAR2(n)` | `VARCHAR(n)` |
| `RENAME t1 TO t2;` | `RENAME TABLE t1 TO t2;` |
| `CREATE TABLE new AS SELECT …` works in both | and MySQL adds `CREATE TABLE new LIKE old;` (structure only) |
| `NVL(x,0)`, `TO_CHAR(d,'DD-MON-YY')`, `SYSDATE` | `IFNULL(x,0)` / `COALESCE`, `DATE_FORMAT(d,'%d-%b-%y')`, `NOW()` *(`SYSDATE()` also exists, with brackets)* |
| `a \|\| b` (concatenate) | `CONCAT(a, b)`   *(in MySQL `\|\|` is logical OR: `SELECT 'a' \|\| 'b'` quietly returns 0, no error!)* |
| `MINUS` | `EXCEPT` *(8.0.31+)* |
| `WHERE ROWNUM <= 5` | `LIMIT 5` |
| `FULL OUTER JOIN` | not supported: `LEFT JOIN … UNION … RIGHT JOIN …` |
| `DESC table` | `DESCRIBE table;`  (`DESC table` also works, but `DESCRIBE` cannot be confused with ORDER BY ... DESC) |
| Column name `S.No` | `S_No` (a dot is not allowed in a name) |

## Exp 0/1 — Database, DDL
```sql
CREATE DATABASE shop;  SHOW DATABASES;  USE shop;  SHOW TABLES;  DROP DATABASE shop;
CREATE TABLE student (sno INT, sname CHAR(10), class CHAR(5));
ALTER TABLE student ADD address CHAR(10);
ALTER TABLE student MODIFY sname VARCHAR(30);
ALTER TABLE student RENAME COLUMN sname TO stu_name;
ALTER TABLE student DROP COLUMN address;
RENAME TABLE student TO std;           -- or  ALTER TABLE student RENAME TO std;
CREATE TABLE std2 LIKE std;
TRUNCATE TABLE std2;   DROP TABLE std2;
DESCRIBE std;   SHOW CREATE TABLE std;
```

## Exp 2 — Constraints
```sql
CREATE TABLE emp (
  eno   INT PRIMARY KEY AUTO_INCREMENT,
  ename VARCHAR(30) NOT NULL,
  email VARCHAR(50) UNIQUE,
  dno   INT,
  sal   DECIMAL(10,2) DEFAULT 10000 CHECK (sal >= 0),
  CONSTRAINT fk_dept FOREIGN KEY (dno) REFERENCES dept(dno) ON DELETE CASCADE
);
ALTER TABLE emp ADD PRIMARY KEY (eno);                   ALTER TABLE emp DROP PRIMARY KEY;
ALTER TABLE emp ADD CONSTRAINT uq_email UNIQUE (email);  ALTER TABLE emp DROP INDEX uq_email;
ALTER TABLE emp ADD CONSTRAINT chk_sal CHECK (sal > 0);  ALTER TABLE emp DROP CHECK chk_sal;
ALTER TABLE emp ADD CONSTRAINT fk_dept FOREIGN KEY (dno) REFERENCES dept(dno);
ALTER TABLE emp DROP FOREIGN KEY fk_dept;
ALTER TABLE emp ALTER COLUMN sal SET DEFAULT 5000;       ALTER TABLE emp ALTER COLUMN sal DROP DEFAULT;   -- afterwards every INSERT must supply sal (error 1364 otherwise)
ALTER TABLE emp MODIFY ename VARCHAR(30) NOT NULL;       ALTER TABLE emp MODIFY ename VARCHAR(30) NULL;
```
Error numbers worth recognising: **1062** duplicate key · **1048** column cannot be null · **1452** FK parent missing · **1451** cannot delete, child rows exist · **3819** CHECK violated.

## Exp 3 — DML
```sql
INSERT INTO emp (eno, ename) VALUES (1, 'Ravi');
INSERT INTO emp VALUES (2,'Mohan','m@x.com',10,40000), (3,'Rio','r@x.com',20,35000);
INSERT INTO emp_copy SELECT * FROM emp WHERE dno = 10;
UPDATE emp SET sal = sal * 1.1 WHERE dno = 10;           -- no WHERE = every row!
DELETE FROM emp WHERE ename = 'James';
SELECT * FROM emp;  SELECT ename, sal FROM emp WHERE dno = 'D10' ORDER BY sal DESC LIMIT 3;
```

## Exp 4 — Functions
```sql
-- number
ROUND(45.678,1)  CEIL(4.2)  FLOOR(4.8)  TRUNCATE(45.678,1)  MOD(10,3)  ABS(-5)  POWER(2,3)  SQRT(16)
-- aggregate (ignore NULLs, except COUNT(*))
COUNT(*)  COUNT(col)  COUNT(DISTINCT col)  SUM(col)  AVG(col)  MIN(col)  MAX(col)
-- string
UPPER(s) LOWER(s) LENGTH(s) CONCAT(a,b) SUBSTRING(s,2,3) LEFT(s,2) RIGHT(s,2) TRIM(s) REPLACE(s,'a','b') INSTR(s,'x') LPAD(s,8,'0') REVERSE(s)
-- date
NOW() CURDATE() DATE(ts) YEAR(d) MONTH(d) DAY(d) HOUR(ts) DAYNAME(d) DATEDIFF(d1,d2) DATE_ADD(d, INTERVAL 7 DAY) DATE_FORMAT(d,'%d-%m-%Y') TIMESTAMPDIFF(MINUTE, t1, t2)
```

## Exp 5 — Operators
```sql
-- arithmetic + - * / DIV %      comparison = <> != < > <= >= <=>      logical AND OR NOT XOR
WHERE sal BETWEEN 20000 AND 40000        WHERE dno IN (10, 20)       WHERE dno NOT IN (10)
WHERE ename LIKE 'R%'  /  '_a%'          WHERE email IS NULL         WHERE ename REGEXP '^R'
SELECT a FROM t1 UNION SELECT a FROM t2;     UNION ALL;     INTERSECT;     EXCEPT;
```

## Exp 6 — Joins
```sql
SELECT … FROM a INNER JOIN b ON a.k = b.k;
SELECT … FROM a LEFT  JOIN b ON a.k = b.k;       -- all of a
SELECT … FROM a RIGHT JOIN b ON a.k = b.k;       -- all of b
SELECT … FROM a LEFT JOIN b ON a.k=b.k UNION SELECT … FROM a RIGHT JOIN b ON a.k=b.k;   -- "full outer"
SELECT … FROM a NATURAL JOIN b;                  -- joins on every same-named column
SELECT … FROM a JOIN b USING (k);
SELECT e.ename, m.ename AS boss FROM emp e JOIN emp m ON m.eno = e.mgr;                  -- self join
SELECT … FROM a LEFT JOIN b ON a.k=b.k WHERE b.k IS NULL;                                -- rows with no match
```

## Exp 7 — GROUP BY, HAVING, ORDER BY
```sql
SELECT dno, COUNT(*) AS n, AVG(sal) FROM emp WHERE sal > 0 GROUP BY dno HAVING COUNT(*) > 2 ORDER BY n DESC;
```
Order of clauses: `SELECT … FROM … WHERE … GROUP BY … HAVING … ORDER BY … LIMIT`. Every non-aggregated SELECT column must appear in GROUP BY.

## Exp 8 — Views and indexes
```sql
CREATE VIEW high_paid AS SELECT eno, ename, sal FROM emp WHERE sal > 40000;
SELECT * FROM high_paid;     CREATE OR REPLACE VIEW …;     DROP VIEW high_paid;     SHOW FULL TABLES WHERE Table_type='VIEW';
CREATE INDEX idx_name ON emp (ename);          CREATE UNIQUE INDEX idx_email ON emp (email);
CREATE INDEX idx_dept_sal ON emp (dno, sal);   -- composite: leftmost-prefix rule
SHOW INDEX FROM emp;     DROP INDEX idx_name ON emp;     EXPLAIN SELECT * FROM emp WHERE ename='Ravi';
```

## Exp 9 — Procedures and triggers
```sql
DELIMITER //
CREATE PROCEDURE raise_salary(IN p_dno INT, IN p_pct DECIMAL(5,2))
BEGIN
    UPDATE emp SET sal = sal * (1 + p_pct/100) WHERE dno = p_dno;
    SELECT ROW_COUNT() AS rows_changed;
END //
DELIMITER ;
CALL raise_salary(10, 5);       DROP PROCEDURE raise_salary;

DELIMITER //
CREATE TRIGGER trg_emp_before_ins BEFORE INSERT ON emp
FOR EACH ROW
BEGIN
    IF NEW.sal < 0 THEN SET NEW.sal = 0; END IF;
    -- AFTER triggers log:  INSERT INTO log VALUES (NEW.eno, NOW());
END //
DELIMITER ;
SHOW TRIGGERS;     DROP TRIGGER trg_emp_before_ins;
```
`DELIMITER //` is a **client** command: it lets the `;` inside the body pass through. Forget it and you get error 1064.

## Transactions (TCL)
```sql
START TRANSACTION;  UPDATE …;  SAVEPOINT s1;  UPDATE …;  ROLLBACK TO s1;  COMMIT;     -- or ROLLBACK;
SET autocommit = 0;
```
DDL (CREATE/ALTER/DROP/TRUNCATE) commits implicitly and cannot be rolled back.

## Fast self-test
Open `week-05…` to `week-10…` `queries/` folders. Cover the SQL, read the comment, and write the query from memory in MySQL Workbench. If it differs from the file, work out why.
