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
,ic.charttime
,ic.itemid
,ic.amount
,ic.amountuom
,case 
when ic.itemid in
(
-- blood transfusion itemid found in inputevents_cv
30001 -- Packed RBC's
,30004 -- Washed PRBC's
,30104 -- OR Packed RBC's
,30179 -- PRBC's
,45020 -- RBC waste
,46124 -- er in prbc
,46407 -- ED PRBC
,46612 -- E.R. prbc
) then 'blood'
else null
end as f_type

from patients_first p
left join inputevents_cv ic
on p.subject_id=ic.subject_id
and p.hadm_id=ic.hadm_id
and p.icustay_id=ic.icustay_id
where (ic.charttime > p.intime and ic.charttime < p.outtime)
)
select * from p_first_fluid 
where f_type is not null

