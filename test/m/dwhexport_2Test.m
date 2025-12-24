all	; Run all tests for dwhexport
	N cfg
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	;
	D testExtractRef
	D testLongIdNa
	D testSumNumbers
	D testFirstToken
	D testConcatRefs
	D testLongConcatRefs
	D testCheckAllConditions
	D testWriteToOwnGlobal
	D testMain
	D testTestLabel
	D testTestupload
	W "== All dwhexport tests passed! ==",!
	Q
testExtractRef
	N q,pat,cfg
	S cfg("f",1,"fname")="filial_id"
	S cfg("f",1,"startpos")=1
	S cfg("f",1,"endpos")=3
	S q(1,153,"оAAAXX","dummy")=""
	D extractRef^dwhexport(.cfg,.pat,1,$na(q(1,153,"оAAAXX")))
	D assertEquals^Assert("оAA",pat("filial_id"))
	Q
testLongIdNa
	N q,longIdNa1,longIdNa2
	S q(1,160,"оAAAAAC","fake")="fake"
	S q(1,160,"оAAAAACAAAA","pnD")=16
	S q(1,160,"оAAAAACAAAB","pnD")=17
	S longIdNa1=$$longIdNa^dwhexport($na(q(1)),160,$na(q(1,153,"оAAAAAC")))
	D assertEquals^Assert($na(q(1,160,"оAAAAACAAAB")),longIdNa1)
	S longIdNa2=$$longIdNa^dwhexport($na(q(1)),160,$na(q(1,153,"оAAAAAD")))
	D assertEquals^Assert("",longIdNa2)
	Q
testSumNumbers
	N q,cfg,pat
	S cfg("f",1,"fname")="service_real_price"
	S cfg("f",1,"ref")="Mr7o"
	S q(1,1860,"id1","Mr7o")="6450 -6450 6222"
	D sumNumbers^dwhexport(.cfg,.pat,1,$na(q(1,1860,"id1")))
	D assertEquals^Assert(6222,pat("service_real_price"))
	; single value stays as-is
	S q(1,1860,"id2","Mr7o")="500"
	D sumNumbers^dwhexport(.cfg,.pat,1,$na(q(1,1860,"id2")))
	D assertEquals^Assert(500,pat("service_real_price"))
	Q
testFirstToken
	N q,cfg,pat
	S cfg("f",1,"fname")="service_quantity"
	S cfg("f",1,"ref")="Mn"
	S q(1,1860,"id1","Mn")="0 12.07.2023 09:00-15:00 меньше желаемого"
	D firstToken^dwhexport(.cfg,.pat,1,$na(q(1,1860,"id1")))
	D assertEquals^Assert("0",pat("service_quantity"))
	Q
testConcatRefs
	N q,cfg,pat
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	S cfg("f",1,"fname")="patient_full_name"
	S cfg("f",1,"ref",1)="pF"
	S cfg("f",1,"ref",2)="pG"
	S cfg("f",1,"ref",3)="pH"
	S cfg("f",1,"delim")=" "
	S q(1,153,"id","pF")="Iv"
	S q(1,153,"id","pG")="Jn"
	S q(1,153,"id","pH")="Sm"
	S q(1,"CpF","Iv")="Last"
	S q(1,"CpG","Jn")="Name"
	S q(1,"CpH","Sm")="Surname"
	D concatRefs^dwhexport(.cfg,.pat,1,$na(q(1,153,"id")))
	D assertEquals^Assert("Last Name Surname",pat("patient_full_name"))
	Q
testLongConcatRefs
	N q,cfg,pat
	S cfg("refId","delim")=" "
	S cfg("refId","subst")=cfg("refId","delim")
	S cfg("f",1,"fname")="patinet_address"
	S cfg("f",1,"entity")=156
	S cfg("f",1,"ref",1)="pZ"
	S cfg("f",1,"ref",2)="pN"
	S cfg("f",1,"ref",3)="pP"
	S cfg("f",1,"ref",4)="pQ"
	S cfg("f",1,"delim")=", "
	S q(1,156,"оAAAAX","pZ")="A"
	S q(1,156,"оAAAAX","pN")="B"
	S q(1,156,"оAAAAX","pP")="C"
	S q(1,156,"оAAAAX","pQ")="D"
	S q(1,"CpZ","A")="Country"
	S q(1,"CpN","B")="City"
	S q(1,"CpP","C")="Street"
	S q(1,"CpQ","D")="42"
	D longConcatRefs^dwhexport(.cfg,.pat,1,$na(q(1,153,"оAAAAA")))
	D assertEquals^Assert("Country, City, Street, 42",pat("patinet_address"))
	Q
