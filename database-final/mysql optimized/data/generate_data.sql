SET FOREIGN_KEY_CHECKS=0;
-- 10+1000+20000个人
DROP PROCEDURE IF EXISTS GENERATE_PERSON;
DELIMITER ||
CREATE PROCEDURE GENERATE_PERSON()
BEGIN
DECLARE x INT DEFAULT 0;
SET @sqlStr='INSERT INTO person (`person_id`,`name`,`age`,`birth`,`detail_address`,`sex`,`username`) VALUES';
WHILE x < 21010
DO
-- 字符串拼接的插入速度更快
SET @sqlStr=CONCAT(@sqlStr,'(',x,',\'person_',x,'\',',FLOOR(2+RAND ()*80),',\'',CURRENT_DATE (),'\',\'address_',x,'\',\'',IF (FLOOR(RAND()*10)< 5,'male','female'),'\',\'username_',x,'\'),');

SET x=x+1; 
END WHILE; 

SET @sqlStr=CONCAT(LEFT(@sqlStr,CHAR_LENGTH(@sqlStr)-1),';');
PREPARE stmt FROM @sqlStr;
EXECUTE stmt;
END || 
DELIMITER ;
CALL GENERATE_PERSON();

-- 10+1000个职员
DROP PROCEDURE IF EXISTS GENERATE_EMPLOYEE;
DELIMITER ||
CREATE PROCEDURE GENERATE_EMPLOYEE()
BEGIN
DECLARE x INT DEFAULT 0;
SET @sqlStr='INSERT INTO employee (`person_id`,`entry_time`,`salary`) VALUES';
WHILE x < 1010
DO

SET @sqlStr=CONCAT(@sqlStr,'(',x,',\'',CURRENT_TIMESTAMP(),'\',',FLOOR(3000+RAND ()*5000),'),');

SET x=x+1; 
END WHILE; 

SET @sqlStr=CONCAT(LEFT(@sqlStr,CHAR_LENGTH(@sqlStr)-1),';');
PREPARE stmt FROM @sqlStr;
EXECUTE stmt;
END || 
DELIMITER ;
CALL GENERATE_EMPLOYEE();

-- 10个管理员
DROP PROCEDURE IF EXISTS GENERATE_ADMINISTRATOR;
DELIMITER ||
CREATE PROCEDURE GENERATE_ADMINISTRATOR()
BEGIN
DECLARE x INT DEFAULT 0;
SET @sqlStr='INSERT INTO administrator (`person_id`) VALUES';
WHILE x < 10
DO

SET @sqlStr=CONCAT(@sqlStr,'(',x,'),');

SET x=x+1; 
END WHILE; 

SET @sqlStr=CONCAT(LEFT(@sqlStr,CHAR_LENGTH(@sqlStr)-1),';');
PREPARE stmt FROM @sqlStr;
EXECUTE stmt;
END || 
DELIMITER ;
CALL GENERATE_ADMINISTRATOR();

-- 1000个医生
DROP PROCEDURE IF EXISTS GENERATE_DOCTOR;
DELIMITER ||
CREATE PROCEDURE GENERATE_DOCTOR()
BEGIN
DECLARE x INT DEFAULT 10;
SET @sqlStr='INSERT INTO doctor (`person_id`,`title`,`avg_grade`) VALUES';
WHILE x < 1010
DO

SET @sqlStr=CONCAT(@sqlStr,'(',x,',\'',
(CASE FLOOR(RAND()*10)%4
	WHEN 0 THEN
		'director'
	WHEN 1 THEN 
		'professor'
	WHEN 2 THEN 
		'doctor'
	ELSE
		'nurse'
END)
,'\',',0,'),');

SET x=x+1; 
END WHILE; 

SET @sqlStr=CONCAT(LEFT(@sqlStr,CHAR_LENGTH(@sqlStr)-1),';');
PREPARE stmt FROM @sqlStr;
EXECUTE stmt;
END || 
DELIMITER ;
CALL GENERATE_DOCTOR();

