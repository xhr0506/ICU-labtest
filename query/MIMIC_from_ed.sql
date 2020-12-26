SELECT 
ad.subject_id
,ad.hadm_id
,id.icustay_id
,ad.admittime
,ad.admission_type
,ad.edregtime
,ad.edouttime
,id.intime
,case when
(id.intime-ad.edouttime) < '1 D' then 'ED'
else 'Other'
end as delta_t
FROM admissions ad
left join icustay_detail id
on ad.subject_id=id.subject_id
and ad.hadm_id=id.hadm_id
WHERE ad.admission_type = 'EMERGENCY'
and id.icustay_id is not null