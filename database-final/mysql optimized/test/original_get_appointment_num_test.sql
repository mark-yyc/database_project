SELECT count(*)
FROM appointment 
WHERE doctor_schedule_id=32878 AND state!=0;

EXPLAIN
SELECT count(*)
FROM appointment 
WHERE doctor_schedule_id=17746 AND state!=0;