	D usage Q
usage
	W "Export patients from qMS",!
	W "Usage:",!
	W " export to current device: d main^"_$ZSOURCE,!
	Q
main
	N cfg,stat,patNa,id
	D config(.cfg)
	S patNa=$na(@cfg("$na")@(cfg("entity","pat"))) ; $na(^Q(1,153))
	S id="" F  S id=$O(@patNa@(id)) Q:id=""  D processPatient(.cfg,.stat,patNa,id)
	;W "== Statistics ==",! ZWR stat
	Q
config(cfg)
	S cfg("$na")=$na(^Q(1))
	S cfg("entity","pat")=153
	;
	S cfg("f",1,"ref")="pB"
	S cfg("f",1,"fname")="hisnumber"
	S cfg("f",1,"required")="true"
	;
	S cfg("f",2,"ref")="pF"
	S cfg("f",2,"fname")="lastname"
	;
	S cfg("f",3,"ref")="pG"
	S cfg("f",3,"fname")="name"
	;
	S cfg("f",4,"ref")="pH"
	S cfg("f",4,"fname")="surname"
	;
	S cfg("f",5,"ref")="pI"
	S cfg("f",5,"fname")="birthdate"
	S cfg("f",5,"required")="true"
	;
	S cfg("f",6,"ref")="pnD"
	S cfg("f",6,"fname")="docType"
	S cfg("f",6,"method")="docType"
	;
	S cfg("f",7,"ref")="pU"
	S cfg("f",7,"fname")="docU"
	S cfg("f",7,"method")="setLongRef"
	S cfg("f",7,"entity")=160
	;
	S cfg("f",8,"ref")="pV"
	S cfg("f",8,"fname")="docV"
	S cfg("f",8,"method")="setLongRef"
	S cfg("f",8,"entity")=160
	;
	S cfg("f",9,"ref")="email"
	S cfg("f",9,"fname")="email"
	;
	S cfg("f",10,"ref")="pT"
	S cfg("f",10,"fname")="phone"
	S cfg("f",10,"method")="setLongRef"
	S cfg("f",10,"entity")=159
	;
	S cfg("f",11,"ref")="Msogl"
	S cfg("f",11,"fname")="login"
	S cfg("f",11,"method")="setLongRefWithCondition"
	S cfg("f",11,"entity")=2533
	S cfg("f",11,"condition",1,"condfield")="soglNum"
	S cfg("f",11,"condition",1,"predicate")="@condfieldNa=""F"""
	S cfg("f",11,"condition",2,"condfield")="Xd"
	S cfg("f",11,"condition",2,"predicate")="$F($E(@condfieldNa,1,3),""d"")'=0"
	;
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
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
processPatient(cfg,stat,patNa,id)
	N fn,pat,idNa,method,isValid
	S idNa=$na(@patNa@(id))
	;S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D setRef(.cfg,.pat,fn,idNa)
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D
	. S method=$G(cfg("f",fn,"method"),"setRef")
	. D @(method_"(.cfg,.pat,fn,idNa)")
	S isValid=$$isValid(.cfg,.pat)
	I $I(stat("isValid",isValid))
	I isValid D writePatient(.cfg,.pat)
	Q
isValid(cfg,pat)
	N fn,result
	S result=1
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D  Q:'result
	. I $D(cfg("f",fn,"required")),$G(pat(cfg("f",fn,"fname")))="" S result=0 Q
	Q result
writePatient(cfg,pat)
	N fn,r,delim
	S delim="|"
	S fn="" F  S fn=$O(cfg("f",fn)) Q:fn=""  D
	. S $P(r,delim,fn)=$G(pat(cfg("f",fn,"fname")))
	w r,!
	Q