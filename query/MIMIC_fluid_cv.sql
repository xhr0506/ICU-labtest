with patients_first as 
(SELECT 
subject_id
,hadm_id
,icustay_id
,intime
,intime + interval '1 D' as first_day_time
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
-- colloids itemid found in inputevents_cv
30008  -- Albumin 5%
,30009 -- Albumin 25%
,42832 -- albumin 12.5%
,40548 -- ALBUMIN
,45403 -- albumin
,44203 -- Albumin 12.5%
,30181 -- Serum Albumin 5%
,46564 -- Albumin
,43237 -- 25% Albumin
,43353 -- Albumin (human) 25%

,30012 -- Hespan
,46313 -- 6% Hespan

,30011 -- Dextran 40
,42975 -- DEXTRAN DRIP
,42944 -- dextran
,46336 -- 10% Dextran 40/D5W
,46729 -- Dextran
,40033 -- DEXTRAN
,45410 -- 10% Dextran 40
,42731 -- Dextran40 10%
) then 'colloids'
when ic.itemid in
(
-- crystalloids itemid found in inputevents_cv
30018 -- .9% Normal Saline
,30352 -- 0.9% Normal Saline
,30160 -- D5 Normal Saline
,30168 -- Normal Saline_GU
,44053 -- normal saline bolus
,43354 -- normal saline flushs
,44440 -- Normal Saline Bolus
,30190 -- NS .9%
,40850 -- ns bolus
,41490 -- NS bolus
,41371 -- ns fluid bolus
,41428 -- ns .9% bolus
,42844 -- NS fluid bolus
,42548 -- NS Bolus
,44741 -- NS FLUID BOLUS
,44633 -- ns boluses
,44983 -- Bolus NS
,45079 -- 500 cc ns bolus
,41467 -- NS IV bolus
,45480 -- 500cc ns bolus
,44491 -- .9NS bolus
,41695 -- NS fluid boluses
,41392 -- ns b
,45989 -- NS Fluid Bolus
,45137 -- NS cc/cc
,44053 -- normal saline bolus
,44894 -- N/s 500 ml bolus
,41380 -- nsbolus

,30060 -- D5NS
,30061 -- D5RL
,30013 -- D5W
,30159 -- D5 Ringers Lact.
,30160 -- D5 Normal Saline

,30021 -- Lactated Ringers
,41322 -- rl bolus
,44184 -- LR Bolus
,44521 -- LR bolus
,44110 -- RL BOLUS
,44815 -- LR BOLUS
,46781 -- lr bolus
,44367 -- LR
) then 'crystalloids'
/*when ic.itemid in
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
) then 'blood'*/
else null
end as f_type

from patients_first p
left join inputevents_cv ic
on p.subject_id=ic.subject_id
and p.hadm_id=ic.hadm_id
and p.icustay_id=ic.icustay_id
where (ic.charttime > p.intime and ic.charttime < p.first_day_time)
)
select * from p_first_fluid 
where f_type is not null

