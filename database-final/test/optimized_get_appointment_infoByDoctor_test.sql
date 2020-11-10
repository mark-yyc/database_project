CREATE VIEW doc_query AS
SELECT *
		FROM (doctor_schedule NATURAL JOIN dept_schedule) NATURAL JOIN time_slot;

call get_appointment_infoByDoctor("2020-06-10","09:00:00","10:00:00","980");

EXPLAIN
	SELECT doctor_schedule_id
	FROM (doctor_schedule NATURAL JOIN dept_schedule) NATURAL JOIN time_slot
	WHERE date_t="2020-06-08" AND start_time="08:00:00" AND end_time = "09:00:00" AND person_id = "391";
-- 	
EXPLAIN 
	SELECT *
	FROM (appointment NATURAL JOIN patient)
	WHERE doctor_schedule_id = 13508 AND state = 1;
