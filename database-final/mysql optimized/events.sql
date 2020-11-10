
DROP PROCEDURE IF EXISTS update_docotor_avg_grade;
delimiter //
CREATE PROCEDURE update_doctor_avg_grade()
BEGIN 
    UPDATE doctor
    SET avg_grade = (
        SELECT avg(grade)
        FROM (doctor_schedule_cold NATURAL JOIN appointment_cold) NATURAL JOIN clinic_entry
        WHERE person_id = doctor.person_id
    )
    WHERE TRUE;
END
//
delimiter ;


SET GLOBAL event_scheduler = 1;

CREATE EVENT event_update_doctor
ON SCHEDULE EVERY 7 DAY STARTS '2020-04-01 23:00:00'
DO CALL update_doctor_avg_grade();

CREATE EVENT event_dump_to_doctor_schedule_cold
ON SCHEDULE EVERY 1 DAY STARTS '2020-04-01 23:10:00'
DO CALL dump_to_doctor_schedule_cold();

CREATE EVENT event_dump_to_dept_schedule_cold
ON SCHEDULE EVERY 1 DAY STARTS '2020-04-01 23:20:00'
DO CALL dump_to_dept_schedule_cold();

CREATE EVENT event_dump_to_appointment_cold
ON SCHEDULE EVERY 1 DAY STARTS '2020-04-01 23:30:00'
DO CALL dump_to_appointment_cold();

