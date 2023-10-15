-- The following script creates the EMPLOYEES table with 1000 entries.
CREATE TABLE employees (
   employee_id   NUMERIC       NOT NULL,
   first_name    VARCHAR(1000) NOT NULL,
   last_name     VARCHAR(1000) NOT NULL,
   date_of_birth DATE                  ,
   phone_number  VARCHAR(1000) NOT NULL,
   junk          CHAR(1000)            ,
   CONSTRAINT employees_pk PRIMARY KEY (employee_id)
);

CREATE FUNCTION random_string(minlen NUMERIC, maxlen NUMERIC)
RETURNS VARCHAR(1000)
AS
$$
DECLARE
  rv VARCHAR(1000) := '';
  i  INTEGER := 0;
  len INTEGER := 0;
BEGIN
  IF maxlen < 1 OR minlen < 1 OR maxlen < minlen THEN
    RETURN rv;
  END IF;

  len := floor(random()*(maxlen-minlen)) + minlen;

  FOR i IN 1..floor(len) LOOP
    rv := rv || chr(97+CAST(random() * 25 AS INTEGER));
  END LOOP;
  RETURN rv;
END;
$$ LANGUAGE plpgsql;
INSERT INTO employees (employee_id,  first_name,
                       last_name,    date_of_birth,
                       phone_number, junk)
SELECT GENERATE_SERIES
     , initcap(lower(random_string(2, 8)))
     , initcap(lower(random_string(2, 8)))
     , CURRENT_DATE - CAST(floor(random() * 365 * 10 + 40 * 365) AS NUMERIC) * INTERVAL '1 DAY'
     , CAST(floor(random() * 9000 + 1000) AS NUMERIC)
     , 'junk'
  FROM GENERATE_SERIES(1, 1000);
UPDATE employees
   SET first_name='MARKUS',
       last_name='WINAND'
 WHERE employee_id=123;
VACUUM ANALYZE employees;

-- This script changes the EMPLOYEES table so that it reflects the situation after the merger with Very Big Company:

-- add subsidiary_id and update existing records
ALTER TABLE employees ADD subsidiary_id NUMERIC;
UPDATE      employees SET subsidiary_id = 30;
ALTER TABLE employees ALTER COLUMN subsidiary_id SET NOT NULL;

-- change the PK
ALTER TABLE employees DROP CONSTRAINT employees_pk;
ALTER TABLE employees ADD CONSTRAINT employees_pk
      PRIMARY KEY (employee_id, subsidiary_id);

-- generate more records (Very Big Company)
INSERT INTO employees (employee_id,  first_name,
                       last_name,    date_of_birth,
                       phone_number, subsidiary_id, junk)
SELECT GENERATE_SERIES
     , initcap(lower(random_string(2, 8)))
     , initcap(lower(random_string(2, 8)))
     , CURRENT_DATE - CAST(floor(random() * 365 * 10 + 40 * 365) AS NUMERIC) * INTERVAL '1 DAY'
     , CAST(floor(random() * 9000 + 1000) AS NUMERIC)
     , CAST(floor(random() * (generate_series)/9000*29) AS NUMERIC)
     , 'junk'
  FROM GENERATE_SERIES(1, 9000);

VACUUM ANALYZE employees;

-- The next script introduces the index on SUBSIDIARY_ID to support the query for all employees of one particular subsidiary:
CREATE INDEX emp_sub_id ON employees (subsidiary_id);

-- Although that gives decent performance, it’s better to use the index that supports the primary key:

-- use tmp index to support the PK
CREATE UNIQUE INDEX employee_pk_tmp
    ON employees (subsidiary_id, employee_id);

 ALTER TABLE employees
   ADD CONSTRAINT employees_pk_tmp
UNIQUE (subsidiary_id, employee_id);

ALTER TABLE employees
 DROP CONSTRAINT employees_pk;

ALTER TABLE employees
  ADD CONSTRAINT employees_pk
      PRIMARY KEY (subsidiary_id, employee_id);

ALTER TABLE employees
 DROP CONSTRAINT employees_pk_tmp;

-- drop old indexes
DROP INDEX employee_pk_tmp;
DROP INDEX emp_sub_id;
