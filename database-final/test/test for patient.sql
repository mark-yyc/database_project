-- ----------------------------
-- test:get_doctor_schedule("2020-04-01","08:00:00","09:00:00","surgery");
-- ----------------------------
explain
SELECT name,building,room_id,start_time,end_time,get_appointment_num(doctor_schedule_id) as current_appointment_num,max_appointment
from (((doctor_schedule NATURAL JOIN dept_schedule) NATURAL JOIN time_slot)NATURAL JOIN person)NATURAL JOIN room
WHERE date_t="2020-04-01" AND start_time="08:00:00" AND end_time="09:00:00" AND is_open=1 AND dept_name="surgery";


explain
SELECT dept_schedule_id 
	FROM (dept_schedule NATURAL JOIN time_slot)
	WHERE dept_name = "surgery" AND date_t = "2020-04-01" AND start_time = "08:00:00" AND end_time = "09:00:00";

explain    
SELECT *
    FROM (doctor_schedule NATURAL JOIN room) NATURAL JOIN doctor
    WHERE dept_schedule_id = 4929 AND is_open = 1;

mysqlslap --no-defaults --create-schema=hosipital -u root -p123456 --query= "call hosipital.get_doctor_schedule("2020-04-01","08:00:00","09:00:00","surgery");" -c 100 -i 10 -u root -p root

-- ----------------------------
-- test:update_doctor_avg_grade
-- ----------------------------

explain
    SELECT doctor_schedule.person_id 
    FROM appointment JOIN doctor_schedule USING(doctor_schedule_id)
    WHERE appointment_id=1;


explain
     SELECT avg(grade) 
   FROM (clinic_entry NATURAL JOIN appointment) JOIN doctor_schedule USING(doctor_schedule_id)
 WHERE doctor_schedule.person_id=30;

DROP PROCEDURE IF EXISTS update_doctor_grade;
delimiter //
CREATE PROCEDURE update_doctor_grade(new_appointment_id INT)
begin 
    DECLARE p_id varchar(13);
    SELECT doctor_schedule.person_id INTO p_id
    FROM appointment JOIN doctor_schedule USING(doctor_schedule_id)
    WHERE appointment_id=new_appointment_id;

    SELECT avg(grade) 
    FROM (clinic_entry NATURAL JOIN appointment) JOIN doctor_schedule USING(doctor_schedule_id)
    WHERE doctor_schedule.person_id=p_id;
end
//
delimiter ;

