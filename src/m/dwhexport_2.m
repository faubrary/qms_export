	D usage Q
usage
	W "Export data for dwh from qMS",!
	W "Usage:",!
	W "Export to current device: d main^"_$ZSOURCE_"(tablename)",!
	W "For testing one row: d test^"_$ZSOURCE_"(tablename,qqc)",!
	Q
readme
	; README for config
	; references (local config for programm execution):
	; there is neccesarry entry with 2 constants: ^Q(1) and starting subnode: need to be fixed in future, but now we have what we have:
	; S cfg("$na")=$na(^Q(1))
	; S cfg("entity","pat")=174
	; other fields, which would be taken, are describing here, in config^:
	; if we dont need any entity and/or id manipulation, we could just describe fields in a simple form;
	; cfg("[f]ield",[number],"attribute")
	; cfg("f",number,"ref")="ref[erence]" (reference, which field from global should be taken)
	; cfg("f",number,"fname")="f[ield]name" (fname = fieldname, how we name it)
	; cfg("f",number,"required")="true" (By default: false. Is field required true/false (boolean). If it is required and it has no value stored in it, this row would not appear in export file.)
	; Mandatory validation is described in isValid^ (checking, if local is empty or not)
	; Also, if there is no method value, "setRef" is set up by default. Check ^setRef for further info.;
	;
	; Example of simple form, when we're getting ^Q(1,153,id,"ref"):
	; S cfg("f",number,"ref")="id"
	; S cfg("f",number,"fname")="episode_id"
	; S cfg("f",number,"required")="true"
	;
	; Complicated form is configuring more verbose with additional logic:
	; cfg("[f]ield",[number],"attribute")
	; cfg("f",number,"ref")="ref[erence]"
	; cfg("f",number,"fname")="f[ield]name"
	; cfg("f",number,"method")="method^" (which method should we use to properly form additional data. For example: docType, setLongRef, setLongRefWithCondition and others)
	; setLongRefWithCondition has it's own conditional config, see below
	; cfg("f",number,"entity")=index
	; 
	; Example of complicated form, when we're getting ^Q(1,159,id,"ref"):
	; S cfg("f",10,"ref")="pT"
	; S cfg("f",10,"fname")="phone"
	; S cfg("f",10,"method")="setLongRef"
	; S cfg("f",10,"entity")=159
	;
	; Conditional form is for method setLongRefWithCondition (and for checkAllConditions):
	; cfg("f",1,"ref")="ref[erence]"
	; cfg("f",1,"fname")="f[ield]name"
	; cfg("f",1,"method")="setLongRefWithCondition"
	; cfg("f",1,"entity")=index
	; cfg("f",1,"condition",1,"condfield")="reference_2" (here is field which value we want to check. Condition field MUST BE at the same level, as ref[erence])
	; cfg("f",1,"condition",1,"predicate")="condition=""conditional_value""" (condition and conditional_value could be expressions, see below for complex example).;
	;
	; Example of conditional form, when we're validating patient's agreement for a specific values, related to web cabinet:
	; 1. "soglNum" should be "F"
	; 2. "Xd" value should contain "d" literal
	; S cfg("f",1,"ref")="Msogl"
	; S cfg("f",1,"fname")="login"
	; S cfg("f",1,"method")="setLongRefWithCondition"
	; S cfg("f",1,"entity")=2533
	; S cfg("f",1,"condition",1,"condfield")="soglNum"
	; S cfg("f",1,"condition",1,"predicate")="@condfieldNa=""F"""
	; S cfg("f",1,"condition",2,"condfield")="Xd"
	; S cfg("f",1,"condition",2,"predicate")="$F($E(@condfieldNa,1,3),""d"")'=0"
	; 
	; There are several more options for config (like with setRef^ for now), configs are described in corresponding methods.;
	; Also, we're setting up delimiter and substrings as " ", as in M it is conventional way
	;
	;
	; README for format
	; 
	Q
mainOld(tablename)
	; Old main entrypoint, which:
	; 1. setting up config via "tablename"config function
	; 2. writing CSV Header
	; 3. does main cycle over main subnode (setting up in config too with 2 special rows: cfg("$na"),cfg("entity","pat")), and calling processRow function
	; 4. Also, optionally, could write statistics: for that, you can uncomment main+12 (W "== Statistics ==",! ZWR stat)
	N cfg,stat,entityNa,id,confNa
	S confNa=tablename_"config"
	D @(confNa_"(.cfg)")
	S entityNa=$na(@cfg("$na")@(cfg("entity","pat")))
	D writeCSVHeader(.cfg)
	S id="" F  S id=$O(@entityNa@(id)) Q:id=""  D processRowOld(.cfg,.stat,entityNa,id)
	;W "== Statistics ==",! ZWR stat
	Q
main(tablename,filialName,outBase)
	; New main entrypoint, which:
	; 1. reads tablename
	; 2. finds data in ^usrextensionbi global, and write it in certain format (.csv)
	N cfg,id,confNa
	S confNa=tablename_"config"
	D @(confNa_"(.cfg)")
	I $D(outBase)=0 S outBase=$G(cfg("$out"),$na(^usrextensionbi))
	D writeCSVHeader(.cfg)
	S id="" F  S id=$O(@outBase@(tablename,filialName,id)) Q:id=""  D processRow(.tablename,id,.cfg,.filialName)
	Q
test(tablename,currentId,inBase,outBase)
	; additional entrypoint, which is using for short (1 row) queries. It isn't test in "test test" meaning, but is test for debug purposes.;
	; mainly, it is used to check, is all values correct to compare them to GUI values.;
	; How to use:
	; 1. Find row in qW/qWD
	; 2. Write down it's qqc index
	; 3. Run test^dwhexport(tablename,qqc), qqc should correspond with subnode indexing and config logic
	; 4. Check, if all values are correct and corresponding to qW/qWD (main HIS logic)
	N cfg,stat,entityNa,id,confNa
	S confNa=tablename_"config"
	D @(confNa_"(.cfg)")
	I $D(inBase) S cfg("$na")=inBase
	I $D(outBase) S cfg("$out")=outBase
	S entityNa=$na(@cfg("$na")@(cfg("entity","pat")))
	D writeCSVHeader(.cfg)
	D processRowOld(.cfg,.stat,entityNa,currentId)
	Q
writeToOwnGlobal(tablename,filialName,inBase,outBase)
	; writing results to own global by agreements with SP.ARM.;
	; This programm should be runned at timetable, via cron or something like that. Then, main is just outputs results to device which is calling main.;
	; Own global in mbase has region with mapping usrextension global:
	; Global                             Region
	; -------------------------------------------------
	; usrextension*                      USREXTENSION
	; So, if you want to use any global with postfix to usrextension, you are free to go. There's only one restriction: when you are coding new module/subprogramm, you should check, which names are 
	; already occupied and which names are free. For ANY purposes in this module, we should use "^usrextensionbi", and none else.;
	; Structure of this global you can see at wiki.;
	N cfg,entityNa,id,confNa,customParser,stat,scope,filialId
	S confNa=tablename_"config"
	D @(confNa_"(.cfg)")
	S scope=$G(cfg("scope"),"byFilial")
	I $D(inBase) S cfg("$na")=inBase
	I $D(outBase) S cfg("$out")=outBase
	S entityNa=$na(@cfg("$na")@(cfg("entity","pat")))
	S outBase=$G(cfg("$out"),$na(^usrextensionbi))
	;
	I filialName'="" S filialId=$G(^usrextensionbi("system","config","filial_id",filialName))
	;
	I filialName'="" K @outBase@(tablename,filialName)
	E  K @outBase@(tablename)
	;
	S customParser=$G(cfg("customParser"))
	I customParser'="" D  Q
	. D @(customParser_"(.cfg,.stat,entityNa,.tablename,.filialName,.filialId,.scope)")
	S id="" F  S id=$O(@entityNa@(id)) Q:id=""  D
	. I scope="byFilial",filialId'="",$E(id,1,3)'=filialId Q
	. D writeToGlobal(.cfg,.stat,entityNa,id,.tablename,.filialName)
	Q
