-- -----------------
-- Create Table RADIUS_STATS
-- DROP TABLE radius_stats;
-- DROP SEQUENCE id_seq;
CREATE TABLE radius_stats(id number(10) NOT NULL, unprocessed_date timestamp,  unprocessed_count number(10) NOT NULL);
ALTER TABLE radius_stats ADD (CONSTRAINT id_pk PRIMARY KEY (id));
CREATE SEQUENCE id_seq START WITH 1;
--
CREATE OR REPLACE TRIGGER stat_trig 
BEFORE INSERT ON radius_stats 
FOR EACH ROW
BEGIN
  SELECT id_seq.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
-- Create AVG Table RADIUS_STATS_AVG 
CREATE TABLE radius_stats_avg AS SELECT * FROM radius_stats;
ALTER TABLE radius_stats_avg ADD (CONSTRAINT id_avg_pk PRIMARY KEY (id));
CREATE SEQUENCE id_seq_avg START WITH 1;
--
CREATE OR REPLACE TRIGGER stat_trig_avg 
BEFORE INSERT ON radius_stats_avg
FOR EACH ROW
BEGIN
  SELECT id_seq_avg.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
-- -------------
-- Create Procedure
CREATE OR REPLACE PROCEDURE NCNRADIUS.radius_stats_proc
AS
    m_time    VARCHAR (5);                                       -- model_time
    c_count   NUMBER;                                         -- current_count
    m_count   NUMBER;                                           -- model_count
BEGIN
    -- Get Current info from Radius;
    SELECT COUNT (q.id)
      INTO c_count
      FROM NCN_REQUEST_QUEUE q
     WHERE q.event_time > SYSDATE - 24 / 24 AND q.STATUS = 0;

    -- Collect 10 minutes stats
    INSERT INTO radius_stats (unprocessed_date, unprocessed_count)
         VALUES (SYSDATE, c_count);

    COMMIT;

    -- Get Averaged info from Model
    SELECT rsa.m_time, rsa.m_count
      INTO m_time, m_count
      FROM RADIUS_STATS_AVG rsa
     WHERE rsa.M_TIME = TO_CHAR (SYSDATE, 'HH24:MI');

--    IF c_count > (m_count + m_count * 0.2)
	IF ((c_count > (m_count + m_count * 0.2)) AND (c_count > 100)) -- Threshold for unprocessed_count > 100
    THEN                                             -- MORE than IN Model+20%
        UTILS.PKG_MAIL.SEND (
            mailto     => 'user1@mail.com,user2@mail.com',
            subject    => 'Alarm from NcnRadius',
            MESSAGE    => 'Unprocessed Requests more than 20% bigger than in Normal state',
            mailfrom   => 'ncnradius@azerconnect.az',
            mimetype   => 'text/html',
            priority   => 1);
--    ELSE
--        UTILS.PKG_MAIL.SEND (
--            mailto     => 'user1@mail.com,user2@mail.com',
--            subject    => 'Alarm from NcnRadius',
--            MESSAGE    => 'All OK',
--            mailfrom   => 'ncnradius@azerconnect.az',
--            mimetype   => 'text/html',
--            priority   => 1);
    END IF;

    -- Truncate Model Table RADIUS_STATS_AVG
    DELETE RADIUS_STATS_AVG;

    COMMIT;

    -- Fill Table RADIUS_STATS_AVG AS with averaged Info
    INSERT INTO RADIUS_STATS_AVG (m_time, m_count)
          SELECT TO_CHAR (r.UNPROCESSED_DATE, 'HH24:MI') AS m_time,
                 CAST (AVG (r.UNPROCESSED_COUNT) AS INT) AS m_count
            FROM radius_stats r
        GROUP BY TO_CHAR (r.UNPROCESSED_DATE, 'HH24:MI')
        ORDER BY TO_CHAR (r.UNPROCESSED_DATE, 'HH24:MI') DESC;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
        m_time := TO_CHAR (SYSDATE, 'HH24:MI');
        m_count := 0;

        -- Compare Current with Averaged Info(+20%) -> IF more send eMail

--        IF c_count > (m_count + m_count * 0.2)
		IF ((c_count > (m_count + m_count * 0.2)) AND (c_count > 100)) -- Threshold for unprocessed_count > 100 
        THEN                                         -- MORE than IN Model+20%
            UTILS.PKG_MAIL.SEND (
                mailto     => 'user1@mail.com,user2@mail.com',
                subject    => 'Alarm from NcnRadius',
                MESSAGE    => 'Unprocessed Requests more than 20% bigger than in Normal state',
                mailfrom   => 'ncnradius@azerconnect.az',
                mimetype   => 'text/html',
                priority   => 1);
--        ELSE
--            UTILS.PKG_MAIL.SEND (
--                mailto     => 'user1@mail.com,user2@mail.com',
--                subject    => 'Alarm from NcnRadius',
--                MESSAGE    => 'All OK',
--                mailfrom   => 'ncnradius@azerconnect.az',
--                mimetype   => 'text/html',
--                priority   => 1);
        END IF;

        -- Truncate Model Table RADIUS_STATS_AVG
        DELETE RADIUS_STATS_AVG;

        --COMMIT;

        -- Fill Table RADIUS_STATS_AVG AS with averaged Info
        INSERT INTO RADIUS_STATS_AVG (m_time, m_count)
              SELECT TO_CHAR (r.UNPROCESSED_DATE, 'HH24:MI') AS m_time,
                     CAST (AVG (r.UNPROCESSED_COUNT) AS INT) AS m_count
                FROM radius_stats r
            GROUP BY TO_CHAR (r.UNPROCESSED_DATE, 'HH24:MI')
            ORDER BY TO_CHAR (r.UNPROCESSED_DATE, 'HH24:MI') DESC;

        COMMIT;
END;

-- ---------------------
-- Delete Job Radius_Stats_Job
BEGIN
  dbms_scheduler.drop_job(job_name => 'Radius_Stats_Job');
END;
-- Create Job Radius_Stats_Job
BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name => 'Radius_Stats_Job',
		job_type => 'PLSQL_BLOCK',
		job_action => 'BEGIN NCNRADIUS.radius_stats_proc; END;',
		start_date => SYSTIMESTAMP,
		repeat_interval => 'FREQ=minutely;BYMINUTE=0,10,20,30,40,50;BYSECOND=0',
		end_date => NULL,
		enabled => TRUE,
		comments => 'Job exec procudure for catching unprocessed Radius requests every 10 minutes.');
END;
-- ---------------------
