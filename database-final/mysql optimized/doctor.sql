DROP ROLE IF EXISTS doctor;
CREATE ROLE doctor;

-- 查询某个医生某个时间段的所有预约信息
DROP PROCEDURE IF EXISTS `get_appointment_infoByDoctor`;
delimiter ;;
CREATE PROCEDURE `get_appointment_infoByDoctor`(aDay date,beginTime time,endTime time,doctor_id VARCHAR(13))
BEGIN
	DECLARE cur_doctor_schedule_id INT;

	-- 找对应医生接诊安排
	SELECT doctor_schedule_id INTO cur_doctor_schedule_id
	FROM (doctor_schedule NATURAL JOIN dept_schedule) NATURAL JOIN time_slot
	WHERE date_t = aDay AND start_time = beginTime AND end_time = endTime AND person_id = doctor_id;

	-- 找对应预约安排
	SELECT *
	FROM (appointment NATURAL JOIN patient)
	WHERE doctor_schedule_id = cur_doctor_schedule_id AND state = 1;
END
;;
delimiter ;
GRANT EXECUTE ON PROCEDURE `get_appointment_infoByDoctor` TO doctor;


-- 设置某条预约完成
DROP PROCEDURE IF EXISTS `set_appointment_success`;
delimiter ;;
CREATE PROCEDURE `set_appointment_success`(IN `apid` INT)
BEGIN
    -- state = 2 表示该条预约 病人已成功看病
	UPDATE `appointment` SET state = 2 WHERE appointment_id = apid;
END
;;
delimiter ;
GRANT EXECUTE ON PROCEDURE `set_appointment_success` TO doctor;
