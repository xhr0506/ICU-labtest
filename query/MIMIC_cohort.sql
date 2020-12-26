with adult_cohort_1 as (
        select idet.subject_id,
               idet.hadm_id,
               idet.icustay_id,
               idet.gender,
               round(case when idet.age >= 89 then 91.4 else idet.age end, 1)       as age,
               idet.ethnicity,
               round(idet.los_icu * 24, 1)                                     as icu_los_hours,
               idet.intime,
               case when p.dod between idet.intime and idet.outtime then 1 else 0 end as icu_expire_flag
        from icustay_detail idet
				left join patients p
				on idet.subject_id=p.subject_id
        where idet.age >= 18
          and idet.hospstay_seq = 1
          and idet.icustay_seq = 1
    )
	,adult_cohort_2 as
	(
	select ac1.*
	,ad.admission_type 
	from adult_cohort_1 ac1
	left join admissions ad
	on ad.subject_id = ac1.subject_id
	and ad.hadm_id=ac1.hadm_id
	)
	,adult_cohort as
	(
	select ac2.*
	,ic.first_careunit
	from adult_cohort_2 ac2
	left join icustays ic
	on  ac2.subject_id = ic.subject_id
	and ac2.hadm_id = ic.hadm_id
	and ac2.icustay_id = ic.icustay_id
	)
    -- extract demographic and min/max aggregated labtest for each patient
    select pvt.subject_id
         , pvt.hadm_id
         , pvt.icustay_id
         , gender
         , age
         , ethnicity
         , icu_los_hours
         , icu_expire_flag
				 , admission_type
				 , first_careunit as unittype
         , min(case when label = 'albumin' then valuenum end)         as albumin_min
         , max(case when label = 'albumin' then valuenum end)         as albumin_max
         , min(case when label = 'bilirubin' then valuenum end)       as bilirubin_min
         , max(case when label = 'bilirubin' then valuenum end)       as bilirubin_max
         , min(case when label = 'bicarbonate' then valuenum end)     as bicarbonate_min
         , max(case when label = 'bicarbonate' then valuenum end)     as bicarbonate_max
         , min(case when label = 'creatinine' then valuenum end)      as creatinine_min
         , max(case when label = 'creatinine' then valuenum end)      as creatinine_max
         , min(case when label = 'glucose' then valuenum end)         as glucose_min
         , max(case when label = 'glucose' then valuenum end)         as glucose_max
         , min(case when label = 'hemoglobin' then valuenum end)      as hemoglobin_min
         , max(case when label = 'hemoglobin' then valuenum end)      as hemoglobin_max
         , min(case when label = 'lactate' then valuenum end)         as lactate_min
         , max(case when label = 'lactate' then valuenum end)         as lactate_max
         , min(case when label = 'platelet' then valuenum end)        as platelet_min
         , max(case when label = 'platelet' then valuenum end)        as platelet_max
         , min(case when label = 'potassium' then valuenum end)       as potassium_min
         , max(case when label = 'potassium' then valuenum end)       as potassium_max
         , min(case when label = 'sodium' then valuenum end)          as sodium_min
         , max(case when label = 'sodium' then valuenum end)          as sodium_max
         , min(case when label = 'magnesium' then valuenum end)       as magnesium_min
         , max(case when label = 'magnesium' then valuenum end)       as magnesium_max
         , min(case when label = 'phosphate' then valuenum end)       as phosphate_min
         , max(case when label = 'phosphate' then valuenum end)       as phosphate_max
         , min(case when label = 'bun' then valuenum end)             as bun_min
         , max(case when label = 'bun' then valuenum end)             as bun_max
         , min(case when label = 'wbc' then valuenum end)             as wbc_min
         , max(case when label = 'wbc' then valuenum end)             as wbc_max
         , min(case when label = 'calcium' then valuenum end)         as calcium_min
         , max(case when label = 'calcium' then valuenum end)         as calcium_max
         , min(case when label = 'ionized_calcium' then valuenum end) as ionized_calcium_min
         , min(case when label = 'ionized_calcium' then valuenum end) as ionized_calcium_max
    from ( -- begin query that extracts the data
             select ac.subject_id
                  , ac.hadm_id
                  , ac.icustay_id
                  , ac.gender
                  , ac.age
                  , ac.ethnicity
                  , ac.icu_los_hours
                  , ac.icu_expire_flag
									, ac.admission_type
									, ac.first_careunit
                  -- here we assign labels to itemids
                  -- this also fuses together multiple itemids containing the same data
                  , case
                        when itemid = 50862 then 'albumin'
                        when itemid = 50882 then 'bicarbonate'
                        when itemid = 50885 then 'bilirubin'
                        when itemid = 50912 then 'creatinine'
                        when itemid = 50809 then 'glucose'
                        when itemid = 50931 then 'glucose'
                        when itemid = 50811 then 'hemoglobin'
                        when itemid = 51222 then 'hemoglobin'
                        when itemid = 50813 then 'lactate'
                        when itemid = 51265 then 'platelet'
                        when itemid = 50822 then 'potassium'
                        when itemid = 50971 then 'potassium'
                        when itemid = 50824 then 'sodium'
                        when itemid = 50983 then 'sodium'
                        when itemid = 50960 then 'magnesium'
                        when itemid = 50970 then 'phosphate'
                        when itemid = 51006 then 'bun'
                        when itemid = 51300 then 'wbc'
                        when itemid = 51301 then 'wbc'
                        when itemid = 50893 then 'calcium'
                        when itemid = 50808 then 'ionized_calcium'
                 end     as label
                  , -- add in some sanity checks on the values
                  -- the where clause below requires all valuenum to be > 0, so these are only upper limit checks
                 case
                     when itemid = 50862 and valuenum > 10 then null -- g/dl 'albumin'
                     when itemid = 50882 and valuenum > 10000 then null -- meq/l 'bicarbonate'
                     when itemid = 50912 and valuenum > 150 then null -- mg/dl 'creatinine'
                     when itemid = 50809 and valuenum > 10000 then null -- mg/dl 'glucose'
                     when itemid = 50931 and valuenum > 10000 then null -- mg/dl 'glucose'
                     when itemid = 50811 and valuenum > 50 then null -- g/dl 'hemoglobin'
                     when itemid = 51222 and valuenum > 50 then null -- g/dl 'hemoglobin'
                     when itemid = 50813 and valuenum > 50 then null -- mmol/l 'lactate'
                     when itemid = 51265 and valuenum > 10000 then null -- k/ul 'platelet'
                     when itemid = 50885 and valuenum > 150 then null -- mg/dL
                     when itemid = 50960 and valuenum > 60 then null -- mmol/L
                     when itemid = 50970 and valuenum > 60 then null -- mmol/L
                     when itemid = 50822 and valuenum > 30 then null -- meq/l 'potassium'
                     when itemid = 50971 and valuenum > 30 then null -- meq/l 'potassium'
                     when itemid = 50824 and valuenum > 200 then null -- meq/l == mmol/l 'sodium'
                     when itemid = 50983 and valuenum > 200 then null -- meq/l == mmol/l 'sodium'
                     when itemid = 51006 and valuenum > 300 then null -- 'bun'
                     when itemid = 51300 and valuenum > 1000 then null -- 'wbc'
                     when itemid = 51301 and valuenum > 1000 then null -- 'wbc'
                     else valuenum
                     end as valuenum

             from adult_cohort ac
                      left join labevents le
                                on le.subject_id = ac.subject_id and le.hadm_id = ac.hadm_id and
                                   le.charttime between ac.intime and ac.intime + interval '24' hour and
                                   le.itemid in (50862, 50882, 50912, 50931, 50809, 51222, 50811,
                                                 50813, 51265, 50971, 50822, 50983, 50824, 51006,
                                                 51301, 51300, 50893, 50808, 50885, 50960, 50970) and
                                   valuenum is not null and
                                   valuenum > 0
         ) pvt
    group by pvt.subject_id, pvt.hadm_id, pvt.icustay_id, gender, age, ethnicity, icu_los_hours, icu_expire_flag, admission_type, first_careunit
    order by pvt.subject_id, pvt.hadm_id, pvt.icustay_id