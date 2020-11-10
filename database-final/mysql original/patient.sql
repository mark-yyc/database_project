DROP ROLE IF EXISTS patient;
CREATE ROLE patient;
-- ----------------------------
-- FUNCTION structure for obtaining the number of the current appointments
-- ----------------------------
DROP FUNCTION IF EXISTS get_appointment_num;
DELIMITER // 
CREATE FUNCTION get_appointment_num(one_doctor_schedule_id varchar(13))
RETURNS INTEGER
BEGIN
DECLARE result INTEGER;
SELECT count(*) into result
FROM appointment 
WHERE doctor_schedule_id=one_doctor_schedule_id AND state!=0;
return result;
end
//
DELIMITER ;
GRANT EXECUTE ON PROCEDURE get_appointment_num TO patient;

-- ----------------------------
-- Procedure structure for obtaining the information of the doctor schedule
-- ----------------------------
DROP PROCEDURE IF EXISTS get_doctor_schedule;
DELIMITER //
CREATE PROCEDURE get_doctor_schedule(aDay date,beginTime time,endTime time,dept varchar(20))
BEGIN
SELECT name,building,room_id,start_time,end_time,get_appointment_num(doctor_schedule_id) as current_appointment_num,max_appointment
from (((doctor_schedule NATURAL JOIN dept_schedule) NATURAL JOIN time_slot)NATURAL JOIN person)NATURAL JOIN room
WHERE date_t=aDay AND start_time=beginTime AND end_time=endTime AND is_open=1 AND dept_name=dept;
END
// 
DELIMITER ;
GRANT EXECUTE ON PROCEDURE get_doctor_schedule TO patient;

-- ----------------------------
-- Function structure for the addition of new appointments
-- ----------------------------
DROP FUNCTION IF EXISTS add_appointment;
DELIMITER ||
CREATE FUNCTION add_appointment(one_doctor_schedule_id INT,patient_id VARCHAR(13)) returns tinyint(1)
BEGIN
        DECLARE new_precedence INT;
    DECLARE new_appt_id INT;
    DECLARE appt_cnt INT DEFAULT 0;
    DECLARE max_cnt INT;

    SELECT max_appointment INTO max_cnt
    FROM doctor_schedule
    WHERE doctor_schedule_id = one_doctor_schedule_id;

    
    SELECT MAX(precedence) INTO new_precedence
    FROM appointment
    WHERE doctor_schedule_id = one_doctor_schedule_id;

    SET new_precedence = new_precedence + 1;
   
    SELECT COUNT(*) INTO appt_cnt
    FROM appointment
    WHERE doctor_schedule_id = one_doctor_schedule_id AND state <> 0;
    
    IF appt_cnt >= max_cnt THEN 
        return false; 
    END IF;
		INSERT INTO appointment(doctor_schedule_id, person_id, precedence, state) VALUE (one_doctor_schedule_id, patient_id, new_precedence, 1);
    return true;
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE add_appointment TO patient;

-- ----------------------------
-- Procedure structure for the cancel of an appointment
-- ----------------------------
DROP PROCEDURE IF EXISTS cancel_appointment;
DELIMITER ||
CREATE PROCEDURE cancel_appointment(IN appt_id INT)
BEGIN
    UPDATE appointment SET state = 0 WHERE appointment_id = appt_id;
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE cancel_appointment TO patient;

-- ----------------------------
-- Procedure structure for the addition of clinic_entry
-- ----------------------------
DROP PROCEDURE IF EXISTS add_clinic_entry;
DELIMITER ||
CREATE PROCEDURE add_clinic_entry(appointmentId  INT, ranking DECIMAL ,com VARCHAR(1024),cos DECIMAL )
BEGIN
    INSERT INTO clinic_entry VALUES(appointmentId ,ranking ,com ,cos);
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE add_clinic_entry TO patient;

-- ----------------------------
-- Triggers structure for the update of doctor's average grade
-- ----------------------------
DROP TRIGGER IF EXISTS update_doctor_avg_grade;
delimiter //
CREATE TRIGGER update_doctor_avg_grade AFTER INSERT ON clinic_entry FOR EACH ROW 
begin 
    DECLARE new_appointment_id INT;
    DECLARE p_id varchar(13);
    DECLARE new_avg_grade DECIMAL;

    SET new_appointment_id=NEW.appointment_id;
    SELECT doctor_schedule.person_id INTO p_id
    FROM appointment JOIN doctor_schedule USING(doctor_schedule_id)
    WHERE appointment_id=new_appointment_id;

    SELECT avg(grade) into new_avg_grade
    FROM (clinic_entry NATURAL JOIN appointment) JOIN doctor_schedule USING(doctor_schedule_id)
    WHERE doctor_schedule.person_id=p_id;

    UPDATE doctor
        set avg_grade=new_avg_grade
        where person_id=p_id;
end
//
delimiter ;


