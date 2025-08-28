%gtmcc  ; entry points to access GT.M
	quit
	;
xecute(var,error)
	s ^a($I(^a))="X:"_var
	xecute var
	quit:$quit 0 quit
	;
do(var,error)
	s ^a($I(^a))="D:"_var
	do @var
	quit:$quit 0 quit
	;
set(var,value,error)
	s ^a($I(^a))="S:"_var_"="_value
	set @var=value
	quit:$quit 0 quit
	;
get(var,value,error)
	set value=@var
	s:+$G(^s("G")) ^a($I(^a))="G:"_var_"="_value
	quit:$quit 0 quit
	;