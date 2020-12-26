WITH adult_cohort AS(
    SELECT
        uniquepid,
        patienthealthsystemstayid,
        patientunitstayid,
        CASE 
            WHEN lower(gender) like 'male%' THEN 'male'
            WHEN lower(gender) like 'female%' THEN 'female'
            ELSE NULL END AS gender,
        CASE WHEN age = '> 89' THEN '91.4' ELSE age END AS age,
        unittype,
				unitadmitsource,
				wardid,
				hospitaladmitsource,
				unitvisitnumber,
        ROUND(unitdischargeoffset / 60) AS icu_los_hours,
				ROUND((hospitaldischargeoffset-hospitaladmitoffset) / 60) AS hospital_los_hours,
        CASE
            WHEN lower(unitdischargestatus) like '%alive%' THEN 0
            WHEN lower(unitdischargestatus) like '%expired%' THEN 1
            ELSE NULL END AS icu_expire_flag,
        CASE 
            WHEN lower(hospitaldischargestatus) like '%alive%' THEN 0
            WHEN lower(hospitaldischargestatus) like '%expired%' THEN 1
            ELSE NULL END AS hospital_expire_flag
    FROM patient
    WHERE age != ''
		and unitvisitnumber = 1
)
, rrt_table as 
(
select distinct patientunitstayid,
		1 as rrt
    from treatment
    where treatmentstring in (
      'renal|dialysis|arteriovenous shunt for renal dialysis'
      ,'renal|dialysis|C A V H D'
      ,'renal|dialysis|C V V H'
      ,'renal|dialysis|C V V H D'
      ,'renal|dialysis|hemodialysis'
      ,'renal|dialysis|hemodialysis|emergent'
      ,'renal|dialysis|hemodialysis|for acute renal failure'
      ,'renal|dialysis|hemodialysis|for chronic renal failure'
      ,'renal|dialysis|SLED'
      ,'renal|dialysis|ultrafiltration (fluid removal only)'
      ,'renal|dialysis|ultrafiltration (fluid removal only)|emergent'
      ,'renal|dialysis|ultrafiltration (fluid removal only)|for acute renal failure'
      ,'renal|dialysis|ultrafiltration (fluid removal only)|for chronic renal failure'
      )
)
, cardiac_surgery_table as
(
-- select cardiac surgery patients
SELECT
	distinct t.patientunitstayid,
	1 as cardiac_surgery
FROM
	treatment t 
	LEFT JOIN patient p ON t.patientunitstayid = p.patientunitstayid 
WHERE
	t.treatmentstring IN (
	'cardiovascular|cardiac surgery|artificial heart implantation',
	'cardiovascular|cardiac surgery|CABG',
	'cardiovascular|cardiac surgery|CABG and valve',
	'cardiovascular|cardiac surgery|CABG and valve|emergent',
	'cardiovascular|cardiac surgery|CABG and valve|routine',
	'cardiovascular|cardiac surgery|CABG|emergent',
	'cardiovascular|cardiac surgery|CABG|routine',
	'cardiovascular|cardiac surgery|heart transplant',
	'cardiovascular|cardiac surgery|implantation of BIVAD',
	'cardiovascular|cardiac surgery|implantation of heart pacemaker - permanent',
	'cardiovascular|cardiac surgery|implantation of LVAD',
	'cardiovascular|cardiac surgery|implantation of RVAD',
	'cardiovascular|cardiac surgery|pericardial window',
	'cardiovascular|cardiac surgery|thrombectomy',
	'cardiovascular|cardiac surgery|valve replacement or repair',
	'cardiovascular|cardiac surgery|valve replacement or repair|emergent',
	'cardiovascular|cardiac surgery|valve replacement or repair|routine' 
	-- ,'cardiovascular|consultations|Cardiac surgery consultation'
  -- ,'transplant|consultations|Cardiac surgery consultation'
	
	) 
	AND p.unittype in ('Med-Surg ICU','CCU-CTICU' )
)
, vent_table_1 as 
(
select pv.*
,cast(round((pv.endtime - pv.starttime))   as   numeric(18,2)) as vent_duration_min
from pivoted_vent pv
left join patient p
on pv.patientunitstayid = p.patientunitstayid
where pv.starttime < p.unitdischargeoffset
and pv.endtime > 0
)
,vent_table as 
(
-- several vent treatments for one unit stay, sum the duration.
select patientunitstayid,sum(vent_duration_min) as vent_duration_min
from vent_table_1
group by patientunitstayid
)
,admission_type_table as
(
select patientunitstayid
,admitdxpath
from admissiondx
where lower(admitdxpath) like '%admission diagnosis|elective|yes%' 
)
SELECT
    ac.uniquepid,
		ac.patienthealthsystemstayid,
		ac.patientunitstayid,
    ac.gender,
    ac.age,
    ac.unittype,
		ac.wardid,
		ac.unitadmitsource,
		ac.hospitaladmitsource,
		ac.unitvisitnumber,
    ac.icu_los_hours,
		ac.hospital_los_hours,
		ac.icu_expire_flag,
    ac.hospital_expire_flag,
		case when rt.rrt = 1 then 1 else 0 end as rrt,
		case when ct.cardiac_surgery = 1 then 1 else 0 end as cardiac_surgery,
		round(vt.vent_duration_min / 60, 2) as vent_duration_hours,
		case when att.admitdxpath is not null then 'elective' else 'emergency' end as admission_type,
    lfd.BICARBONATE_min,
    lfd.CREATININE_max,
    lfd.GLUCOSE_max,
    lfd.HEMOGLOBIN_min,
    lfd.LACTATE_max,
    lfd.SODIUM_max,
    lfd.SODIUM_min
    
FROM adult_cohort ac
LEFT JOIN labsfirstday lfd
    ON ac.patientunitstayid = lfd.patientunitstayid
left join rrt_table rt
		on ac.patientunitstayid = rt.patientunitstayid
left join  cardiac_surgery_table ct
		on ac.patientunitstayid = ct.patientunitstayid
left join vent_table vt
		on ac.patientunitstayid = vt.patientunitstayid
left join admission_type_table att
    on ac.patientunitstayid = att.patientunitstayid
ORDER BY ac.uniquepid,ac.age