-- 20000个病人
DROP PROCEDURE IF EXISTS GENERATE_PATIENT;
DELIMITER ||
CREATE PROCEDURE GENERATE_PATIENT()
BEGIN
DECLARE x INT DEFAULT 1010;
SET @sqlStr='INSERT INTO patient (`person_id`,`career`,`identity_card`,`medical_insurance_id`,`allergy_drugs`) VALUES';
WHILE x < 21010
DO

SET @sqlStr=CONCAT(@sqlStr,'(',x,',\'career_',x,'\',\'identity_card_',x,'\',\'i_id_',x,'\',\'allergy_drugs_',x,'\'),');

SET x=x+1; 
END WHILE; 

SET @sqlStr=CONCAT(LEFT(@sqlStr,CHAR_LENGTH(@sqlStr)-1),';');
PREPARE stmt FROM @sqlStr;
EXECUTE stmt;
END || 
DELIMITER ;
CALL GENERATE_PATIENT();

-- 添加科室
DROP PROCEDURE IF EXISTS GENERATE_DEPARTMENT;
DELIMITER ||
CREATE PROCEDURE GENERATE_DEPARTMENT()
BEGIN

INSERT INTO department(`dept_name`) VALUES('surgery'),('pediatrics'),('neurology'),('ophtalmology'),('stomatology'),('urology'),('orthopedic'),('traumatology'),('endocrinology'),('anesthesiology');

END || 
DELIMITER ;
CALL GENERATE_DEPARTMENT();

-- 添加门诊室
DROP PROCEDURE IF EXISTS GENERATE_ROOM;
DELIMITER ||
CREATE PROCEDURE GENERATE_ROOM()
BEGIN
DECLARE x INT DEFAULT 0;
DECLARE y INT DEFAULT 0;
DECLARE z INT DEFAULT 0;
WHILE x < 4
DO
SET y=0;
WHILE y < 4
DO
SET z=0;
WHILE z < 10
DO

INSERT INTO room(`building`,`room_id`) VALUES(
(CASE x
	WHEN 0 THEN 'A'
	WHEN 1 THEN 'B'
	WHEN 2 THEN 'C'
	ELSE 'D'
END
),CONCAT(y+1,'0',z)
);

SET z=z+1;
END WHILE;
SET y=y+1; 
END WHILE; 
SET x=x+1; 
END WHILE; 
END || 
DELIMITER;
CALL GENERATE_ROOM();

-- 添加时间段
DROP PROCEDURE IF EXISTS GENERATE_TIME_SLOT;
DELIMITER ||
CREATE PROCEDURE GENERATE_TIME_SLOT()
BEGIN
DECLARE x INT DEFAULT 0;
WHILE x<10 DO

INSERT INTO time_slot(`time_slot_id`,`start_time`,`end_time`)VALUES(CONCAT('slot_id_',x),CONCAT(x+8,':00'),CONCAT(x+9,':00'));

SET x=x+1;
END WHILE;
END || 
DELIMITER ;
CALL GENERATE_TIME_SLOT();

-- 添加科室分配
DROP PROCEDURE IF EXISTS GENERATE_DEPT_ASSIGN;
DELIMITER ||
CREATE PROCEDURE GENERATE_DEPT_ASSIGN()
BEGIN
DECLARE id INT DEFAULT 10;
DECLARE dept_num INT;
DECLARE x INT;
DECLARE isRepeated VARCHAR(30);
DECLARE y INT;
SET @sqlStr='INSERT INTO dept_assign(`person_id`,`dept_name`)VALUES';
WHILE id<1010 DO

SET dept_num=FLOOR(RAND()*10)%2+1; -- 每个医生1,2个科室
SET x=0;
SET y=FLOOR(RAND()*10);
WHILE x<dept_num DO 
  SET @sqlStr=CONCAT(@sqlStr,'(',id,',\'',(CASE (y+x)%10
	WHEN 0 THEN 'anesthesiology'
	WHEN 1 THEN 'endocrinology'
	WHEN 2 THEN 'neurology'
	WHEN 3 THEN 'ophtalmology'
	WHEN 4 THEN 'orthopedic'
	WHEN 5 THEN 'pediatrics'
	WHEN 6 THEN 'stomatology'
	WHEN 7 THEN 'surgery'
	WHEN 8 THEN 'traumatology'
	ELSE 'urology'
  END
  ),'\'),');

