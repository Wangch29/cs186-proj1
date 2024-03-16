-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear 
  FROM people 
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst
  LIKE '% %'
  ORDER BY namefirst ASC, namelast ASC
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) AS avgheight, COUNT(*) as count
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) AS avgheight, COUNT(*) as count
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, h.yearid
  FROM people AS p
  JOIN HallofFame AS h ON p.playerid = h.playerid
  WHERE h.inducted = 'Y'
  ORDER BY h.yearid DESC, p.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, cp.schoolid, h.yearid
  FROM people AS p
  JOIN HallofFame AS h ON p.playerid = h.playerid
  JOIN CollegePlaying AS cp ON p.playerid = cp.playerid
  JOIN schools AS s ON cp.schoolid = s.schoolid
  WHERE h.inducted = 'Y' AND s.schoolState = 'CA'
  ORDER BY h.yearid DESC, s.schoolid ASC, p.playerid ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, cp.schoolid
  FROM HallofFame AS h
  JOIN people AS p ON p.playerid = h.playerid
  LEFT JOIN CollegePlaying AS cp ON p.playerid = cp.playerid
  WHERE h.inducted = 'Y'
  ORDER BY p.playerid DESC, cp.schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  WITH SLG AS (
    SELECT CAST((H + H2B + 2 * H3B + 3 * HR) AS FLOAT) / AB AS slg, playerid, yearid
    FROM batting
    WHERE batting.AB > 50
  )
  SELECT p.playerid, p.namefirst, p.namelast, s.yearid, s.slg
  FROM people AS p
  JOIN SLG AS s ON s.playerid = p.playerid
  ORDER BY s.slg DESC, s.yearid ASC, p.playerid ASC
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  WITH SLG AS (
    SELECT CAST(SUM(H + H2B + 2 * H3B + 3 * HR) AS FLOAT) / NULLIF(SUM(AB), 0) AS lslg, playerid, yearid
    FROM batting
    GROUP BY playerid
    HAVING SUM(AB) > 50
  )
  SELECT p.playerid, p.namefirst, p.namelast, s.lslg
  FROM people AS p
  JOIN SLG AS s ON s.playerid = p.playerid
  ORDER BY s.lslg DESC, p.playerid ASC
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
 WITH SLG AS (
    SELECT CAST(SUM(H + H2B + 2 * H3B + 3 * HR) AS FLOAT) / NULLIF(SUM(AB), 0) AS lslg, playerid, yearid
    FROM batting
    GROUP BY playerid
    HAVING SUM(AB) > 50
  ),
  MaysSLG AS (
    SELECT lslg
    FROM SLG
    WHERE playerid = 'mayswi01'
  )
  SELECT p.namefirst, p.namelast, s.lslg
  FROM people AS p
  JOIN SLG AS s ON s.playerid = p.playerid
  JOIN MaysSLG AS m
  WHERE s.lslg > m.lslg
  ORDER BY s.lslg DESC, p.playerid ASC
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT s.yearid, MIN(s.salary), MAX(s.salary), AVG(s.salary)
  FROM Salaries AS s
  GROUP BY s.yearid
  ORDER BY s.yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count) 
AS
  WITH BinParams AS (
    SELECT 
      (MAX(salary) - MIN(salary)) / 10.0 AS bin_size, 
      MIN(salary) AS min_salary,
      MAX(salary) AS max_salary
    FROM salaries
    WHERE yearid = 2016
  ),
  SalaryBins AS (
    SELECT
      CAST(((s.salary - bp.min_salary - 0.01) / bp.bin_size) AS INTEGER) AS binid,
      s.salary
    FROM salaries s, BinParams bp
    WHERE s.yearid = 2016
  ),
  BinRanges AS (
    SELECT
      binid,
      bp.min_salary + (binid * bp.bin_size) AS low,
      bp.min_salary + ((binid + 1) * bp.bin_size) AS high
    FROM BinParams bp, (SELECT DISTINCT binid FROM SalaryBins) sb
  )
  SELECT 
    br.binid, 
    br.low, 
    br.high, 
    COUNT(sb.salary) AS count
  FROM 
    BinRanges br
  JOIN 
    SalaryBins sb ON sb.binid = br.binid
  GROUP BY 
    br.binid, br.low, br.high
  ORDER BY 
    br.binid
;


-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  WITH PREDATA AS (
     SELECT s.yearid, 
      MIN(s.salary) AS pmin,
      MAX(s.salary) AS pmax,
      AVG(s.salary) AS pavg
  FROM Salaries AS s 
  GROUP BY s.yearid
  ORDER BY s.yearid ASC
  )

  SELECT s.yearid + 1, 
    pmin - MIN(s.salary),
    pmax - MAX(s.salary),
    pavg - AVG(s.salary)
  FROM PREDATA AS p
  JOIN Salaries AS s ON s.yearid = p.yearid - 1
  GROUP BY s.yearid
  ORDER BY s.yearid ASC
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  WITH Salary_max AS (
    SELECT yearid, MAX(salary) AS max_salary
    FROM Salaries
    WHERE yearid IN (2000, 2001)
    GROUP BY yearid
  )

  SELECT s.playerid, p.namefirst, p.namelast, salary, s.yearid
  FROM Salaries AS s 
  JOIN people AS p ON p.playerid = s.playerid
  JOIN Salary_max AS m ON m.yearid = s.yearid AND s.salary = m.max_salary
  ORDER BY s.yearid
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT 
    a.teamid AS team,
    MAX(s.salary) - MIN(s.salary) AS diffAvg
  FROM allstarfull AS a
  JOIN Salaries AS s ON s.playerid = a.playerid AND s.yearid = A.yearid
  WHERE S.yearid = 2016
  GROUP BY a.teamid 
;

