with pat_fluid as 
(
select
patientunitstayid
,intakeoutputoffset
,cellpath
,celllabel
,cellvaluenumeric
,case 
when 
(
position('albumin' in lower(celllabel)) >0
or position('colloids' in lower(celllabel)) >0
or position('dextran' in lower(celllabel)) >0
) then 'colloids'
/*when
(
position('rbc' in lower(celllabel)) >0
or position('red blood cell' in lower(celllabel)) >0
) then 'blood'*/
when 
(

celllabel in 
(
-- LR abbreviation
'LR '
,'LR IVF'
,'D5 LR '
,'D5LR IVF'
,'LR'
,'LR bolus'
,'LR Bolus'
,'D5 LR Volume' 

-- NS abbreviation
,'NS IVF','NS '
,'NS','D5NS '
,'D5NS IVF'
,'NS 0.9% Volume'
,'NS bolus'
,'NS Bolus'
,'NS  w/20 mEq KCL 1000 ml'
,'NS  w/40 mEq KCL 1000 ml'
,'NS  w/20 mEq KCL'
,'D5 0.45 NS  w/20 mEq KCL 1000 ml'
,'0.9 NS_c'
,'D5NS  w/20 mEq KCL 1000 ml'
,'D5NS  w/20 mEq KCL' 

-- D5 abbreviation
,'D5W'
,'D5W '
,'D5W  w/150 mEq NaHCO3 1000 ml'
,'D5W  w/150 mEq NaHCO3'
,'D5W  w/ mEq NaHCO3'
,'D5W  w/100 mEq NaHCO3 1000 ml'
)

-- lactated ringers
or position('lactated ringers' in lower(celllabel)) >0

-- saline
or position('normal saline' in lower(celllabel)) >0
or position('0.9 %  sodium chloride' in lower(celllabel)) >0
or position('0.9 % sodium chloride' in lower(celllabel)) >0
or position('0.9 % nacl' in lower(celllabel)) >0

-- dextrose 5 %
or position('dextrose 5 %' in lower(celllabel)) >0

-- crystalloids
or position('crystalloids' in lower(celllabel)) >0
) then 'crystalloids'
else null
end as f_type

from intakeoutput
where (intakeoutputoffset >0 and intakeoutputoffset <1440)
)
select * from pat_fluid
where f_type is not null
-- group by f_type
order by patientunitstayid,intakeoutputoffset