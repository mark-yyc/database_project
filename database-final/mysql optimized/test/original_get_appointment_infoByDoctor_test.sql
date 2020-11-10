CREATE VIEW doc_query AS
SELECT *
		FROM (doctor_schedule NATURAL JOIN dept_schedule) NATURAL JOIN time_slot;
call  get_appointment_infoByDoctor("2020-06-01","08:00:00","09:00:00","237");

EXPLAIN 
SELECT * 
	FROM (appointment NATURAL JOIN patient)
	WHERE doctor_schedule_id IN (
		SELECT doctor_schedule_id
		FROM (doctor_schedule NATURAL JOIN dept_schedule) NATURAL JOIN time_slot
		WHERE doctor_schedule.person_id = "237" AND date_t="2020-06-01" AND start_time="08:00:00" AND end_time="09:00:00"
	) AND state = 1;