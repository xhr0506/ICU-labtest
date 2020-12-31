with bt_treatment as
(
	select 
	distinct t.patientunitstayid
	-- ,t.treatmentoffset
	,1 as blood 
	from treatment t
	left join patient p
	on t.patientunitstayid = p.patientunitstayid
	where treatmentstring in 
		(
		'cardiovascular|shock|blood product administration|packed red blood cells',
		'hematology|red blood cell disorders|blood product administration|packed red blood cells|transfusion of > 2 units prbc%',
		'gastrointestinal|intravenous fluid administration|blood product administration|packed red blood cells|transfusion of 1-2 units prbc%',
		'gastrointestinal|intravenous fluid administration|blood product administration|packed red blood cells',
		'gastrointestinal|intravenous fluid administration|blood product administration|packed red blood cells|transfusion of > 2 units prbc%',
		'hematology|red blood cell disorders|blood product administration|packed red blood cells',
		'cardiovascular|shock|blood product administration|packed red blood cells|transfusion of > 2 units prbc%',
		'hematology|red blood cell disorders|blood product administration|packed red blood cells|transfusion of 1-2 units prbc%',
		'surgery|intravenous fluids / electrolytes|blood product administration|packed red blood cells|transfusion of > 2 units prbc%',
		'cardiovascular|intravenous fluid|blood product administration|packed red blood cells|transfusion of > 2 units prbc%',
		'burns/trauma|intravenous fluids|blood product administration|packed red blood cells',
		'cardiovascular|intravenous fluid|blood product administration|packed red blood cells',
		'surgery|intravenous fluids / electrolytes|blood product administration|packed red blood cells',
		'hematology|coagulation and platelets|blood product administration|packed red blood cells',
		'cardiovascular|intravenous fluid|blood product administration|packed red blood cells|transfusion of 1-2 units prbc%s',
		'hematology|coagulation and platelets|blood product administration|packed red blood cells|transfusion of > 2 units prbc%s',
		'surgery|intravenous fluids / electrolytes|blood product administration|packed red blood cells|transfusion of  0 negative prbc%s',
		'hematology|coagulation and platelets|blood product administration|packed red blood cells|transfusion of 1-2 units prbc%s',
		'renal|intravenous fluid|blood product administration|packed red blood cells|transfusion of > 2 units prbc%s',
		'surgery|intravenous fluids / electrolytes|blood product administration|packed red blood cells|transfusion of 1-2 units prbc%s',
		'burns/trauma|intravenous fluids|blood product administration|packed red blood cells|transfusion of > 2 units prbc%s',
		'burns/trauma|intravenous fluids|blood product administration|packed red blood cells|transfusion of 1-2 units prbc%s',
		'renal|intravenous fluid|blood product administration|packed red blood cells',
		'renal|intravenous fluid|blood product administration|packed red blood cells|transfusion of 1-2 units prbc%s',
		'cardiovascular|shock|blood product administration|packed red blood cells|transfusion of 1-2 units prbc%s',
		'hematology|red blood cell disorders|blood product administration|packed red blood cells|transfusion of  0 negative prbc%s',
		'endocrine|intravenous fluid administration|blood product administration|packed red blood cells|transfusion of 1-2 units prbc%s',
		'hematology|coagulation and platelets|blood product administration|packed red blood cells|transfusion of  0 negative prbc%s',
		'endocrine|intravenous fluid administration|blood product administration|packed red blood cells',
		'cardiovascular|intravenous fluid|blood product administration|packed red blood cells|transfusion of  0 negative prbc%s',
		'gastrointestinal|intravenous fluid administration|blood product administration|packed red blood cells|transfusion of  0 negative prbc%s'
		)
		and t.treatmentoffset between -720 and p.unitdischargeoffset
)
, bt_inout as
(
	select 
	distinct i.patientunitstayid
	,1 as blood
	from intakeoutput i
	left join patient p
	on i.patientunitstayid=p.patientunitstayid
	where
		(
		position('rbc' in lower(i.celllabel)) >0
		or position('red blood cell' in lower(i.celllabel)) >0
		)
	and i.intakeoutputoffset between -720 and p.unitdischargeoffset
)
, bt as
(
	select 
	p.patientunitstayid
	,case 
		when btt.blood = 1 then 1
		when bti.blood = 1 then 1
	else 0 end as blood
	from patient p
	left join bt_treatment btt
	on p.patientunitstayid = btt.patientunitstayid
	left join bt_inout bti
	on p.patientunitstayid = bti.patientunitstayid
)
select * from bt
where blood = 1
order by patientunitstayid







