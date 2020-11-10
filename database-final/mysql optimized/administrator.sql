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

-- 添加医生的某个科室分配
DROP PROCEDURE IF EXISTS add_dept_assign;
DELIMITER ||
CREATE PROCEDURE add_dept_assign(IN new_doctor_id INT,IN new_dept_name VARCHAR(13))
BEGIN
    INSERT INTO dept_assign VALUES(new_doctor_id,new_dept_name);
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE add_dept_assign TO administrator;


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
GRANT EXECUTE ON FUNCTION modify_doctor_schedule_maxnumber TO patient;


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
GRANT EXECUTE ON FUNCTION `add_doc_schedule` TO patient;


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
GRANT EXECUTE ON PROCEDURE set_doc_schedule_isopen TO patient;


-- ----------------------------
-- 创建新的 appointment_cold_table
-- ----------------------------
DROP PROCEDURE IF EXISTS create_appointment_cold_table;
DELIMITER ||
CREATE PROCEDURE create_appointment_cold_table(idx INT)
BEGIN
    # 创建分表
    SET @script = CONCAT('drop table if exists appointment_cold_', idx, ';');
    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET @script = '';

    SET @script = CONCAT('create table appointment_cold_', idx);
    SET @script = CONCAT(@script,
        ' (
            appointment_id       int not null,
            doctor_schedule_id   int not null,
            person_id            varchar(13) not null,
            precedence           int not null,
            state                int not null,
            primary key (appointment_id)
        ) engine = MyISAM;'
    );
    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET @script = '';

    # 重建总表
    ## 删除总表
    SET @script = CONCAT(@script, 'drop table if exists appointment_cold;');
    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET @script = '';

    ## union 关键词
    SET @_union = 'union = (';
    SET @_i = 1;
    WHILE @_i < idx DO
        SET @_union = CONCAT(@_union, 'appointment_cold_', @_i, ',');
        SET @_i = @_i + 1;
    END WHILE;
    SET @_union = CONCAT(@_union, 'appointment_cold_', idx, ')');


    ## 创建总表
    SET @script = CONCAT(@script,
        'create table appointment_cold (
            appointment_id       int not null,
            doctor_schedule_id   int not null,
            person_id            varchar(13) not null,
            precedence           int not null,
            state                int not null,
            primary key (appointment_id)
        ) engine = MRG_MyISAM,'
    );
    SET @script = CONCAT(@script, @_union, ';');

    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE create_appointment_cold_table TO administrator;

-- ---------------------------------------------------
-- appointment_hot_table 转换为 appointment_cold_table
-- ---------------------------------------------------
DROP PROCEDURE IF EXISTS dump_to_appointment_cold;
DELIMITER ||
CREATE PROCEDURE dump_to_appointment_cold()
BEGIN
    # cold table数量，最大cold table当前数据量，hot table当前数据量，每个cold table默认数据量(1W)
    DECLARE cold_tables_num INT;
    DECLARE max_cold_table_size INT;
    DECLARE hot_table_size INT;
    DECLARE cold_max_size INT DEFAULT 1000;

    # cold table数量
    SELECT COUNT(TABLE_NAME) INTO cold_tables_num
    FROM information_schema.TABLES
    WHERE TABLE_NAME LIKE 'appointment_cold_%';

    # 最大cold table当前数据量
    SET @max_cold_table_name = CONCAT('appointment_cold_', cold_tables_num);
    SET @_script = CONCAT('SELECT COUNT(*) INTO @_ret FROM ', @max_cold_table_name, ';');
    PREPARE _sql FROM @_script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET max_cold_table_size = @_ret;

    # 今天过期的预约临时表
    DROP TABLE IF EXISTS appointment_today;
    CREATE TEMPORARY TABLE appointment_today (
        appointment_id       int not null,
        doctor_schedule_id   int not null,
        person_id            varchar(13) not null,
        precedence           int not null,
        state                int not null,
        primary key (appointment_id)
    ) ENGINE = Heap;

    SET @today = CURDATE();

    # 缓存今日及以前（如果有漏的）预约
    INSERT INTO appointment_today (
        SELECT appointment_id, appointment.doctor_schedule_id, appointment.person_id, precedence, state
        FROM (appointment INNER JOIN doctor_schedule_cold ON appointment.doctor_schedule_id = doctor_schedule_cold.doctor_schedule_id)
                 NATURAL JOIN dept_schedule_cold
        WHERE date_t <= @today
    );

    # 从 hot table 中删除
    DELETE FROM appointment
    WHERE appointment_id IN (
        SELECT appointment_id
        FROM appointment_today
    );

    # 临时表当前数据量
    SELECT COUNT(*) INTO hot_table_size
    FROM appointment_today;

    WHILE hot_table_size + max_cold_table_size >= cold_max_size DO
        # 转移量
        SET @dump_size = cold_max_size - max_cold_table_size;

        # 插入cold table
        SET @_script = CONCAT('INSERT INTO ', @max_cold_table_name, ' (SELECT * FROM appointment_today LIMIT ', @dump_size, ');');
        PREPARE _sql FROM @_script;
        EXECUTE _sql;
        DEALLOCATE PREPARE _sql;

        # 从hot table中删除
        SET @_script = CONCAT('DELETE FROM appointment_today WHERE TRUE LIMIT ', @dump_size, ';');
        PREPARE _sql FROM @_script;
        EXECUTE _sql;
        DEALLOCATE PREPARE _sql;

        # 创建新cold table
        CALL create_appointment_cold_table(cold_tables_num + 1);

        # 更新数据
        SET max_cold_table_size = 0;
        SET hot_table_size = hot_table_size - @dump_size;
        SET cold_tables_num = cold_tables_num + 1;
        SET @max_cold_table_name = CONCAT('appointment_cold_', cold_tables_num);

    END WHILE;

    DROP TABLE appointment_today;

