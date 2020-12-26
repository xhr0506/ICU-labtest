with patients_first as 
(SELECT 
subject_id
,hadm_id
,icustay_id
,intime
,outtime
,first_icu_stay
FROM icustay_detail
where first_icu_stay = 'Y'
), p_first_fluid as
(
select p.*
,im.starttime
,im.endtime
,im.itemid
,im.amount
,im.amountuom
,im.totalamount
,case 
when im.itemid in 
(
225168 -- Packed Red Blood Cells
) then 'blood'
else null
end as f_type

from patients_first p
left join inputevents_mv im
on p.subject_id=im.subject_id
and p.hadm_id=im.hadm_id
and p.icustay_id=im.icustay_id
where (im.starttime > p.intime and im.starttime < p.outtime)
)
select * from p_first_fluid 
where f_type is not null