testupload(tablename,filialName,outBase)
	; additional entrypoint, which is using for short (500 rows) queries. It was created for ETL processing.;
	; Usage: d testupload^dwhexport_2(tablename,filialName)
	; Example: d testupload^dwhexport_2("treatservices","Hadassah")
	N cfg,id,confNa,k
	S confNa=tablename_"config"
	D @(confNa_"(.cfg)")
	I $D(outBase)=0 S outBase=$G(cfg("$out"),$na(^usrextensionbi))
	D writeCSVHeader(.cfg)
	S id=""
	F k=1:1:500 S id=$O(@outBase@(tablename,filialName,id)) Q:id=""  D processRow(.tablename,id,.cfg,.filialName)
	Q
treatscheduleconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")="1860"
	S cfg("scope")="byFilial"
	S cfg("customParser")="parseTreatSchedule"
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="treat_schedule_id"
	;
	S cfg("f",2,"ref")="datAF"
	S cfg("f",2,"fname")="treat_schedule_date"
	;
	S cfg("f",3,"ref")="Ytr"
	S cfg("f",3,"fname")="treat_schedule_slot_start_time"
	S cfg("f",3,"required")="true"
	;
	S cfg("f",4,"ref")="Ytr"
	S cfg("f",4,"fname")="treat_schedule_slot_end_time"
	S cfg("f",4,"required")="true"
	;
	S cfg("f",5,"ref")=" "
	S cfg("f",5,"fname")="treat_schedule_type"
	S cfg("f",5,"method")="null"
	;
	S cfg("f",6,"ref")=" "
	S cfg("f",6,"fname")="payment_mode_id"
	S cfg("f",6,"method")="null"
	;
	S cfg("f",7,"ref")="id"
	S cfg("f",7,"fname")="patient_id"
	S cfg("f",7,"method")="extractRef"
	S cfg("f",7,"startpos")=1
	S cfg("f",7,"endpos")=7
	;
	S cfg("f",8,"ref")="id"
	S cfg("f",8,"fname")="filial_id"
	S cfg("f",8,"method")="extractRef"
	S cfg("f",8,"startpos")=1
	S cfg("f",8,"endpos")=4
	;
	S cfg("f",9,"ref")=" "
	S cfg("f",9,"fname")="division_id"
	S cfg("f",9,"method")="null"
	;
	S cfg("f",10,"ref")=" "
	S cfg("f",10,"fname")="department_id"
	S cfg("f",10,"method")="null"
	;
	S cfg("f",11,"ref")=" "
	S cfg("f",11,"fname")="operation_room_id"
	S cfg("f",11,"method")="null"
	;
	S cfg("f",12,"ref")=" "
	S cfg("f",12,"fname")="room_id"
	S cfg("f",12,"method")="null"
	;
	S cfg("f",13,"ref")=" "
	S cfg("f",13,"fname")="workplace_id"
	S cfg("f",13,"method")="null"
	;
	S cfg("f",14,"ref")=" "
	S cfg("f",14,"fname")="doctor_id"
	;
	S cfg("f",15,"ref")=" "
	S cfg("f",15,"fname")="treat_id"
	;
	S cfg("f",16,"ref")=" "
	S cfg("f",16,"fname")="treat_schedule_status"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q
referralsconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")="244"
	S cfg("scope")="byFilial"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q
doctorsconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")="244"
	S cfg("scope")="byFilial"
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="doctor_id"
	S cfg("f",1,"method")="extractRef"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=11
	;
	S cfg("f",2,"ref")="cmnt"
	S cfg("f",2,"fname")="doctor_num"
	;
	S cfg("f",3,"ref")=" "
	S cfg("f",3,"fname")="doctor_start_date"
	S cfg("f",3,"method")="null"
	;
	S cfg("f",4,"ref")="id"
	S cfg("f",4,"fname")="filial_id"
	S cfg("f",4,"method")="extractRef"
	S cfg("f",4,"startpos")=1
	S cfg("f",4,"endpos")=3
	;
	S cfg("f",5,"ref")="id"
	S cfg("f",5,"fname")="department_id"
	S cfg("f",5,"method")="extractRef"
	S cfg("f",5,"startpos")=1
	S cfg("f",5,"endpos")=7
	;
	S cfg("f",6,"ref")="puR"
	S cfg("f",6,"fname")="doctor_speciality"
	;
	S cfg("f",7,"ref")="puR"
	S cfg("f",7,"fname")="doctor_position"
	;
	S cfg("f",8,"ref")="pAz"
	S cfg("f",8,"fname")="doctor_name"
	;
	S cfg("f",9,"ref")="pAz"
	S cfg("f",9,"fname")="doctor_full_name"
	;
	S cfg("f",10,"ref")="pAz"
	S cfg("f",10,"fname")="doctor_fte"
	S cfg("f",10,"method")="null"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q
episodecategoriesconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")="Cpvs"
	S cfg("scope")="system"
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="episode_category_id"
	S cfg("f",1,"method")="extractRef"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=2
	;
	S cfg("f",2,"ref")=" "
	S cfg("f",2,"fname")="episode_category_name"
	S cfg("f",2,"method")="directGetSelf"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q
patientsconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")=153
	S cfg("scope")="byFilial"
	;
	S cfg("f",1,"ref")="pB"
	S cfg("f",1,"fname")="patient_id"
	S cfg("f",1,"method")="extractRef"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=7
	S cfg("f",1,"required")="true"
	;
	S cfg("f",2,"ref")=" "
	S cfg("f",2,"fname")="patient_create_date"
	S cfg("f",2,"method")="null"
	;
	S cfg("f",3,"ref")="pI"
	S cfg("f",3,"fname")="patient_birth_date"
	;
	S cfg("f",4,"ref")="pBm"
	S cfg("f",4,"fname")="patient_num"
	S cfg("f",4,"method")="setLongRef"
	S cfg("f",4,"entity")=253
	;
	S cfg("f",5,"ref")="pJ"
	S cfg("f",5,"fname")="patient_gender"
	;
	S cfg("f",6,"method")="concatRefs"
	S cfg("f",6,"fname")="patient_name"
	S cfg("f",7,"ref",1)="pF" ; lastname
	S cfg("f",7,"ref",2)="pG" ; name
	S cfg("f",7,"ref",3)="pH" ; surname
	S cfg("f",6,"delim")=" "
	;
	S cfg("f",7,"method")="concatRefs"
	S cfg("f",7,"fname")="patient_full_name"
	S cfg("f",7,"ref",1)="pF" ; lastname
	S cfg("f",7,"ref",2)="pG" ; name
	S cfg("f",7,"ref",3)="pH" ; surname
	S cfg("f",7,"delim")=" "
	;
	S cfg("f",8,"ref")=" "
	S cfg("f",8,"fname")="patient_marketing_source"
	S cfg("f",8,"method")="null"
	;
	S cfg("f",9,"ref")="pnD"
	S cfg("f",9,"fname")="patient_nationality_name"
	S cfg("f",9,"method")="docType"
	;
	S cfg("f",10,"ref")="pN"
	S cfg("f",10,"fname")="patient_city"
	S cfg("f",10,"method")="setLongRef"
	S cfg("f",10,"entity")=156
	;
	S cfg("f",11,"method")="longConcatRefs"
	S cfg("f",11,"fname")="patinet_address"
	S cfg("f",11,"entity")=156
	; order: country, city, street, house, building, apartment, number
	S cfg("f",11,"ref",1)="pZ"  ; country
	S cfg("f",11,"ref",2)="pN"  ; city
	S cfg("f",11,"ref",3)="pP"  ; street
	S cfg("f",11,"ref",4)="pQ"  ; house
	S cfg("f",11,"ref",5)="pR"  ; building
	S cfg("f",11,"ref",6)="pS"  ; apartment
	S cfg("f",11,"ref",7)="pM"  ; number
	S cfg("f",11,"delim")=", "
	;
	S cfg("f",12,"ref")="pT"
	S cfg("f",12,"fname")="patient_phone"
	S cfg("f",12,"method")="setLongRef"
	S cfg("f",12,"entity")=159
	;
	S cfg("f",13,"ref")="email"
	S cfg("f",13,"fname")="patient_email"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q
invoicesconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")="238"
	S cfg("scope")="byFilial"
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="treat_schedule_id"
	S cfg("f",1,"method")="extractRef"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=8
	S cfg("f",1,"required")="true"
	;
	S cfg("f",2,"ref")="dd"
	S cfg("f",2,"fname")="invoice_date"
	;
	S cfg("f",3,"ref")=" "
	S cfg("f",3,"fname")="patient_id"
	;
	S cfg("f",4,"ref")=" "
	S cfg("f",4,"fname")="treat_id"
	;
	S cfg("f",5,"ref")=" "
	S cfg("f",5,"fname")="service_id"
	;
	S cfg("f",6,"ref")=" "
	S cfg("f",6,"fname")="payment_mode_id"
	;
	S cfg("f",7,"ref")=" "
	S cfg("f",7,"fname")="payer_id"
	;
	S cfg("f",8,"ref")=" "
	S cfg("f",8,"fname")="price_list_id"
	S cfg("f",8,"method")="null"
	;
	S cfg("f",9,"ref")=" "
	S cfg("f",9,"fname")="service_quantity"
	;
	S cfg("f",10,"ref")=" "
	S cfg("f",10,"fname")="service_base_price"
	;
	S cfg("f",11,"ref")=" "
	S cfg("f",11,"fname")="service_real_price"
	;
	S cfg("f",12,"ref")=" "
	S cfg("f",12,"fname")="discount_name"
	;
	S cfg("f",13,"ref")=" "
	S cfg("f",13,"fname")="service_total_cost"
	;
	S cfg("f",14,"ref")=" "
	S cfg("f",14,"fname")="paid_amount"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q
workscheduleconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")="244"
	S cfg("customParser")="parseRasp"
	S cfg("scope")="system" ; TODO byFilial
	;
	S cfg("f",1,"ref")=" "
	S cfg("f",1,"fname")="work_schedule_id"
	S cfg("f",1,"method")="extractRef"
	S cfg("f",1,"required")="true"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=12
	;
	S cfg("f",2,"ref")=""
	S cfg("f",2,"fname")="work_schedule_date"
	;
	S cfg("f",3,"ref")=" "
	S cfg("f",3,"fname")="work_schedule_slot_start_time"
	;
	S cfg("f",4,"ref")=" "
	S cfg("f",4,"fname")="work_schedule_slot_end_time"
	;
	S cfg("f",5,"ref")=" "
	S cfg("f",5,"fname")="work_schedule_type" ; tses
	;
	S cfg("f",6,"ref")=" "
	S cfg("f",6,"fname")="filial_id"
	S cfg("f",6,"method")="extractRef"
	S cfg("f",6,"startpos")=1
	S cfg("f",6,"endpos")=4
	;
	S cfg("f",7,"ref")=" "
	S cfg("f",7,"fname")="division_id"
	S cfg("f",7,"method")="null"
	;
	S cfg("f",8,"ref")=" "
	S cfg("f",8,"fname")="department_id"
	S cfg("f",8,"method")="null"
	;
	S cfg("f",9,"ref")=" "
	S cfg("f",9,"fname")="room_id"
	S cfg("f",9,"method")="null"
	;
	S cfg("f",10,"ref")=" "
	S cfg("f",10,"fname")="workplace_id"
	S cfg("f",10,"method")="null"
	;
	S cfg("f",11,"ref")=" "
	S cfg("f",11,"fname")="doctor_id"
	S cfg("f",11,"method")="extractRef"
	S cfg("f",11,"startpos")=1
	S cfg("f",11,"endpos")=7
	;
	S cfg("f",12,"ref")=" "
	S cfg("f",12,"fname")="work_schedule_status"
	S cfg("f",12,"method")="null"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	Q
departmentsconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("entity","pat")="153"
	S cfg("scope")="byFilial"
	S cfg("customParser")="parseDepartments"
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="department_id"
	S cfg("f",1,"method")="directId"
	;
	S cfg("f",2,"ref")="id"
	S cfg("f",2,"fname")="filial_id"
	S cfg("f",2,"method")="extractRef"
	S cfg("f",2,"startpos")=1
	S cfg("f",2,"endpos")=3
	;
	S cfg("f",3,"ref")="MpnOrgF"
	S cfg("f",3,"fname")="department_name"
	S cfg("f",3,"method")="directGet"
	S cfg("f",3,"required")="true"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q
filialsconfig(cfg)
	; N filial
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")="153"
	S cfg("scope")="system"
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="filial_id"
	S cfg("f",1,"method")="extractRef" ; extractRefwithCondition
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=3
	S cfg("f",1,"required")="true"
	;
	S cfg("f",2,"ref")="MpnOrgPl"
	S cfg("f",2,"fname")="filial_name"
	S cfg("f",2,"method")="directGet"
	S cfg("f",2,"required")="true"
	;
	S cfg("f",3,"ref")=" "
	S cfg("f",3,"fname")="filial_address"
	S cfg("f",3,"method")="null"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q
pricelistsconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")="pr0"
	S cfg("scope")="byFilial"
	;
	S cfg("f",1,"ref")="Duv"
	S cfg("f",1,"fname")="pricelist_service_id"
	S cfg("f",1,"method")="joinByIndex"
	S cfg("f",1,"indexstartpos")=1
	S cfg("f",1,"indexendpos")=7
	S cfg("f",1,"subnode")=$na(@cfg("$na")@("pr"))
	S cfg("f",1,"retrieve_field")="Duv"
	;
	S cfg("f",2,"ref")=" "
	S cfg("f",2,"fname")="pricelist_id"
	S cfg("f",2,"method")="null"
	;
	S cfg("f",3,"ref")=" "
	S cfg("f",3,"fname")="pricelist_name"
	S cfg("f",3,"method")="recursiveCall"
	S cfg("f",3,"dictionary")=$na(@cfg("$na")@(235,"оAA","Ytar"))
	S cfg("f",3,"validation_value")="Mna"
	S cfg("f",3,"validation_mode")="not_exists"
	;
	S cfg("f",4,"ref")="datpr"
	S cfg("f",4,"fname")="pricelist_startdate"
	;
	S cfg("f",5,"ref")="datpre"
	S cfg("f",5,"fname")="pricelist_enddate"
	;
	S cfg("f",6,"ref")="Mr7"
	S cfg("f",6,"fname")="price"
	S cfg("f",6,"method")="directGet"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;		
	Q
paymentmodesconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")="ww"
	S cfg("scope")="system"
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="payment_mode_id"
	S cfg("f",1,"method")="extractRef"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=8
	S cfg("f",1,"required")="true"
	;
	S cfg("f",2,"ref")="tpl"
	S cfg("f",2,"fname")="payment_mode_name"
	S cfg("f",2,"required")="true"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q	
diagnosesconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")=4
	S cfg("scope")="system"
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="diagnosis_id"
	S cfg("f",1,"method")="extractRef"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=9
	S cfg("f",1,"required")="true"
	;
	S cfg("f",2,"ref")="rub"
	S cfg("f",2,"fname")="diagnosis_mkb_code"
	;
	S cfg("f",3,"ref")="z"
	S cfg("f",3,"fname")="diagnosis_name"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q	
treatservicesconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")=1860
	S cfg("scope")="byFilial"
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="treat_id"
	S cfg("f",1,"method")="extractRef"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=23
	S cfg("f",1,"required")="true"
	;
	S cfg("f",2,"ref")="datAF"
	S cfg("f",2,"fname")="treat_date"
	S cfg("f",2,"required")="true"
	;
	S cfg("f",3,"ref")="id"
	S cfg("f",3,"fname")="patient_id"
	S cfg("f",3,"method")="extractRef"
	S cfg("f",3,"startpos")=1
	S cfg("f",3,"endpos")=7
	S cfg("f",3,"required")="true"
	;
	S cfg("f",4,"ref")="id"
	S cfg("f",4,"fname")="filial_id"
	S cfg("f",4,"method")="extractRef"
	S cfg("f",4,"startpos")=1
	S cfg("f",4,"endpos")=4
	S cfg("f",4,"required")="true"
	;
	S cfg("f",5,"ref")=" "
	S cfg("f",5,"fname")="division_id"
	S cfg("f",5,"method")="null"
	;
	S cfg("f",6,"ref")="pID"
	S cfg("f",6,"fname")="department_id"
	;
	S cfg("f",7,"ref")=" "
	S cfg("f",7,"fname")="hospital_room_id"
	S cfg("f",7,"method")="null"
	;
	S cfg("f",8,"ref")=" "
	S cfg("f",8,"fname")="hospital_bed_id"
	S cfg("f",8,"method")="null"
	;
	S cfg("f",9,"ref")=" "
	S cfg("f",9,"fname")="operation_room_id"
	S cfg("f",9,"method")="null"
	;
	S cfg("f",10,"ref")=" "
	S cfg("f",10,"fname")="room_id"
	S cfg("f",10,"method")="null"
	;
	S cfg("f",11,"ref")=" "
	S cfg("f",11,"fname")="workplace_id"
	S cfg("f",11,"method")="null"
	;
	S cfg("f",12,"ref")=" "
	S cfg("f",12,"fname")="isntrument_id"
	S cfg("f",12,"method")="null"
	;
	S cfg("f",13,"ref")="Dz"
	S cfg("f",13,"fname")="doctor_id"
	;
	S cfg("f",14,"ref")=" "
	S cfg("f",14,"fname")="diagnosis_id"
	S cfg("f",14,"method")="null"
	;
	S cfg("f",15,"ref")="Duv"
	S cfg("f",15,"fname")="service_id"
	S cfg("f",15,"method")="joinFields"
	S cfg("f",15,"subnode")=$na(@cfg("$na")@("pr"))
	S cfg("f",15,"matching_on")="Du"
	S cfg("f",15,"matching_from")="Du"
	S cfg("f",15,"retrieve_field")="Duv"
	;
	S cfg("f",16,"ref")="u"
	S cfg("f",16,"fname")="complex_service_name"
	S cfg("f",16,"method")="joinFields"
	S cfg("f",16,"subnode")=$na(@cfg("$na")@("pr"))
	S cfg("f",16,"matching_on")="Du"
	S cfg("f",16,"matching_from")="Du"
	S cfg("f",16,"retrieve_field")="u"
	S cfg("f",16,"mode")="translate"
	S cfg("f",16,"required")="true"
	;
	S cfg("f",17,"ref")=" "
	S cfg("f",17,"fname")="clinic_prim_treat"
	S cfg("f",17,"method")="null"
	;
	S cfg("f",18,"ref")=" "
	S cfg("f",18,"fname")="doctor_prim_treat"
	S cfg("f",18,"method")="null"
	;
	S cfg("f",19,"ref")="referral_id"
	S cfg("f",19,"fname")="referral_id"
	S cfg("f",19,"method")="null"
	;
	S cfg("f",20,"ref")="n1000"
	S cfg("f",20,"fname")="payment_document_id"
	S cfg("f",20,"method")="joinByIndex"
	S cfg("f",20,"mode")="translate"
	S cfg("f",20,"subnode")=$na(@cfg("$na")@(293))
	S cfg("f",20,"retrieve_field")="n1000"
	;
	S cfg("f",21,"ref")=""
	S cfg("f",21,"fname")="payment_mode_id"
	S cfg("f",21,"method")="null"
	;
	S cfg("f",22,"ref")=""
	S cfg("f",22,"fname")="payer_id"
	S cfg("f",22,"method")="null"
	;
	S cfg("f",23,"ref")=""
	S cfg("f",23,"fname")="price_list_id"
	S cfg("f",23,"method")="null"
	;
	S cfg("f",24,"ref")="Mn"
	S cfg("f",24,"fname")="service_quantity"
	S cfg("f",24,"method")="firstToken"
	;
	S cfg("f",25,"ref")=""
	S cfg("f",25,"fname")="service_base_price"
	S cfg("f",25,"method")="null"
	;
	S cfg("f",26,"ref")="Mr7o"
	S cfg("f",26,"fname")="service_real_price"
	S cfg("f",26,"method")="sumNumbers"
	;
	S cfg("f",27,"ref")=""
	S cfg("f",27,"fname")="discount_name"
	S cfg("f",27,"method")="null"
	;
	S cfg("f",28,"ref")="Mr7o"
	S cfg("f",28,"fname")="service_total_cost"
	S cfg("f",28,"method")="sumNumbers"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	Q
treatepisodesconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("$out")=$na(^usrextensionbi)
	S cfg("entity","pat")=174
	S cfg("scope")="byFilial"
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="episode_id"
	S cfg("f",1,"method")="extractRef"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=10
	S cfg("f",1,"required")="true"
	;
	S cfg("f",2,"ref")="pAX"
	S cfg("f",2,"fname")="episode_num"
	S cfg("f",2,"required")="true"
	;
	S cfg("f",3,"ref")="pAE"
	S cfg("f",3,"fname")="episode_start_date"
	S cfg("f",3,"required")="true"
	;
	S cfg("f",4,"ref")="pAG"
	S cfg("f",4,"fname")="episode_end_date"
	;
	S cfg("f",5,"ref")="pvs"
	S cfg("f",5,"fname")="treatment_mode_name"
	;
	S cfg("f",6,"ref")=" "
	S cfg("f",6,"fname")="episode_type"
	S cfg("f",6,"method")="null"
	;
	S cfg("f",7,"ref")="id"
	S cfg("f",7,"fname")="patient_id"
	S cfg("f",7,"method")="extractRef"
	S cfg("f",7,"startpos")=1
	S cfg("f",7,"endpos")=7
	S cfg("f",7,"required")="true"
	;
	S cfg("f",8,"ref")="id"
	S cfg("f",8,"fname")="filial_id"
	S cfg("f",8,"method")="extractRef"
	S cfg("f",8,"startpos")=1
	S cfg("f",8,"endpos")=4
	S cfg("f",8,"required")="true"
	;
	S cfg("f",9,"ref")=" "
	S cfg("f",9,"fname")="division_id"
	S cfg("f",9,"method")="null"
	;
	S cfg("f",10,"ref")="pID"
	S cfg("f",10,"fname")="department_id"
	;
	S cfg("f",11,"ref")=" "
	S cfg("f",11,"fname")="hospital_room_id"
	S cfg("f",11,"method")="null"
	;
	S cfg("f",12,"ref")=" "
	S cfg("f",12,"fname")="hospital_bed_id"
	S cfg("f",12,"method")="null"
	;
	S cfg("f",13,"ref")="pAz"
	S cfg("f",13,"fname")="episode_doctor_id"
	;
	S cfg("f",14,"ref")="pKDiag"
	S cfg("f",14,"fname")="episode_diagnosis_id"
	S cfg("f",14,"method")="wordWrap"
	S cfg("f",14,"words")=1
	;
	S cfg("f",15,"ref")=" "
	S cfg("f",15,"fname")="episode_result_name"
	S cfg("f",15,"method")="null"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	Q
writeCSVHeader(cfg)
	N fn,delim,r
	S delim="|"
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D
	. S $P(r,delim,fn)=cfg("f",fn,"fname")
	W r,!
	Q
recursiveCall(cfg,pat,fn,idNa)
	; In some cases, you need to recursievly invoke writeRow. For example, in same id you have several rows to write.;
	; You need to configure this behaviour via config: in most common case, you have some dictionary inside global and you want to parse it and plan rows strategy.;
	; In this dictionary there could be three modes:
	; S cfg("f",3,"validation_mode")="not_exists" (checks, if value not existing)
	; S cfg("f",3,"validation_mode")="exists" (checks, if value is existing)
	; S cfg("f",3,"validation_mode")="equals" (checks, if value is equal to some value)
	; S cfg("f",3,"validation_mode")="not_equals" (checks, if value is not equal to some value)
	; S cfg("f",3,"validation_value")="some_value" (in case of equals or not equals, you should set, which value should be checked)
	N ref,fname
	S ref=cfg("f",fn,"ref")
	S fname=cfg("f",fn,"fname")
	I $D(dictionary)=0 M dictionary=@cfg("f",fn,"dictionary")
	;	
	Q
usePreviousResult(cfg,pat,fn,idNa)
	; uses previous result (already calculated!) to retrieve additional information by another path
	; deduplicates useless calculations
	; NOTE: value MUST BE already calculated, because we're referencing pat("fname")!
	Q
directGetSelf(cfg,pat,fn,idNa)
	; Gets the value of the current node ^...,(last subscript)
	N fname
	S fname=cfg("f",fn,"fname")
	S pat(fname)=$G(@idNa)
	Q
directId(cfg,pat,fn,idNa)
	; Gets full id (last subscript) as-is
	N fname
	S fname=cfg("f",fn,"fname")
	S pat(fname)=$QS(idNa,$QL(idNa))
	Q
joinByIndex(cfg,pat,fn,idNa)
	; joins another subnode by same index in different position
	; for example: you have ^gl(ind1,ind2,ind3), ^gl(ind1,ind3,field)="refValue" (you are iterating over ind3 in main cycle)
	; So, you may want to retrieve refValue by saying: $G(^gl(ind1,ind3,field)) 
	N id,ref,fname,searchValue,pathNa,refValue,mode,startpos,endpos,indexstartpos,indexendpos
	S ref=cfg("f",fn,"ref")
	S fname=cfg("f",fn,"fname")
	S searchValue=cfg("f",fn,"retrieve_field")
	S pathNa=cfg("f",fn,"subnode")
	S mode=$G(cfg("f",fn,"mode"),"")
	S startpos=$G(cfg("f",fn,"startpos"))
	S endpos=$G(cfg("f",fn,"endpos"))
	S indexstartpos=$G(cfg("f",fn,"indexstartpos"))
	S indexendpos=$G(cfg("f",fn,"indexendpos"))
	I $D(cfg("f",fn,"indexstartpos")),$D(cfg("f",fn,"indexendpos")) D
	. S id=$E($QS(idNa,$QL(idNa)),indexstartpos,indexendpos)  
	E  S id=$QS(idNa,$QL(idNa))
	S refValue=$G(@pathNa@(id,ref),"null")
	I mode="translate",refValue'="null" S refValue=$$translate(refValue,.cfg,.fn,startpos,endpos)
	S pat(fname)=refValue
	Q
joinFields(cfg,pat,fn,idNa)
	; joins value from another subnode by some identificator, which is set up in config
	; function is creating local variable with index dimension to compare values
	N searchValue,fname,ref,matchin,matchfrom,pathNa,matchingvalue,refValue,mode,startpos,endpos
	S fname=cfg("f",fn,"fname") ; fieldname
	S ref=cfg("f",fn,"ref")
	S searchValue=cfg("f",fn,"retrieve_field")
	S matchfrom=cfg("f",fn,"matching_from")
	S matchin=cfg("f",fn,"matching_on")
	S pathNa=cfg("f",fn,"subnode")
	S mode=$G(cfg("f",fn,"mode"),"")
	S startpos=$G(cfg("f",fn,"startpos"))
	S endpos=$G(cfg("f",fn,"endpos"))
	I $D(indexes(fn))=0 D indexing(searchValue,matchin,pathNa,.fn)
	S matchingvalue=$G(@idNa@(matchfrom))
	I matchingvalue'="",$D(indexes(fn,matchingvalue))=1 S refValue=$G(indexes(fn,matchingvalue)) D
	. I refValue'="" D 
	. . I mode="translate" S refValue=$$translate(refValue,.cfg,.fn,startpos,endpos)
	. . S pat(fname)=refValue Q
	Q
