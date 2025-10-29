	D usage Q
	;
usage()
	W "Browse node with values, if it is accessable with C_ logic."
	W "Run with hisnumber."
	W "Usage:",!
	W "Stdout to current device: d main^"_$ZSOURCE_"(hisnumber,entity)",!
	W "Example: d main^"_$ZSOURCE_"(7/A21,2533)"
	Q
	;
main(hisnumber,entity)
	; Browse all nodes on current level with values.;
	; You can change codepage of stdout by: yottadb -run main^Browse(arg1,arg2) | iconv -f WINDOWS-1251 -t UTF-8
	; Also, there is possibility to run this as a script, check docs here:
	; https://docs.yottadb.com/ProgrammersGuide/appendix.html#appendix-b-creating-shebang-scripts
	N glNa,patObj,patNa,entityNa,id,ref,fieldValue
	S glNa=$na(^Q(1))
	S patObj=153
	S patNa=$na(@glNa@(patObj)) ; ^Q(1,153)
	S entityNa=$na(@glNa@(entity)) ; ^Q(1,2533)
	S id=$$searchByHisnumber(hisnumber,glNa,patObj) ; returns "qqc" of this hisnumber: "oAAAAAC"
	I id="" w "hisnumber was not found",! Q
	S idNa=$na(@entityNa@(id)) ; ^Q(1,2533,"oAAAAAC")
	S ref="" F  S ref=$O(@idNa@(ref)) Q:ref=""  D ; iterate over next level of subnodes
	. S fieldValue=$G(@idNa@(ref))
	. I $D(fieldValue)=0 Q
	. w ref,fieldValue,glNa,idNa
	. D decodeValuesByGlossary(ref,fieldValue,glNa,idNa)
	;	
searchByHisnumber(hisnumber,glNa,patObj)
	N ref,reverseNa,result
	S ref="pB"
	S reverseNa=$na(@glNa@(ref,hisnumber,patObj,""))
	S result=$O(@reverseNa)
	Q result
	;
decodeValuesByGlossary(ref,fieldValue,glNa,idNa)
	N glossaryNa,fieldValueLength,delimiter,refValue
	S delimiter=" "
	S glossaryNa=$na(@glNa@("C"_ref)) ; ^Q(1,"CpB")
	w $na(@idNa@(ref))_"="
	I $D(glossaryNa)=0,$D(glossaryNa)=1 D 
	. w " "_fieldValue Q ; $D could be 10,11
	S fieldValueLength=$L(fieldValue,delimiter)
	F l=1:1:fieldValueLength S $P(refValue,delimiter,l)=@glossaryNa@($P(fieldValue,delimiter,l))
	w refValue,!
	Q
	;