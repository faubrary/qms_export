	D usage Q
usage
	W "Export data for dwh from qMS",!
	W "Usage:",!
	W "Export to current device: d main^"_$ZSOURCE_"(tablename)",!
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
main(tablename)
	N cfg,stat,entityNa,id,confNa
	S confNa=tablename_"config"
	D @(confNa_"(.cfg)")
	S entityNa=$na(@cfg("$na")@(cfg("entity","pat"))) ; $na(^Q(1,153))
	D writeCSVHeader(.cfg)
	S id="" F  S id=$O(@entityNa@(id)) Q:id=""  D processRow(.cfg,.stat,entityNa,id)
	;W "== Statistics ==",! ZWR stat
	Q
treatservicestestconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("entity","pat")=1860
	;
	S cfg("f",1,"ref")="id"
	S cfg("f",1,"fname")="treat_id"
	S cfg("f",1,"method")="extractRef"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=23
	S cfg("f",1,"required")="true"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	Q
treatservicesconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("entity","pat")=1860
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
	S cfg("f",17,"ref")="n1000"
	S cfg("f",17,"fname")="clinic_prim_treat"
	S cfg("f",17,"method")="joinByIndex"
	S cfg("f",17,"mode")="translate"
	S cfg("f",17,"subnode")=$na(@cfg("$na")@(293))
	S cfg("f",17,"retrieve_field")="n1000"
	;
	S cfg("f",18,"ref")=" "
	S cfg("f",18,"fname")="doctor_prim_treat"
	S cfg("f",18,"method")="null"
	;
	S cfg("f",19,"ref")="referral_id"
	S cfg("f",19,"fname")="referral_id"
	S cfg("f",19,"method")="null"
	;
	S cfg("f",20,"ref")=""
	S cfg("f",20,"fname")="payment_document_id"
	S cfg("f",20,"method")="null"
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
	S cfg("f",24,"method")="directGet"
	;
	S cfg("f",25,"ref")=""
	S cfg("f",25,"fname")="service_base_price"
	S cfg("f",25,"method")="null"
	;
	S cfg("f",26,"ref")=""
	S cfg("f",26,"fname")="service_real_price"
	S cfg("f",26,"method")="null"
	;
	S cfg("f",27,"ref")=""
	S cfg("f",27,"fname")="discount_name"
	S cfg("f",27,"method")="null"
	;
	S cfg("f",28,"ref")=""
	S cfg("f",28,"fname")="service_total_cost"
	S cfg("f",28,"method")="null"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	Q
	;
treatepisodesconfig(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("entity","pat")=174
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
usePreviousResult(cfg,pat,fn,idNa)
	; uses previous result (already calculated!) to retrieve additional information by another path
	; deduplicates useless calculations
	; NOTE: value MUST BE already calculated, because we're referencing pat("fname")!
joinByIndex(cfg,pat,fn,idNa)
	; joins another subnode by same index in different position
	; for example: you have ^gl(ind1,ind2,ind3), ^gl(ind1,ind3,field)="refValue" (you are iterating over ind3 in main cycle)
	; So, you may want to retrieve refValue by saying: $G(^gl(ind1,ind3,field)) 
	N id,ref,fname,searchValue,pathNa,refValue,mode,startpos,endpos
	S ref=cfg("f",fn,"ref")
	S fname=cfg("f",fn,"fname")
	S searchValue=cfg("f",fn,"retrieve_field")
	S pathNa=cfg("f",fn,"subnode")
	S mode=$G(cfg("f",fn,"mode"),"")
	S startpos=$G(cfg("f",fn,"startpos"))
	S endpos=$G(cfg("f",fn,"endpos"))
	S id=$QS(idNa,$QL(idNa))
	S refValue=$G(@pathNa@(id),"null")
	I mode="translate",refValue'="null" S refValue=$$translate(refValue,.cfg,.fn,startpos,endpos)
	S pat(fname)=refValue
	Q
	;	
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
	N fname,ref,refValue
	S fname=cfg("f",fn,"fname")
	S ref=cfg("f",fn,"ref")
	S refValue=$G(@idNa@(ref))
	S pat(fname)=refValue
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
	; TODO is pU/pV multiple index like in setRef?
	S refValue=$G(@refNa@(refId))
	S:refValue'="" pat(fname)=refValue
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
	. S condfieldNa=$NA(@recordNa@(@condPath@(condNum,"condfield"))) ; ^Q(1,2533,longId,"condfield")
	. S predicate=@condPath@(condNum,"predicate")
	. I @predicate Q
	. E  S result=0 Q
	Q result
	; . I @idNa@"pB"="7/A21" B ; for debug purposes, put it before I @predicate line
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
	S dictionaryNa=$na(@cfg("$na")@("C"_ref)) ; dictinary name, ^Q(1,"CpF")
	S delim=" "
	S words=$G(@idNa@(ref))
	I words="" Q
	S wordslength=$L(words,delim)
	I count="all" D
	. F p=1:1:wordslength S $P(translation,delim,p)=@dictionaryNa@($P(words,delim,p))
	E  S translation=@dictionaryNa@($P(words,delim,count))
	S pat(fname)=translation
	Q
processRow(cfg,stat,entityNa,id)
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
isValid(cfg,pat)
	N fn,result
	S result=1
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D  Q:'result
	. I $D(cfg("f",fn,"required")),$G(pat(cfg("f",fn,"fname")))="" S result=0 Q
	Q result
writeRow(cfg,pat)
	N fn,r,delim
	S delim="|"
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D
	. S $P(r,delim,fn)=$G(pat(cfg("f",fn,"fname")))
	w r,!
	Q