indexing(searchValue,matchin,pathNa,fn)
	; creates indexes from searched subnode values
	N currentindex
	N i
	S i="" F  S i=$O(@pathNa@(i)) Q:i=""  D
	. S currentindex=$G(@pathNa@(i,matchin))
	. I currentindex'="" S indexes(fn,currentindex)=$G(@pathNa@(i,searchValue)) Q
	Q
translate(refValue,cfg,fn,startpos,endpos)
	; translates values in value field corresponding to dictionary by standard logic
	; by default, translating all words
	N ref,refNa,refIdDelim,refIdSubst,length,i,translation,startposition,endposition
	S ref=cfg("f",fn,"ref")
	S refNa=$na(@cfg("$na")@("C"_ref))
	S refIdDelim=cfg("refId","delim")
	S refIdSubst=cfg("refId","subst")
	S length=$L(refValue,refIdDelim)
	S startposition=$G(startpos,"1") ; defaults
	S endposition=$G(endpos,length)  ; defaults
	F i=1:1:length S $P(translation,refIdSubst,i)=@refNa@($P(refValue,refIdDelim,i))
	S refValue=$P(translation,startposition,endposition)
	Q translation
directGet(cfg,pat,fn,idNa)
	; gets a value direct from ref, without any translation: the simplest method of all
	N fname,ref,refValue
	S fname=cfg("f",fn,"fname")
	S ref=cfg("f",fn,"ref")
	S refValue=$G(@idNa@(ref))
	S pat(fname)=refValue
	Q
sumNumbers(cfg,pat,fn,idNa)
	; Sums space-delimited numeric parts if multiple values present; keeps single value as-is
	; Example: "6450 -6450 6222" -> 6222
	N fname,ref,raw,parts,total,i,part,count
	S fname=cfg("f",fn,"fname")
	S ref=cfg("f",fn,"ref")
	S raw=$G(@idNa@(ref))
	S count=$L(raw," ")
	I count'>1 S pat(fname)=raw Q
	S total=0
	F i=1:1:count S part=$P(raw," ",i) I part'="" S total=total+part
	S pat(fname)=total
	Q
firstToken(cfg,pat,fn,idNa)
	; Takes only the first whitespace-delimited token from a value
	; Example: "0 12.07.2023 09:00-15:00" -> "0"
	N fname,ref,raw
	S fname=cfg("f",fn,"fname")
	S ref=cfg("f",fn,"ref")
	S raw=$G(@idNa@(ref))
	S pat(fname)=$P(raw," ",1)
	Q
setRef(cfg,pat,fn,idNa) ; fn=2 idNa=$na(^Q(1,153,"оAAAAAC"))
	N fname,ref,refId,refNa,refValue,refIdDelim,refIdSubst
	N p,lp
	S fname=cfg("f",fn,"fname") ; lastname
	S ref=cfg("f",fn,"ref") ; pF
	S refId=$G(@idNa@(ref))
	I refId="" Q
	S refNa=$na(@cfg("$na")@("C"_ref)) ; ^Q(1,"CpF")
	S refIdDelim=cfg("refId","delim")
	S refIdSubst=cfg("refId","subst")
	S lp=$L(refId,refIdDelim)
	F p=1:1:lp S $P(refValue,refIdSubst,p)=@refNa@($P(refId,refIdDelim,p))
	S pat(fname)=refValue
	Q
concatRefs(cfg,pat,fn,idNa)
	; Concatenates several translated refs into a single string in defined order
	; Example config:
	; S cfg("f",6,"method")="concatRefs"
	; S cfg("f",6,"fname")="patient_full_name"
	; S cfg("f",6,"ref",1)="pF" ; lastname
	; S cfg("f",6,"ref",2)="pG" ; name
	; S cfg("f",6,"ref",3)="pH" ; surname
	; S cfg("f",6,"delim")=" "
	N fname,order,refKey,refId,refNa,refIdDelim,refIdSubst,lp,p,part,delim,result
	S fname=cfg("f",fn,"fname")
	S delim=$G(cfg("f",fn,"delim")," ")
	S refIdDelim=cfg("refId","delim")
	S refIdSubst=cfg("refId","subst")
	S order=0,result=""
	F  S order=$O(cfg("f",fn,"ref",order)) Q:order=""  D
	. S refKey=cfg("f",fn,"ref",order)
	. S refId=$G(@idNa@(refKey))
	. Q:refId=""
	. S refNa=$na(@cfg("$na")@("C"_refKey))
	. S lp=$L(refId,refIdDelim)
	. K part S part=""
	. F p=1:1:lp S $P(part,refIdSubst,p)=$G(@refNa@($P(refId,refIdDelim,p)))
	. Q:part=""
	. I result'="" S result=result_delim_part
	. E  S result=part
	S pat(fname)=result
	Q
docType(cfg,pat,fn,idNa)
	N longIdNa,docType,ref,fname
	S longIdNa=$$longIdNa(cfg("$na"),160,idNa)
	Q:longIdNa=""
	S ref=cfg("f",fn,"ref") ; pnD
	S docType=$G(@longIdNa@(ref))
	Q:docType=""
	S fname=cfg("f",fn,"fname") ; docType
	S pat(fname)=docType
	Q
null(cfg,pat,fn,idNa)
	; Always returning null. This is a placeholder function, which is using, when we don't actually know, where is field in the base, containing information.;
	; This placeholder is needed, because we're also testing CSV upload to ETL and then to DWH.;
	N fname
	S fname=cfg("f",fn,"fname")
	S pat(fname)="null"
	Q
setLongRef(cfg,pat,fn,idNa)
	; << TODO -dup docType
	N entity,longIdNa,ref,refId,refNa,refValue,fname
	S entity=cfg("f",fn,"entity")
	S longIdNa=$$longIdNa(cfg("$na"),entity,idNa) ; ^Q(1,160,"оAAAAACAAAA")
	Q:longIdNa=""
	; >> TODO -dup
	; << TODO -dup setRef
	S fname=cfg("f",fn,"fname") ; docU/docV
	S ref=cfg("f",fn,"ref") ; pU/pV
	S refId=$G(@longIdNa@(ref))
	Q:refId=""
	S refNa=$na(@cfg("$na")@("C"_ref)) ; ^Q(1,"CpV")
	; >> TODO -dup
	S refValue=$G(@refNa@(refId))
	S:refValue'="" pat(fname)=refValue
	Q
