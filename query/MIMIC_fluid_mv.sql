with patients_first as 
(SELECT 
subject_id
,hadm_id
,icustay_id,intime
,intime + interval '1 D' as first_day_time
,first_icu_stay
FROM icustay_detail
where first_icu_stay = 'Y'
), p_first_fluid as
(
select p.*,im.starttime
,im.endtime
,im.itemid
,im.amount
,im.amountuom
,im.totalamount
,case 
/*when im.itemid in 
(
225168 -- Packed Red Blood Cells
) then 'blood'*/
when im.itemid in
(
-- colloids
220862	-- Albumin 25%
,220864	-- Albumin 5%
,225174	-- Hetastarch (Hespan) 6%
,225795	-- Dextran 40
) then 'colloids'
when im.itemid in
(
225158	-- NaCl 0.9%
,220949	-- Dextrose 5%
,220954 -- Saline 0,9%
,225827	-- D5LR 
,225828	-- LR
) then 'crystalloids'
else null
end as f_type

from patients_first p
left join inputevents_mv im
on p.subject_id=im.subject_id
and p.hadm_id=im.hadm_id
and p.icustay_id=im.icustay_id
where (im.starttime > p.intime and im.starttime < p.first_day_time)
)
select * from p_first_fluid 
where f_type is not null