END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE dump_to_appointment_cold TO administrator;

-- ----------------------------------
-- 创建新的 doctor_schedule_cold_table
-- ----------------------------------
DROP PROCEDURE IF EXISTS create_doctor_schedule_cold_table;
DELIMITER ||
CREATE PROCEDURE create_doctor_schedule_cold_table(idx INT)
BEGIN
    # 创建分表
    SET @script = CONCAT('drop table if exists doctor_schedule_cold_', idx, ';');
    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET @script = '';

    SET @script = CONCAT('create table doctor_schedule_cold_', idx);
    SET @script = CONCAT(@script,
        ' (
                doctor_schedule_id   int not null,
                dept_schedule_id     int,
                building             varchar(5),
                room_id              varchar(5),
                person_id            varchar(13),
                max_appointment      int not null,
                is_open              bool not null,
                primary key (doctor_schedule_id)
        ) engine = MyISAM;'
    );
    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET @script = '';

    # 重建总表
    ## 删除总表
    SET @script = CONCAT(@script, 'drop table if exists doctor_schedule_cold;');
    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET @script = '';

    ## union 关键词
    SET @_union = 'union = (';
    SET @_i = 1;
    WHILE @_i < idx DO
        SET @_union = CONCAT(@_union, 'doctor_schedule_cold_', @_i, ',');
        SET @_i = @_i + 1;
    END WHILE;
    SET @_union = CONCAT(@_union, 'doctor_schedule_cold_', idx, ')');


    ## 创建总表
    SET @script = CONCAT(@script,
        'create table doctor_schedule_cold
        (
            doctor_schedule_id   int not null,
            dept_schedule_id     int,
            building             varchar(5),
            room_id              varchar(5),
            person_id            varchar(13),
            max_appointment      int not null,
            is_open              bool not null,
            primary key (doctor_schedule_id)
        ) engine = MRG_MyISAM,'
    );
    SET @script = CONCAT(@script, @_union, ';');

    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE create_doctor_schedule_cold_table TO administrator;

-- -----------------------------------------------------------
-- doctor_schedule_hot_table 转换为 doctor_schedule_cold_table
-- -----------------------------------------------------------
DROP PROCEDURE IF EXISTS dump_to_doctor_schedule_cold;
DELIMITER ||
CREATE PROCEDURE dump_to_doctor_schedule_cold()
BEGIN
    # cold table数量，最大cold table当前数据量，hot table当前数据量，每个cold table默认数据量(1W)
    DECLARE cold_tables_num INT;
    DECLARE max_cold_table_size INT;
    DECLARE hot_table_size INT;
    DECLARE cold_max_size INT DEFAULT 1000;

    # cold table数量
    SELECT COUNT(TABLE_NAME) INTO cold_tables_num
    FROM information_schema.TABLES
    WHERE TABLE_NAME LIKE 'doctor_schedule_cold_%';

    # 最大cold table当前数据量
    SET @max_cold_table_name = CONCAT('doctor_schedule_cold_', cold_tables_num);
    SET @_script = CONCAT('SELECT COUNT(*) INTO @_ret FROM ', @max_cold_table_name, ';');
    PREPARE _sql FROM @_script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET max_cold_table_size = @_ret;


    # hot table当前数据量
    SELECT COUNT(*) INTO hot_table_size
    FROM doctor_schedule;

    WHILE hot_table_size + max_cold_table_size >= cold_max_size DO
        # 转移量
        SET @dump_size = cold_max_size - max_cold_table_size;

        # 插入cold table
        SET @_script = CONCAT('INSERT INTO ', @max_cold_table_name, ' (SELECT * FROM doctor_schedule LIMIT ', @dump_size, ');');
        PREPARE _sql FROM @_script;
        EXECUTE _sql;
        DEALLOCATE PREPARE _sql;

        # 从hot table中删除
        SET @_script = CONCAT('DELETE FROM doctor_schedule WHERE TRUE LIMIT ', @dump_size, ';');
        PREPARE _sql FROM @_script;
        EXECUTE _sql;
        DEALLOCATE PREPARE _sql;

        # 创建新cold table
        CALL create_doctor_schedule_cold_table(cold_tables_num + 1);

        # 更新数据
        SET max_cold_table_size = 0;
        SET hot_table_size = hot_table_size - @dump_size;
        SET cold_tables_num = cold_tables_num + 1;
        SET @max_cold_table_name = CONCAT('doctor_schedule_cold_', cold_tables_num);

    END WHILE;