longConcatRefs(cfg,pat,fn,idNa)
	; Concatenates several long-ref translated fields from another entity into one string
	; Uses longIdNa (like setLongRef) and then dictionary Cp<refKey> for each part
	; Example config:
	; S cfg("f",11,"method")="longConcatRefs"
	; S cfg("f",11,"fname")="patinet_address"
	; S cfg("f",11,"entity")=156
	; S cfg("f",11,"ref",1)="pZ"  ; country
	; S cfg("f",11,"ref",2)="pN"  ; city
	; S cfg("f",11,"ref",3)="pP"  ; street
	; S cfg("f",11,"ref",4)="pQ"  ; house
	; S cfg("f",11,"ref",5)="pR"  ; building
	; S cfg("f",11,"ref",6)="pS"  ; apartment
	; S cfg("f",11,"ref",7)="pM"  ; number
	; S cfg("f",11,"delim")=", "
	N fname,entity,longIdNa,order,refKey,code,refNa,part,delim,result
	S fname=cfg("f",fn,"fname")
	S delim=$G(cfg("f",fn,"delim"),", ")
	S entity=cfg("f",fn,"entity")
	S longIdNa=$$longIdNa(cfg("$na"),entity,idNa)
	Q:longIdNa=""
	S result="",order=0
	F  S order=$O(cfg("f",fn,"ref",order)) Q:order=""  D
	. S refKey=cfg("f",fn,"ref",order)
	. S code=$G(@longIdNa@(refKey))
	. Q:code=""
	. S refNa=$na(@cfg("$na")@("C"_refKey))
	. S part=$G(@refNa@(code))
	. Q:part=""
	. I result'="" S result=result_delim_part
	. E  S result=part
	S pat(fname)=result
	Q
setLongRefWithCondition(cfg,pat,fn,idNa)
	N entity,ref,refValue,fname,p,baseNa,conditionPath,lengthId,id
	S entity=cfg("f",fn,"entity")
	S fname=cfg("f",fn,"fname") ; login
	S ref=cfg("f",fn,"ref") ; Msogl
	S id=$QS(idNa,$QL(idNa)) ; current id, оAAAAAC: end inside this node, do not go forward to оAAAAAD
	S lengthId=$L(id)
	S baseNa=$na(@cfg("$na")@(entity)) ; ^Q(1,2533)
	S conditionPath=$na(cfg("f",fn,"condition")) ; cfg("f",fn,"condition"): to pass to checkAllConditions
	S p=id F  S p=$O(@baseNa@(p)) Q:p=""  Q:$E(p,1,lengthId)'=id  D
	. I $$checkAllConditions(conditionPath,$na(@baseNa@(p))) D
	. . S refValue=$G(@baseNa@(p,ref))
	. . I refValue'="" S pat(fname)=refValue Q
	Q
checkAllConditions(condPath,recordNa)
	N condNum,condfieldNa,predicate,result
	S result=1
	S condNum="" F  S condNum=$O(@condPath@(condNum)) Q:condNum=""  D  Q:'result
	. I @condPath@(condNum,"condfield")="self" S condfieldNa=recordNa
	. E  S condfieldNa=$NA(@recordNa@(@condPath@(condNum,"condfield"))) ; ^Q(1,2533,longId,"condfield")
	. S predicate=@condPath@(condNum,"predicate")
	. I @predicate Q
	. E  S result=0 Q
	Q result
longIdNa(startNa,nextInd,idNa)
	N id,longId,lengthId
	S id=$QS(idNa,$QL(idNa))
	S lengthId=$L(id)
	S longId=$O(@startNa@(nextInd,id_$c(255,255,255,255,255)),-1)
	I id]]longId,$E(longId,1,lengthId)'=id Q ""
	Q $na(@startNa@(nextInd,longId))
extractRef(cfg,pat,fn,idNa)
	; Extracting substring from current node name idNa (fixed length).;
	; Length should be set by:
	; S cfg("f",1,"startpos")=1 ; starting position
	; S cfg("f",1,"endpos")=7   ; ending position
	N fname,startpos,endpos
	S fname=cfg("f",fn,"fname")
	S startpos=cfg("f",fn,"startpos")
	S endpos=cfg("f",fn,"endpos")
	S pat(fname)=$E($QS(idNa,$QL(idNa)),startpos,endpos)
	Q
parseRasp(cfg,stat,entityNa,tablename,filialName,filialId,scope)
	; Parses rasp nodes and writes flattened schedule rows into ^usrextensionbi(tablename,*)
	N id,idNa,marker,scheduleDate,slot,slotValue,basePat,pat,isValid,recordId
	S id="" F  S id=$O(@entityNa@(id)) Q:id=""  D
	. I scope="byFilial",filialId'="",$E(id,1,4)'=filialId Q
	. S idNa=$na(@entityNa@(id))
	. K basePat
	. D buildScheduleStaticPat(.cfg,.basePat,idNa)
	. S marker=""
	. F  S marker=$O(@idNa@(marker)) Q:marker=""  D
	. . I marker'="YSG" Q  ; only timetable marker needed
	. . S scheduleDate=""
	. . F  S scheduleDate=$O(@idNa@(marker,scheduleDate)) Q:scheduleDate=""  D
	. . . N slotNa S slotNa=$na(@idNa@(marker,scheduleDate))
	. . . I $D(@slotNa)<10 Q  ; no slots under this date
	. . . S slot=""
	. . . F  S slot=$O(@slotNa@(slot)) Q:slot=""  D
	. . . . S slotValue=$G(@slotNa@(slot))
	. . . . K pat M pat=basePat
	. . . . D setScheduleSlotFields(.pat,scheduleDate,slot,slotValue)
	. . . . S isValid=$$isValid(.cfg,.pat)
	. . . . I $I(stat("isValid",isValid))
	. . . . Q:'isValid
	. . . . S recordId=id_"|"_scheduleDate_"|"_slot
	. . . . M ^usrextensionbi(tablename,filialName,recordId)=pat
	Q
parseDepartments(cfg,stat,entityNa,tablename,filialName,filialId,scope)
	; Builds department list from unique department_id values in doctors export for this filial
	; Expects doctors export to be already populated in ^usrextensionbi("doctors",filialName,*,"department_id")
	N usedDept,id,deptId
	; collect unique department ids from doctors for this filial
	S id=""
	F  S id=$O(^usrextensionbi("doctors",filialName,id)) Q:id=""  D
	. S deptId=$G(^usrextensionbi("doctors",filialName,id,"department_id"))
	. I deptId'="" S usedDept(deptId)=""
	; now, for each unique deptId, use standard writeToGlobal flow with entityNa=^Q(1,153)
	S deptId=""
	F  S deptId=$O(usedDept(deptId)) Q:deptId=""  D
	. D writeToGlobal(.cfg,.stat,entityNa,deptId,.tablename,.filialName)
	Q
parseTreatSchedule(cfg,stat,entityNa,tablename,filialName,filialId,scope)
	; Parses ^QNaz(5,doctor_id,date,slot,0,service_id) linkages to build treat schedule records
	; Structure: ^QNaz(5,doctor_id,date,slot,0,service_id)="1"
	N doctorId,date,slot,serviceId,serviceNa,pat,isValid,recordId,outBase
	S outBase=$G(cfg("$out"),$na(^usrextensionbi))
	S doctorId=""
	F  S doctorId=$O(^QNaz(5,doctorId)) Q:doctorId=""  D
	. I scope="byFilial",filialId'="",$E(doctorId,1,3)'=filialId Q
	. S date=""
	. F  S date=$O(^QNaz(5,doctorId,date)) Q:date=""  D
	. . S slot=""
	. . F  S slot=$O(^QNaz(5,doctorId,date,slot)) Q:slot=""  D
	. . . S serviceId=""
	. . . F  S serviceId=$O(^QNaz(5,doctorId,date,slot,0,serviceId)) Q:serviceId=""  D
	. . . . S serviceNa=$na(@entityNa@(serviceId))
	. . . . I '$D(@serviceNa) Q  ; service record doesn't exist
	. . . . K pat
	. . . . D buildTreatSchedulePat(.cfg,.pat,serviceNa,serviceId,doctorId,date,slot)
	. . . . S isValid=$$isValid(.cfg,.pat)
	. . . . ; additional validation: slot times must be different
	. . . . I isValid,$G(pat("treat_schedule_slot_start_time"))=$G(pat("treat_schedule_slot_end_time")) S isValid=0
	. . . . I $I(stat("isValid",isValid))
	. . . . Q:'isValid
	. . . . S recordId=serviceId_"|"_doctorId
	. . . . M @outBase@(tablename,filialName,recordId)=pat
	Q
