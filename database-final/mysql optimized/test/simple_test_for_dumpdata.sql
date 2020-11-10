set @test_size = 20000 + 50;
set foreign_key_checks = 0;

delimiter ||
drop function if exists gen_id_str;
create function gen_id_str(idx int) returns varchar(13)
begin
    return lpad(idx, 13, 0);
end ||
delimiter ;

delimiter ||
drop procedure if exists test_prepare;
create procedure test_prepare()
begin
    set @id_ite = 1;

    replace into person(person_id) value (gen_id_str(@id_ite));
    replace into employee(person_id) value (gen_id_str(@id_ite));
    replace into doctor(person_id) value (gen_id_str(@id_ite));

    # dept_schedule_prepare
    set @tomorrow = date_add(curdate(), interval 1 day);
    set @today = curdate();
    insert into dept_schedule(date_t) value (@today);
    insert into dept_schedule(date_t) value (@tomorrow);
    set @_i = 1;
    while @_i <= @test_size - 2 do
        insert into dept_schedule value ();
        set @_i = @_i + 1;
    end while;

    # doctor_schedule_prepare
    insert into doctor_schedule(dept_schedule_id, person_id, max_appointment, is_open) value (1, gen_id_str(@id_ite), @test_size-40, 1);
    insert into doctor_schedule(dept_schedule_id, person_id, max_appointment, is_open) value (2, gen_id_str(@id_ite), @test_size-40, 1);
    set @_i = 1;
    while @_i <= @test_size - 2 do
        insert into doctor_schedule(person_id, max_appointment, is_open) value (gen_id_str(@id_ite), @test_size-40, 1);
        set @_i = @_i + 1;
    end while;



    # appointment_prepare
    set @_i = 1;
    while @_i <= @test_size do
        set @tmp = add_appointment(1, '1234567890123');
        set @_i = @_i + 1;
    end while;
    set @_i = 1;
    while @_i <= @test_size do
        set @tmp = add_appointment(2, '1234567890123');
        set @_i = @_i + 1;
    end while;
end ||
delimiter ;

call test_prepare();


call dump_to_dept_schedule_cold();
call dump_to_doctor_schedule_cold();
call dump_to_appointment_cold();

set foreign_key_checks = 1;

