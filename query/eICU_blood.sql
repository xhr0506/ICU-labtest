select
i.patientunitstayid
,i.intakeoutputoffset
,i.cellpath
,i.celllabel
,i.cellvaluenumeric
,p.unitdischargeoffset
from intakeoutput i
left join patient p
on i.patientunitstayid=p.patientunitstayid
where (
position('rbc' in lower(i.celllabel)) >0
or position('red blood cell' in lower(i.celllabel)) >0
)
and i.intakeoutputoffset >0 and i.intakeoutputoffset <p.unitdischargeoffset
order by patientunitstayid,intakeoutputoffset