buildTreatSchedulePat(cfg,pat,serviceNa,serviceId,doctorId,date,slot)
	; Builds pat array for treat schedule from service record and QNaz linkage
	N fn,method,startTime,endTime,dateCode,dateValue
	; treat_schedule_id: concatenation of service_id and doctor_id
	S pat("treat_schedule_id")=serviceId_doctorId
	; treat_schedule_date: from date parameter (already numeric YYYYMMDD)
	S pat("treat_schedule_date")=date
	; treat_schedule_slot_start_time and end_time: parse slot "HH:MM-HH:MM"
	S startTime=$P(slot,"-",1)
	S endTime=$P(slot,"-",2)
	I startTime="" S startTime=slot
	I endTime="" S endTime=startTime
	S pat("treat_schedule_slot_start_time")=startTime
	S pat("treat_schedule_slot_end_time")=endTime
	; patient_id: positions 1-7 from service_id
	S pat("patient_id")=$E(serviceId,1,7)
	; filial_id: positions 1-4 from service_id
	S pat("filial_id")=$E(serviceId,1,4)
	; doctor_id: from QNaz linkage
	S pat("doctor_id")=doctorId
	; other fields via standard methods
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D
	. I $D(pat(cfg("f",fn,"fname"))) Q  ; already set above
	. S method=$G(cfg("f",fn,"method"),"setRef")
	. D @(method_"(.cfg,.pat,fn,serviceNa)")
	Q
buildScheduleStaticPat(cfg,basePat,idNa)
	; Builds part of pat that is the same for every slot within idNa
	N fn,method
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D
	. I fn?1.N,fn>1,fn<6 Q  ; skip date/time fields, filled per slot
	. S method=$G(cfg("f",fn,"method"),"setRef")
	. D @(method_"(.cfg,.basePat,fn,idNa)")
	Q
setScheduleSlotFields(pat,scheduleDate,slot,slotValue)
	N startTime,endTime
	S pat("work_schedule_date")=scheduleDate
	S startTime=$P(slot,"-",1)
	S endTime=$P(slot,"-",2)
	I startTime="" S startTime=slot
	I endTime="" S endTime=startTime
	S pat("work_schedule_slot_start_time")=startTime
	S pat("work_schedule_slot_end_time")=endTime
	S pat("work_schedule_type")=$$normalizeScheduleType(slotValue)
	Q
normalizeScheduleType(slotValue)
	N cleaned
	S slotValue=$G(slotValue)
	S cleaned=$TR(slotValue,"~")
	I slotValue="" Q "default"
	I cleaned="" Q "default"
	Q slotValue
extractRefwithCondition(cfg,pat,fn,idNa)
	; Extracting substring from current node name idNa (fixed length).;
	; Length should be set by:
	; S cfg("f",1,"startpos")=1 ; starting position
	; S cfg("f",1,"endpos")=7   ; ending position
	N fname,startpos,endpos,conditionPath
	S fname=cfg("f",fn,"fname")
	S startpos=cfg("f",fn,"startpos")
	S endpos=cfg("f",fn,"endpos")
	S conditionPath=$na(cfg("f",fn,"condition"))
	I $$checkAllConditions(conditionPath,idNa) S pat(fname)=$E($QS(idNa,$QL(idNa)),startpos,endpos)
	Q
wordWrap(cfg,pat,fn,idNa)
	; Translating words with C_ref dictionary and selecting them for final upload. Could be set as:
	; S cfg("f",14,"method")="wordWrap"
	; S cfg("f",14,"words")=1 ; position of word we need
	; OR
	; S cfg("f",14,"words")="all" ; for all of them
	; For now, there is no range support: I suppose, I will add it, when there would be a need
	N fname,words,count,delim,wordslength,ref,translation,p,dictionaryNa
	S fname=cfg("f",fn,"fname") ; field
	S count=cfg("f",fn,"words") ; how much should we take from words array
	S ref=cfg("f",fn,"ref")		; pF
	S dictionaryNa=$na(@cfg("$na")@("C"_ref)) ; dictionary name, ^Q(1,"CpF")
	S delim=" "
	S words=$G(@idNa@(ref))
	I words="" Q
	S wordslength=$L(words,delim)
	I count="all" D
	. F p=1:1:wordslength S $P(translation,delim,p)=@dictionaryNa@($P(words,delim,p))
	E  S translation=@dictionaryNa@($P(words,delim,count))
	S pat(fname)=translation
	Q
processRowOld(cfg,stat,entityNa,id)
	N fn,pat,idNa,method,isValid
	S idNa=$na(@entityNa@(id))
	;S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D setRef(.cfg,.pat,fn,idNa)
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D
	. S method=$G(cfg("f",fn,"method"),"setRef")
	. D @(method_"(.cfg,.pat,fn,idNa)")
	S isValid=$$isValid(.cfg,.pat)
	I $I(stat("isValid",isValid))
	I isValid D writeRow(.cfg,.pat)
	Q
processRow(tablename,id,cfg,filialName)
	N r,fn,delim,value,fieldname
	S delim="|"
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D
	. S fieldname=$G(cfg("f",fn,"fname"))
	. S value=$G(^usrextensionbi(tablename,filialName,id,fieldname))
	. S value=$$sanitizeValue(value)
	. S $P(r,delim,fn)=value
	w r,!
	Q
isValid(cfg,pat)
	N fn,result
	S result=1
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D  Q:'result
	. I $D(cfg("f",fn,"required")),$G(pat(cfg("f",fn,"fname")))="" S result=0 Q
	Q result
writeRow(cfg,pat)
	N fn,r,delim,value
	S delim="|"
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D
	. S value=$G(pat(cfg("f",fn,"fname")))
	. S value=$$sanitizeValue(value)
	. S $P(r,delim,fn)=value
	w r,!
	Q
writeToGlobal(cfg,stat,entityNa,id,tablename,filialName)
	N fn,pat,idNa,method,isValid,outBase
	S outBase=$G(cfg("$out"),$na(^usrextensionbi))
	S idNa=$na(@entityNa@(id))
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D
	. S method=$G(cfg("f",fn,"method"),"setRef")
	. D @(method_"(.cfg,.pat,fn,idNa)")
	S isValid=$$isValid(.cfg,.pat)
	I $I(stat("isValid",isValid))
	I isValid D
	. I $I(@outBase)
	. M @outBase@(tablename,filialName,id)=pat
	Q
sanitizeValue(value)
	N sanitized
	S sanitized=$TR(value,$C(13)_$C(10),"  ")
	Q sanitized