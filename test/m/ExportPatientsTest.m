all	; Run all tests
	N cfg
	; Configuration
	D config^ExportPatients(.cfg)
	S cfg("$na")=$na(q(1))
	S cfg("refId","subst")="-"
	;
	D testLastName
	D testComplexLastName
	D testIsValid
	D testLongIdNa
	D testDocType
	D testDocNumber
	D testEmail
	D testPhone
	D testLogin
	D testCheckAllConditions
	W "== All tests passed! ==",!
	Q
testLastName
	N q,pat
	S q(1,153,"оAAAAAC","pF")="Iv"
	S q(1,"CpF","Iv")="LastName"
	D setRef^ExportPatients(.cfg,.pat,2,$na(q(1,153,"оAAAAAC")))
	D assertEquals^Assert("LastName",pat("lastname"))
	Q
testComplexLastName
	N q,pat
	S q(1,153,"оAAAAAC","pF")="I1 I2"
	S q(1,"CpF","I1")="Lloyd"
	S q(1,"CpF","I2")="George"
	D setRef^ExportPatients(.cfg,.pat,2,$na(q(1,153,"оAAAAAC")))
	D assertEquals^Assert("Lloyd-George",pat("lastname"))
	Q
testIsValid
	N pat,cfg
	S cfg("f",1,"ref")="pB"
	S cfg("f",1,"fname")="hisnumber"
	S cfg("f",1,"required")="true"
	S cfg("f",5,"ref")="pI"
	S cfg("f",5,"fname")="birthdate"
	S cfg("f",5,"required")="true"
	S cfg("f",9,"ref")="email"
	S cfg("f",9,"fname")="email"
	S pat("hisnumber")="1/A25"
	D assertEquals^Assert(0,$$isValid^ExportPatients(.cfg,.pat))
	S pat("birthdate")=""
	D assertEquals^Assert(0,$$isValid^ExportPatients(.cfg,.pat))
	S pat("email")="example@yandex.ru"
	D assertEquals^Assert(0,$$isValid^ExportPatients(.cfg,.pat))
	S pat("birthdate")="19941015"
	D assertEquals^Assert(1,$$isValid^ExportPatients(.cfg,.pat))
	Q
testLongIdNa
	N q,longIdNa1,longIdNa2
	S q(1,160,"оAAAAAC","fake")="fake"
	S q(1,160,"оAAAAACAAAA","pnD")=16
	S q(1,160,"оAAAAACAAAB","pnD")=17
	S longIdNa1=$$longIdNa^ExportPatients($na(q(1)),160,$na(q(1,153,"оAAAAAC")))
	D assertEquals^Assert($na(q(1,160,"оAAAAACAAAB")),longIdNa1)
	S longIdNa2=$$longIdNa^ExportPatients($na(q(1)),160,$na(q(1,153,"оAAAAAD")))
	D assertEquals^Assert("",longIdNa2)
	Q
testDocType
	N q,pat
	S q(1,160,"оAAAAACAAAA","pnD")=16
	D docType^ExportPatients(.cfg,.pat,6,$na(q(1,153,"оAAAAAD")))
	D assertEquals^Assert(0,$D(pat("docType")))
	D docType^ExportPatients(.cfg,.pat,6,$na(q(1,153,"оAAAAAC")))
	D assertEquals^Assert(16,pat("docType"))
	Q
testDocNumber
	N q,pat
	S q(1,160,"оAAAAACAAAA","pV")="OLC"
	S q(1,"CpV","OLC")=361956
	D setLongRef^ExportPatients(.cfg,.pat,7,$na(q(1,153,"оAAAAAC")))
	D assertEquals^Assert(0,$D(pat("docU")))
	D setLongRef^ExportPatients(.cfg,.pat,8,$na(q(1,153,"оAAAAAC")))
	D assertEquals^Assert(361956,pat("docV"))
	Q
