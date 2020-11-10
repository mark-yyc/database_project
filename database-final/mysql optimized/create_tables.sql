/*==============================================================*/
/* DBMS name:      MySQL 5.0                                    */
/* Created on:     2020/5/18 12:23:10                           */
/*==============================================================*/


drop table if exists administrator;
drop table if exists clinic_entry;
drop table if exists schedule_people_realtime;
drop table if exists appointment_cold_1;
drop table if exists appointment_cold;
drop table if exists appointment;
drop table if exists dept_assign;
drop table if exists doctor_schedule_cold_1;
drop table if exists doctor_schedule_cold;
drop table if exists doctor_schedule;
drop table if exists dept_schedule_cold_1;
drop table if exists dept_schedule_cold;
drop table if exists dept_schedule;
drop table if exists department;
drop table if exists doctor;
drop table if exists employee;
drop table if exists patient;
drop table if exists person;
drop table if exists room;
drop table if exists time_slot;

/*==============================================================*/
/* Table: administrator                                         */
/*==============================================================*/
create table administrator
(
   person_id            varchar(13) not null,
   primary key (person_id)
);

/*==============================================================*/
/* Table: schedule_people_realtime                              */
/*==============================================================*/
create table schedule_people_realtime
(
   doctor_schedule_id  int not null,
   people_count int not null,
   primary key (doctor_schedule_id)
) engine = Heap;

/*==============================================================*/
/* Table: appointment_cold_1                                    */
/*==============================================================*/
create table appointment_cold_1
(
   appointment_id       int not null,
   doctor_schedule_id   int not null,
   person_id            varchar(13) not null,
   precedence           int not null,
   state                int not null,
   primary key (appointment_id)
) engine = MyISAM;

/*==============================================================*/
/* Table: appointment_cold                                      */
/*==============================================================*/
create table appointment_cold
(
   appointment_id       int not null,
   doctor_schedule_id   int not null,
   person_id            varchar(13) not null,
   precedence           int not null,
   state                int not null,
   primary key (appointment_id)
) engine = MRG_MyISAM, union = (appointment_cold_1);

/*==============================================================*/
/* Table: appointment                                           */
/*==============================================================*/
create table appointment
(
   appointment_id       int not null auto_increment,
   doctor_schedule_id   int,
   person_id            varchar(13) not null,
   precedence           int not null,
   state                int not null,
   primary key (appointment_id),
   index idx_doctor_schedule_id (doctor_schedule_id)
) engine = InnoDB, auto_increment = 1;

/*==============================================================*/
/* Table: clinic_entry                                          */
/*==============================================================*/
create table clinic_entry
(
   appointment_id       int not null,
   grade                decimal not null,
   comment              varchar(1024) not null,
   cost                 decimal not null
);

/*==============================================================*/
/* Table: department                                            */
/*==============================================================*/
create table department
(
   dept_name            varchar(20) not null,
   primary key (dept_name)
);

/*==============================================================*/
/* Table: dept_assign                                           */
/*==============================================================*/
create table dept_assign
(
   person_id            varchar(13) not null,
   dept_name            varchar(20) not null,
   primary key (person_id, dept_name)
);

/*==============================================================*/
/* Table: dept_schedule_cold_1                                  */
/*==============================================================*/
create table dept_schedule_cold_1
(
   dept_schedule_id     int not null,
   time_slot_id         varchar(13),
   dept_name            varchar(20),
   date_t               date,
   primary key (dept_schedule_id)
) engine = MyISAM;

/*==============================================================*/
/* Table: dept_schedule_cold                                    */
/*==============================================================*/
create table dept_schedule_cold
(
   dept_schedule_id     int not null,
   time_slot_id         varchar(13),
   dept_name            varchar(20),
   date_t               date,
   primary key (dept_schedule_id)
) engine = MRG_MyISAM, union = (doctor_schedule_cold_1);

/*==============================================================*/
/* Table: dept_schedule                                         */
/*==============================================================*/
create table dept_schedule
(
   dept_schedule_id     int not null auto_increment,
   time_slot_id         varchar(13),
   dept_name            varchar(20),
   date_t               date not null,
   primary key (dept_schedule_id),
   unique index idx_time (dept_name,date_t,time_slot_id)
) engine = InnoDB, auto_increment = 1;

/*==============================================================*/
/* Table: doctor                                                */
/*==============================================================*/
create table doctor
(
   person_id            varchar(13) not null,
   title                varchar(10),
   avg_grade            decimal,
   primary key (person_id)
);