SET x=x+1;	
END WHILE;
SET id=id+1;
END WHILE;

SET @sqlStr=CONCAT(LEFT(@sqlStr,CHAR_LENGTH(@sqlStr)-1),';');
PREPARE stmt FROM @sqlStr;
EXECUTE stmt;

END || 
DELIMITER;
CALL GENERATE_DEPT_ASSIGN();

-- 添加科室接诊计划
DROP PROCEDURE IF EXISTS GENERATE_DEPT_SCHEDULE;
DELIMITER ||
CREATE PROCEDURE GENERATE_DEPT_SCHEDULE()
BEGIN
DECLARE dept INT DEFAULT 0;
DECLARE t_slot INT;
DECLARE cur_date VARCHAR(20);
DECLARE month_num INT; -- 月数
DECLARE day_num INT; -- 天数
SET @sqlStr='INSERT INTO dept_schedule (`time_slot_id`,`dept_name`,`date_t`) VALUES';
WHILE dept < 10 DO

SET t_slot=0;
WHILE t_slot<8 DO  -- 每个科室一共8个时间段
	
SET month_num=4;
WHILE month_num<8 DO-- 4,5,6,7月的接诊计划

SET day_num=1;
WHILE day_num<32 DO  -- 每一个月是周一到周五

SET cur_date='';
IF day_num<=5 OR (day_num>=8 AND day_num<=12)OR(day_num>=15 AND day_num<=19)OR(day_num>=22 AND day_num<=26)OR(day_num>=29 AND day_num<=30) THEN
SET cur_date=CONCAT('2020-0',month_num,'-',day_num);
END IF;

IF cur_date<>'' THEN
	SET @sqlStr=CONCAT(@sqlStr,'(\'slot_id_',t_slot,'\',\'',(CASE dept
	WHEN 0 THEN 'anesthesiology'
	WHEN 1 THEN 'endocrinology'
	WHEN 2 THEN 'neurology'
	WHEN 3 THEN 'ophtalmology'
	WHEN 4 THEN 'orthopedic'
	WHEN 5 THEN 'pediatrics'
	WHEN 6 THEN 'stomatology'
	WHEN 7 THEN 'surgery'
	WHEN 8 THEN 'traumatology'
	ELSE 'urology'
  END
  ),'\',\'',cur_date,'\'),');
END IF;

SET day_num=day_num+1;
END WHILE;
SET month_num=month_num+1;
END WHILE;
SET t_slot=t_slot+1;
END WHILE;
SET dept=dept+1; 
END WHILE; 
	
SET @sqlStr=CONCAT(LEFT(@sqlStr,CHAR_LENGTH(@sqlStr)-1),';');
PREPARE stmt FROM @sqlStr;
EXECUTE stmt;
END || 
DELIMITER ;
CALL GENERATE_DEPT_SCHEDULE();

-- 添加医生接诊安排
DROP PROCEDURE IF EXISTS GENERATE_DOCTOR_SCHEDULE;
DELIMITER ||
CREATE PROCEDURE GENERATE_DOCTOR_SCHEDULE()
BEGIN
DECLARE doctor_id INT DEFAULT 10;

WHILE doctor_id<1010 DO
	SET @buildingStr=(CASE FLOOR(RAND()*10)%4
	WHEN 0 THEN 'A'
	WHEN 1 THEN 'B'
	WHEN 2 THEN 'C'
	ELSE 'D'
  END
  );
	SET @roomIdStr=CONCAT(FLOOR(RAND()*10)%4+1,'0',FLOOR(RAND()*10));
	SET @maxAppointmentStr=20; -- 最大预约人数20
	SET @isOpenStr=true;

	INSERT INTO doctor_schedule (`dept_schedule_id`,`building`,`room_id`,`person_id`,`max_appointment`,`is_open`) SELECT dept_schedule_id,@buildingStr,@roomIdStr,person_id,@maxAppointmentStr,@isOpenStr FROM (((SELECT * FROM dept_assign WHERE person_id=doctor_id) AS T1 NATURAL JOIN department)NATURAL JOIN (SELECT * FROM dept_schedule WHERE time_slot_id=CONCAT('slot_id_',FLOOR(RAND()*10)))AS T2) ;
	