testEmail
	N q,pat
	S q(1,153,"оAAAAAC","email")="KUb"
	S q(1,"Cemail","KUb")="user@yandex.ru"
	D setRef^ExportPatients(.cfg,.pat,9,$na(q(1,153,"оAAAAAD")))
	D assertEquals^Assert(0,$D(pat("email")))
	D setRef^ExportPatients(.cfg,.pat,9,$na(q(1,153,"оAAAAAC")))
	D assertEquals^Assert("user@yandex.ru",pat("email"))
	Q
testPhone
	N q,pat
	S q(1,159,"оAAAAACAAA","pT")="OFT"
	S q(1,"CpT","OFT")="89916624844"
	D setLongRef^ExportPatients(.cfg,.pat,10,$na(q(1,153,"оAAAAAD")))
	D assertEquals^Assert(0,$D(pat("phone")))
	D setLongRef^ExportPatients(.cfg,.pat,10,$na(q(1,153,"оAAAAAC")))
	D assertEquals^Assert("89916624844",pat("phone"))
	Q
testLogin
	N q,pat
	S q(1,2533,"oAAAAACAAAA","soglNum")="aaa"
	S q(1,2533,"oAAAAACAAAA","Msogl")="case1@yandex.ru"
	S q(1,2533,"oAAAAACAAAA","Xd")="dd"
	S q(1,2533,"oAAAAACAAAB","soglNum")="F"
	S q(1,2533,"oAAAAACAAAB","Msogl")="case2@yandex.ru"
	S q(1,2533,"oAAAAACAAAB","Xd")=""
	S q(1,2533,"oAAAAACAAAC","soglNum")="bb"
	S q(1,2533,"oAAAAACAAAC","Msogl")="case3@yandex.ru"
	S q(1,2533,"oAAAAACAAAC","Xd")=""
	S q(1,2533,"oAAAAACAAAD","soglNum")="F"
	S q(1,2533,"oAAAAACAAAD","Msogl")="case4@yandex.ru"
	S q(1,2533,"oAAAAACAAAD","Xd")="ddsdfsdf"
	D setLongRefWithCondition^ExportPatients(.cfg,.pat,11,$na(q(1,153,"oAAAAAD")))
	D assertEquals^Assert(0,$D(pat("login")))
	D setLongRefWithCondition^ExportPatients(.cfg,.pat,11,$na(q(1,153,"oAAAAAC")))
	D assertEquals^Assert("case4@yandex.ru",pat("login"))
	;
testCheckAllConditions
	N q,cfg,result,condNa,dataNa
	S cfg("f",1,"condition",1,"condfield")="field1"
	S cfg("f",1,"condition",1,"predicate")="@condfieldNa=11"
	S cfg("f",1,"condition",2,"condfield")="field2"
	S cfg("f",1,"condition",2,"predicate")="@condfieldNa'=""h8"""
	S condNa=$na(cfg("f",1,"condition"))
	S dataNa=$na(q)
	;
	S q("field1")=11
	S q("field2")="a1"
	S result=$$checkAllConditions^ExportPatients(condNa,dataNa)
	D assertEquals^Assert(1,result)
	;  
	S q("field1")=22
	S q("field2")="h8"
	S result=$$checkAllConditions^ExportPatients(condNa,dataNa)
	D assertEquals^Assert(0,result)
	;  
	S q("field1")=22
	S q("field2")="h7"
	S result=$$checkAllConditions^ExportPatients(condNa,dataNa)
	D assertEquals^Assert(0,result)
	;  
	S q("field1")=11
	S q("field2")="h8"
	S result=$$checkAllConditions^ExportPatients(condNa,dataNa)
	D assertEquals^Assert(0,result)
	;  
	S cfg("f",1,"condition",2,"predicate")="$D(@condfieldNa)=0"
	S q("field1")=11
	K q("field2")
	S result=$$checkAllConditions^ExportPatients(condNa,dataNa)
	D assertEquals^Assert(1,result)
	Q
	;