DROP ROLE IF EXISTS administrator;
CREATE ROLE administrator;

-- 修改医生接诊安排是否开放时触发，设置预约无效或正常
DROP TRIGGER IF EXISTS check_is_open;
delimiter ;;
CREATE TRIGGER check_is_open AFTER UPDATE ON doctor_schedule FOR EACH ROW begin
	-- state = 3 表示该预约无效（如对应医生接诊安排改变） state = 1 表示该预约处于正常状态，等待病人就诊
	IF new.is_open <> true 	THEN 
		update appointment
		set state = 3
		where appointment.doctor_schedule_id = new.doctor_schedule_id AND state = 1;
	END IF;
	IF new.is_open = true THEN 
	    UPDATE appointment
		SET state = 1
		WHERE appointment.doctor_schudule_id = new.doctor_schedule_id AND state = 3;
	END IF;
end
;;
delimiter ;

-- 删除医生接诊安排时触发,设置预约无效
DROP TRIGGER IF EXISTS trigger_doctor_dept;
DELIMITER ||
CREATE TRIGGER trigger_doctor_dept BEFORE DELETE 
ON doctor_schedule FOR EACH ROW 
BEGIN 
		UPDATE appointment 
		SET state=3
		WHERE appointment.doctor_schedule_id = OLD.doctor_schedule_id;
END ||
DELIMITER ;


-- 删除医生的某个科室分配,并删除对应的接诊安排
DROP PROCEDURE IF EXISTS delete_dept_assign;
DELIMITER ||
CREATE PROCEDURE delete_dept_assign(IN _person_id VARCHAR(13),IN _dept_name VARCHAR(13))
BEGIN
    SET FOREIGN_KEY_CHECKS = 0;
		DELETE FROM dept_assign WHERE person_id = _person_id AND dept_name = _dept_name;
		DELETE FROM doctor_schedule WHERE person_id = _person_id;
	  SET FOREIGN_KEY_CHECKS = 1;
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE delete_dept_assign TO administrator;

-- 删除某个科室接诊计划,并删除对应的医生接诊安排
DROP PROCEDURE IF EXISTS delete_dept_schedule;
DELIMITER ||
CREATE PROCEDURE delete_dept_schedule(IN _time_slot_id VARCHAR(20),IN _dept_name VARCHAR(30),IN _date_t date)
BEGIN
    SET FOREIGN_KEY_CHECKS = 0;
		DELETE FROM doctor_schedule WHERE dept_schedule_id = 
		   (SELECT dept_schedule_id FROM dept_schedule WHERE time_slot_id = _time_slot_id AND dept_name = _dept_name AND date_t=_date_t);
		DELETE FROM dept_schedule WHERE time_slot_id = _time_slot_id AND dept_name = _dept_name;
	  SET FOREIGN_KEY_CHECKS = 1;
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE delete_dept_schedule TO administrator;


-- 添加某个科室接诊计划
DROP PROCEDURE IF EXISTS add_dept_schedule;
DELIMITER ||
CREATE PROCEDURE add_dept_schedule(IN new_time_slot_id VARCHAR(20),IN new_dept_name VARCHAR(30),IN _date_t date)
BEGIN
    DECLARE new_id VARCHAR(13);
		 
		SELECT MAX(dept_schedule_id) INTO new_id
    FROM dept_schedule;

    SET new_id = new_id + 1;
    INSERT INTO dept_schedule VALUES(new_id,new_time_slot_id,new_dept_name,_date_t);
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE add_dept_schedule TO administrator;


-- 修改某个医生接诊安排的最大预约人数，若修改值小于当前预约人数，则不能修改
DROP FUNCTION IF EXISTS modify_doctor_schedule_maxnumber;
delimiter ;;
CREATE FUNCTION modify_doctor_schedule_maxnumber(`doc_sche_id` INT,`maxnumber` int) RETURNS tinyint(1)
BEGIN
	
	DECLARE cur_num int DEFAULT(0);
	SELECT COUNT(*) into cur_num FROM appointment WHERE doctor_schedule_id=doc_sche_id AND state=1;
	IF maxnumber < cur_max THEN
		RETURN false;
	END IF;
	UPDATE doctor_schedule SET max_appointment = maxnumber WHERE doctor_schedule_id = doc_sche_id;
	RETURN true;	

END
;;
delimiter ;
GRANT EXECUTE ON PROCEDURE modify_doctor_schedule_maxnumber TO administrator;

-- 添加医生接诊安排
DROP FUNCTION IF EXISTS `add_doc_schedule`;
delimiter ;;
CREATE FUNCTION `add_doc_schedule`(`_dept_schedule_id` INT,`building` varchar(5),`room_id` varchar(5),`_person_id` varchar(13),`max_appointment` int ,`is_open` bool)
 RETURNS tinyint(1)
BEGIN
	
	-- 需要检查该时段该医生有没有空
	DECLARE available int DEFAULT(0);
	DECLARE doctor_schedule_id INT;
	DECLARE cur_time_slot_id VARCHAR(13);
	SELECT time_slot_id INTO cur_time_slot_id
	FROM dept_schedule 
	WHERE dept_schedule_id = _dept_schedule_id;
    
	-- 找出该医生同一时间段的接诊安排，若有超过一条，说明插入失败
	SELECT COUNT(*) INTO available 
	FROM doctor_schedule  NATURAL JOIN dept_schedule 
	WHERE person_id = _person_id AND time_slot_id = cur_time_slot_id;

	IF available > 1 THEN 
		RETURN FALSE;
	END IF;

  	SELECT MAX(doctor_schedule_id)into doctor_schedule_id FROM doctor_schedule;
  	SET doctor_schedule_id = doctor_schedule_id + 1;
	INSERT INTO doctor_schedule VALUES(doctor_schedule_id,dept_schedule_id,building,room_id,person_id,max_appointment,is_open);
	RETURN true;
END
;;
delimiter ;
GRANT EXECUTE ON PROCEDURE add_doc_schedule TO administrator;

-- 设置医生某个接诊安排是否开放
DROP PROCEDURE IF EXISTS set_doc_schedule_isopen;
delimiter ||
CREATE PROCEDURE set_doc_schedule_isopen(IN cur_doctor_schedule_id INT,IN cur_state TINYINT(1))
BEGIN
	UPDATE doctor_schedule
	SET is_open = cur_state
	WHERE doctor_schedule_id = cur_doctor_schedule_id;
END ||
delimiter ;
GRANT EXECUTE ON PROCEDURE set_doc_schedule_isopen TO administrator;