with adult_cohort as (
    select patientid,
           admissionid,
           case
               when gender = 'Man' then 'male'
               when gender = 'Vrouw' then 'female'
               else 'N/A' end                                    as gender,
           agegroup,
           lengthofstay                                          as icu_los_hour,
           case when destination = 'Overleden' then 1 else 0 end as icu_expire
    from admissions
    where admissioncount = 1
      and gender is not null
    order by patientid
)
   , labtests as (
    select admissionid,
           measuredat / 1000 / 3600 as measure_time_hour,
           itemid,
           case
               when itemid in (6801, 9937) then 'albumin'
               when itemid in (6813, 9945) then 'bilirubin'
               when itemid in (6836, 9941, 14216) then 'creatinine'
               when itemid in (6850, 9943) then 'BUN'
               when itemid in (6833, 9557, 9947) then 'glucose'
               when itemid in (6797, 9964, 10409, 14252) then 'platelet'
               when itemid in (6779, 9965) then 'WBC'
               when itemid in (6810, 9992) then 'bicarbonate'
               when itemid in (6837, 9580, 10053) then 'lactate'
               when itemid in (6840, 9555, 9924, 10284) then 'sodium'
               when itemid in (6835, 9556, 9927, 10285) then 'potassium'
               when itemid in (6828, 9935) then 'phosphate'
               when itemid in (6778, 9553, 9960, 10286, 19703) then 'hemoglobin'
               when itemid in (6839, 9952) then 'magnesium'
               when itemid in (6817, 9933) then 'calcium'
               when itemid in (6815, 8915, 9560, 9561, 10267) then 'calcium_ion'
               end                  as label,
           round(value::numeric, 1) as value
    from numericitems
    where itemid in (6801, 9937,
                     6813, 9945,
                     6836, 9941, 14216,
                     6850, 9943,
                     6833, 9557, 9947,
                     6797, 9964, 10409, 14252,
                     6779, 9965,
                     6810, 9992,
                     6837, 9580, 10053,
                     6840, 9555, 9924, 10284,
                     6835, 9556, 9927, 10285,
                     6828, 9935,
                     6778, 9553, 9960, 10286, 19703,
                     6839, 9952,
                     6817, 9933,
                     6815, 8915, 9560, 9561, 10267)
      and islabresult = B'1'
      and measuredat >= 0
      and admissionid in (select distinct admissionid from adult_cohort)
    order by admissionid, measuredat
)
   , grouped_labtest as (
    select admissionid
         , min(case when label = 'albumin' then value end)     as albumin_min
         , max(case when label = 'albumin' then value end)     as albumin_max
         , min(case when label = 'bilirubin' then value end)   as bilirubin_min
         , max(case when label = 'bilirubin' then value end)   as bilirubin_max
         , min(case when label = 'bicarbonate' then value end) as bicarbonate_min
         , max(case when label = 'bicarbonate' then value end) as bicarbonate_max
         , min(case when label = 'creatinine' then value end)  as creatinine_min
         , max(case when label = 'creatinine' then value end)  as creatinine_max
         , min(case when label = 'glucose' then value end)     as glucose_min
         , max(case when label = 'glucose' then value end)     as glucose_max
         , min(case when label = 'hemoglobin' then value end)  as hemoglobin_min
         , max(case when label = 'hemoglobin' then value end)  as hemoglobin_max
         , min(case when label = 'lactate' then value end)     as lactate_min
         , max(case when label = 'lactate' then value end)     as lactate_max
         , min(case when label = 'platelet' then value end)    as platelet_min
         , max(case when label = 'platelet' then value end)    as platelet_max
         , min(case when label = 'potassium' then value end)   as potassium_min
         , max(case when label = 'potassium' then value end)   as potassium_max
         , min(case when label = 'sodium' then value end)      as sodium_min
         , max(case when label = 'sodium' then value end)      as sodium_max
         , min(case when label = 'magnesium' then value end)   as magnesium_min
         , max(case when label = 'magnesium' then value end)   as magnesium_max
         , min(case when label = 'phosphate' then value end)   as phosphate_min
         , max(case when label = 'phosphate' then value end)   as phosphate_max
         , min(case when label = 'BUN' then value end)         as bun_min
         , max(case when label = 'BUN' then value end)         as bun_max
         , min(case when label = 'WBC' then value end)         as wbc_min
         , max(case when label = 'WBC' then value end)         as wbc_max
         , min(case when label = 'calcium' then value end)     as calcium_min
         , max(case when label = 'calcium' then value end)     as calcium_max
         , min(case when label = 'calcium_ion' then value end) as calcium_ion_min
         , min(case when label = 'calcium_ion' then value end) as calcium_ion_max
    from labtests
    where measure_time_hour <= 24
    group by admissionid
    order by admissionid
)
select patientid,
       gender,
       agegroup,
       icu_los_hour,
       icu_expire,
       gl.*
from adult_cohort ac
         left join grouped_labtest gl on ac.admissionid = gl.admissionid
order by patientid