END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE dump_to_doctor_schedule_cold TO administrator;


-- ----------------------------------
-- 创建新的 dept_schedule_cold_table
-- ----------------------------------
DROP PROCEDURE IF EXISTS create_dept_schedule_cold_table;
DELIMITER ||
CREATE PROCEDURE create_dept_schedule_cold_table(idx INT)
BEGIN
    # 创建分表
    SET @script = CONCAT('drop table if exists dept_schedule_cold_', idx, ';');
    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET @script = '';

    SET @script = CONCAT('create table dept_schedule_cold_', idx);
    SET @script = CONCAT(@script,
        ' (
                dept_schedule_id     int not null,
                time_slot_id         varchar(13),
                dept_name            varchar(20),
                date_t               date,
                primary key (dept_schedule_id)
          ) engine = MyISAM;'
    );
    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET @script = '';

    # 重建总表
    ## 删除总表
    SET @script = CONCAT(@script, 'drop table if exists dept_schedule_cold;');
    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET @script = '';

    ## union 关键词
    SET @_union = 'union = (';
    SET @_i = 1;
    WHILE @_i < idx DO
        SET @_union = CONCAT(@_union, 'dept_schedule_cold_', @_i, ',');
        SET @_i = @_i + 1;
    END WHILE;
    SET @_union = CONCAT(@_union, 'dept_schedule_cold_', idx, ')');


    ## 创建总表
    SET @script = CONCAT(@script,
        'create table dept_schedule_cold
        (
            dept_schedule_id     int not null,
            time_slot_id         varchar(13),
            dept_name            varchar(20),
            date_t               date,
            primary key (dept_schedule_id)
        ) engine = MRG_MyISAM,'
    );
    SET @script = CONCAT(@script, @_union, ';');

    PREPARE _sql FROM @script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE create_dept_schedule_cold_table TO administrator;

-- -----------------------------------------------------------
-- dept_schedule_hot_table 转换为 dept_schedule_cold_table
-- -----------------------------------------------------------
DROP PROCEDURE IF EXISTS dump_to_dept_schedule_cold;
DELIMITER ||
CREATE PROCEDURE dump_to_dept_schedule_cold()
BEGIN
    # cold table数量，最大cold table当前数据量，hot table当前数据量，每个cold table默认数据量(1W)
    DECLARE cold_tables_num INT;
    DECLARE max_cold_table_size INT;
    DECLARE hot_table_size INT;
    DECLARE cold_max_size INT DEFAULT 1000;

    # cold table数量
    SELECT COUNT(TABLE_NAME) INTO cold_tables_num
    FROM information_schema.TABLES
    WHERE TABLE_NAME LIKE 'dept_schedule_cold_%';

    # 最大cold table当前数据量
    SET @max_cold_table_name = CONCAT('dept_schedule_cold_', cold_tables_num);
    SET @_script = CONCAT('SELECT COUNT(*) INTO @_ret FROM ', @max_cold_table_name, ';');
    PREPARE _sql FROM @_script;
    EXECUTE _sql;
    DEALLOCATE PREPARE _sql;
    SET max_cold_table_size = @_ret;

    # hot table当前数据量
    SELECT COUNT(*) INTO hot_table_size
    FROM dept_schedule;

    WHILE hot_table_size + max_cold_table_size >= cold_max_size DO
        # 转移量
        SET @dump_size = cold_max_size - max_cold_table_size;

        # 插入cold table
        SET @_script = CONCAT('INSERT INTO ', @max_cold_table_name, ' (SELECT * FROM dept_schedule LIMIT ', @dump_size, ');');
        PREPARE _sql FROM @_script;
        EXECUTE _sql;
        DEALLOCATE PREPARE _sql;

        # 从hot table中删除
        SET @_script = CONCAT('DELETE FROM dept_schedule WHERE TRUE LIMIT ', @dump_size, ';');
        PREPARE _sql FROM @_script;
        EXECUTE _sql;
        DEALLOCATE PREPARE _sql;

        # 创建新cold table
        CALL create_dept_schedule_cold_table(cold_tables_num + 1);

        # 更新数据
        SET max_cold_table_size = 0;
        SET hot_table_size = hot_table_size - @dump_size;
        SET cold_tables_num = cold_tables_num + 1;
        SET @max_cold_table_name = CONCAT('dept_schedule_cold_', cold_tables_num);

    END WHILE;

END ||
DELIMITER ;
GRANT EXECUTE ON PROCEDURE dump_to_dept_schedule_cold TO administrator;