testCheckAllConditions
	N cfg,result,condNa,dataNa
	S cfg("f",1,"condition",1,"condfield")="field1"
	S cfg("f",1,"condition",1,"predicate")="@condfieldNa=11"
	S cfg("f",1,"condition",2,"condfield")="field2"
	S cfg("f",1,"condition",2,"predicate")="@condfieldNa'="""""""""
	S condNa=$na(cfg("f",1,"condition"))
	S dataNa=$na(^TMP($J,"data"))
	K ^TMP($J,"data")
	S ^TMP($J,"data","field1")=11
	S ^TMP($J,"data","field2")="abc"
	S result=$$checkAllConditions^dwhexport(condNa,$na(^TMP($J,"data")))
	D assertEquals^Assert(1,result)
	S ^TMP($J,"data","field1")=22
	S result=$$checkAllConditions^dwhexport(condNa,$na(^TMP($J,"data")))
	D assertEquals^Assert(0,result)
	K ^TMP($J,"data")
	Q
testWriteToOwnGlobal
	; ensure writeToOwnGlobal writes using config and respects scope/system
	N q,out
	K q,out
	; prepare filials data (scope=system) in locals
	S q(1,153,"FIL123","id")="FIL123"
	S q(1,153,"FIL123","MpnOrgPl")="Hadassah"
	; call with local bases
	D writeToOwnGlobal^dwhexport("filials","",$na(q(1)),$na(out))
	; assert structure
	D assertEquals^Assert("FIL",$E($G(out("filials","","FIL123","filial_id")),1,3))
	D assertEquals^Assert("Hadassah",$G(out("filials","","FIL123","filial_name")))
	Q
testMain
	; main reads from ^usrextensionbi and writes CSV
	N out
	K out
	S out("filials","",1,"filial_id")="F01"
	S out("filials","",1,"filial_name")="Name1"
	S out("filials","",2,"filial_id")="F02"
	S out("filials","",2,"filial_name")="Name2"
	N file S file="/tmp/dwhexport_main.out"
	D runWithOutput("D main^dwhexport(""filials"","""",$na(out))",file)
	N lines D readFileLines(.lines,file)
	D assertEquals^Assert(3,$G(lines("count"))) ; header + 2 rows
	; header should contain both field names
	D assertContains^Assert(lines(1),"filial_id|filial_name")
	Q
testTestLabel
	; test^dwhexport_2 writes header + one row using processRowOld
	N q,out
	K q,out
	S q(1,153,"FIL999","id")="FIL999"
	S q(1,153,"FIL999","MpnOrgPl")="OneRow"
	N file S file="/tmp/dwhexport_test.out"
	D runWithOutput("D test^dwhexport(""filials"",""FIL999"",$na(q(1)),$na(out))",file)
	N lines D readFileLines(.lines,file)
	D assertEquals^Assert(2,$G(lines("count"))) ; header + 1 row
	Q
testTestupload
	; testupload reads ^usrextensionbi and writes first 500 rows (all we put)
	N out
	K out
	S out("filials","",1,"filial_id")="F01"
	S out("filials","",1,"filial_name")="Name1"
	S out("filials","",2,"filial_id")="F02"
	S out("filials","",2,"filial_name")="Name2"
	S out("filials","",3,"filial_id")="F03"
	S out("filials","",3,"filial_name")="Name3"
	N file S file="/tmp/dwhexport_testupload.out"
	D runWithOutput("D testupload^dwhexport(""filials"","""",$na(out))",file)
	N lines D readFileLines(.lines,file)
	D assertEquals^Assert(4,$G(lines("count"))) ; header + 3 rows
	Q
runWithOutput(code,file)
	; run code while directing output to file
	N $ET S $ET="G errRun"
	OPEN file:(newversion)
	USE file
	XECUTE code
	USE $PRINCIPAL
	CLOSE file
	Q
errRun
	USE $PRINCIPAL
	CLOSE file
	QUIT
readFileLines(lines,file)
	N cnt,line
	K lines S cnt=0
	OPEN file:(READONLY)
	USE file
	F  R line Q:$ZEOF  S cnt=cnt+1,lines(cnt)=line
	CLOSE file
	USE $PRINCIPAL
	S lines("count")=cnt
	Q
	;
	;