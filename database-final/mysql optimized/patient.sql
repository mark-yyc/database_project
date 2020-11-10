DROP ROLE IF EXISTS patient;
CREATE ROLE patient;


-- ----------------------------
-- Procedure structure for obtaining the information of the appointment
-- ----------------------------
DROP PROCEDURE IF EXISTS get_doctor_schedule;
DELIMITER //
CREATE PROCEDURE get_doctor_schedule(aDay date,beginTime time,endTime time,dept varchar(20))
BEGIN

    DECLARE cur_people_count INT;
    DECLARE cur_dept_schedule_id INT;
    
	SELECT dept_schedule_id INTO cur_dept_schedule_id
	FROM (dept_schedule NATURAL JOIN time_slot)
	WHERE dept_name = dept AND date_t = aDay AND start_time = beginTime AND end_time = endTime;

    SELECT *
    FROM (doctor_schedule NATURAL JOIN room) NATURAL JOIN doctor NATURAL JOIN schedule_people_realtime
    WHERE dept_schedule_id = cur_dept_schedule_id AND is_open = 1;

END
// 
DELIMITER ;
GRANT EXECUTE ON PROCEDURE get_doctor_schedule TO patient;

-- ----------------------------
-- 添加新预约
-- ----------------------------
DROP FUNCTION IF EXISTS add_appointment;
DELIMITER ||
CREATE FUNCTION add_appointment(one_doctor_schedule_id INT, patient_id VARCHAR(13)) RETURNS TINYINT(1)
BEGIN
    DECLARE max_cnt INT;
    DECLARE cur_people INT;

    # 插入预约Hot Table
    ## 最大预约
    SELECT max_appointment INTO max_cnt
    FROM doctor_schedule_cold
    WHERE doctor_schedule_id = one_doctor_schedule_id;

    IF IFNULL(max_cnt, -1) = -1 THEN
        SELECT max_appointment INTO max_cnt
        FROM doctor_schedule
        WHERE doctor_schedule_id = one_doctor_schedule_id;
    END IF;

    ## 当前人数, 如果 schedule_people_realtime 里没有该时间段的数据，说明当前没有人预约过该时间段, 记为0
    SELECT people_count INTO cur_people
    FROM schedule_people_realtime
    WHERE doctor_schedule_id = one_doctor_schedule_id;

    SET cur_people = IFNULL(cur_people, 0);

    ## 超过最大人数，返回FALSE
    IF cur_people >= max_cnt THEN
        RETURN FALSE;
    END IF;

    ## 插入数据，自增
    INSERT INTO appointment(doctor_schedule_id, person_id, precedence, state) VALUE (one_doctor_schedule_id, patient_id, cur_people + 1, 1);

    # 改变实时人数
    REPLACE INTO schedule_people_realtime VALUE (one_doctor_schedule_id, cur_people + 1);

    RETURN TRUE;

END ||
DELIMITER ;
GRANT EXECUTE ON FUNCTION add_appointment TO patient;

-- ----------------------------
-- Procedure structure for the cancel of an appointment
-- ----------------------------
DROP PROCEDURE IF EXISTS cancel_appointment;
DELIMITER ||
CREATE PROCEDURE cancel_appointment(IN appt_id VARCHAR(13))
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
CREATE PROCEDURE add_clinic_entry(appointmentId  VARCHAR(13), ranking DECIMAL ,com VARCHAR(1024),cos DECIMAL )
BEGIN
    INSERT INTO clinic_entry VALUES(appointmentId ,ranking ,com ,cos);
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE add_clinic_entry TO patient;