SET doctor_id=doctor_id+1;
END WHILE;

END || 
DELIMITER ;
CALL GENERATE_DOCTOR_SCHEDULE();

-- 添加预约和就诊记录
DROP PROCEDURE IF EXISTS GENERATE_APPOINTMENT_AND_CLINIC_ENTRY;
DELIMITER ||
CREATE PROCEDURE GENERATE_APPOINTMENT_AND_CLINIC_ENTRY()
BEGIN
DECLARE ds_id INT;
DECLARE max_ds_id INT;
DECLARE x INT;
DECLARE begin_p_id INT;
DECLARE done INT;
DECLARE ap_id INT DEFAULT 1;
DECLARE cur CURSOR FOR select doctor_schedule_id from doctor_schedule; -- 定义游标
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1; -- 声明当游标遍历完后将标志变量置成某个值
SET @sqlStr_1='INSERT INTO appointment (`appointment_id`,`doctor_schedule_id`,`person_id`,`precedence`,`state`) VALUES';
SET @sqlStr_2='INSERT INTO clinic_entry (`appointment_id`,`grade`,`comment`,`cost`) VALUES';

-- 打开游标
OPEN cur;
posloop:LOOP
IF done=1 THEN
	LEAVE posloop;
END IF;
FETCH cur INTO ds_id;

-- 循环中的添加操作
SET x=0;
SET begin_p_id=FLOOR(RAND()*20000)+1010;
WHILE x<5+FLOOR(RAND()*10) DO -- 每个接诊安排5~15个人预约,平均10个预约
SET @sqlStr_1=CONCAT(@sqlStr_1,'(',ap_id,',',ds_id,',',(begin_p_id+x-1010)%20000+1010,',',x+1,',',1,'),');
SET @sqlStr_2=CONCAT(@sqlStr_2,'(',ap_id,',',CAST(RAND() AS DECIMAL),',\'comment_',ap_id,'\',',CAST(RAND()*100+10 AS DECIMAL),'),');
SET ap_id=ap_id+1;
SET x=x+1;
END WHILE;

-- 字符串不能过长,否则会变为null
IF CHAR_LENGTH(@sqlStr_1)>300000 THEN -- 超过一定长度,就提交掉
	SET @sqlStr_1=CONCAT(LEFT(@sqlStr_1,CHAR_LENGTH(@sqlStr_1)-1),';');
	SET @sqlStr_2=CONCAT(LEFT(@sqlStr_2,CHAR_LENGTH(@sqlStr_2)-1),';');
  PREPARE stmt_1 FROM @sqlStr_1;
	PREPARE stmt_2 FROM @sqlStr_2;
  EXECUTE stmt_1;
	EXECUTE stmt_2;
  SET @sqlStr_1='INSERT INTO appointment (`appointment_id`,`doctor_schedule_id`,`person_id`,`precedence`,`state`) VALUES';
	SET @sqlStr_2='INSERT INTO clinic_entry (`appointment_id`,`grade`,`comment`,`cost`) VALUES';
END IF;


-- 关闭游标
END LOOP posloop;
CLOSE cur;

SET @sqlStr_1=CONCAT(LEFT(@sqlStr_1,CHAR_LENGTH(@sqlStr_1)-1),';');
SET @sqlStr_2=CONCAT(LEFT(@sqlStr_2,CHAR_LENGTH(@sqlStr_2)-1),';');
PREPARE stmt_1 FROM @sqlStr_1;
PREPARE stmt_2 FROM @sqlStr_2;
EXECUTE stmt_1;
EXECUTE stmt_2;
END || 
DELIMITER ;
CALL GENERATE_APPOINTMENT_AND_CLINIC_ENTRY();
SET FOREIGN_KEY_CHECKS=1;