/*==============================================================*/
/* Table: doctor_schedule_cold_1                                */
/*==============================================================*/
create table doctor_schedule_cold_1
(
   doctor_schedule_id   int not null,
   dept_schedule_id     int,
   building             varchar(5),
   room_id              varchar(5),
   person_id            varchar(13),
   max_appointment      int not null,
   is_open              bool not null,
   primary key (doctor_schedule_id)
) engine = MyISAM;

/*==============================================================*/
/* Table: doctor_schedule_cold                                  */
/*==============================================================*/
create table doctor_schedule_cold
(
   doctor_schedule_id   int not null,
   dept_schedule_id     int,
   building             varchar(5),
   room_id              varchar(5),
   person_id            varchar(13),
   max_appointment      int not null,
   is_open              bool not null,
   primary key (doctor_schedule_id)
) engine = MRG_MyISAM, union = (doctor_schedule_cold_1);

/*==============================================================*/
/* Table: doctor_schedule                                       */
/*==============================================================*/
create table doctor_schedule
(
   doctor_schedule_id   int not null auto_increment,
   dept_schedule_id     int,
   building             varchar(5),
   room_id              varchar(5),
   person_id            varchar(13),
   max_appointment      int not null,
   is_open              bool not null,
   primary key (doctor_schedule_id),
   index idx_dept_schedule_id (dept_schedule_id)
) engine = InnoDB, auto_increment = 1;

/*==============================================================*/
/* Table: employee                                              */
/*==============================================================*/
create table employee
(
   person_id            varchar(13) not null,
   entry_time           datetime,
   salary               int,
   primary key (person_id)
);

/*==============================================================*/
/* Table: patient                                               */
/*==============================================================*/
create table patient
(
   person_id            varchar(13) not null,
   career               varchar(20),
   identity_card        varchar(18),
   medical_insurance_id varchar(16),
   allergy_drugs        varchar(1024),
   primary key (person_id)
);

/*==============================================================*/
/* Table: person                                                */
/*==============================================================*/
create table person
(
   person_id            varchar(13) not null,
   name                 varchar(20),
   age                  int,
   birth                date,
   detail_address       varchar(50),
   sex                  varchar(10),
   username             varchar(20),
   primary key (person_id)
);

/*==============================================================*/
/* Table: room                                                  */
/*==============================================================*/
create table room
(
   building             varchar(5) not null,
   room_id              varchar(5) not null,
   primary key (building, room_id)
);

/*==============================================================*/
/* Table: time_slot                                             */
/*==============================================================*/
create table time_slot
(
   time_slot_id         varchar(13) not null,
   start_time           time not null,
   end_time             time not null,
   primary key (time_slot_id)
);

alter table administrator add constraint FK_employee_and_doctor_plus_administrator2 foreign key (person_id)
      references employee (person_id) on delete restrict on update restrict;

alter table clinic_entry add constraint FK_appointment_and_clinic_entry foreign key (appointment_id)
      references appointment (appointment_id) on delete restrict on update restrict;

alter table dept_assign add constraint FK_dept_assign foreign key (person_id)
      references doctor (person_id) on delete restrict on update restrict;

alter table dept_assign add constraint FK_dept_assign2 foreign key (dept_name)
      references department (dept_name) on delete restrict on update restrict;

alter table dept_schedule add constraint FK_dept_schedule foreign key (dept_name)
      references department (dept_name) on delete restrict on update restrict;

alter table dept_schedule add constraint FK_dept_timeslot foreign key (time_slot_id)
      references time_slot (time_slot_id) on delete restrict on update restrict;

alter table doctor add constraint FK_employee_and_doctor_plus_administrator foreign key (person_id)
      references employee (person_id) on delete restrict on update restrict;

alter table doctor_schedule add constraint FK_doctor_dept_schedule foreign key (dept_schedule_id)
      references dept_schedule (dept_schedule_id) on delete restrict on update restrict;

alter table doctor_schedule add constraint FK_doctor_room foreign key (building, room_id)
      references room (building, room_id) on delete restrict on update restrict;

alter table doctor_schedule add constraint FK_doctor_and_appointment_unit foreign key (person_id)
      references doctor (person_id) on delete restrict on update restrict;

alter table employee add constraint FK_person_and_employee_plus_patient2 foreign key (person_id)
      references person (person_id) on delete restrict on update restrict;

alter table patient add constraint FK_person_and_employee_plus_patient foreign key (person_id)
      references person (person_id) on delete restrict on update restrict;