	Q
selftest
	W "before ok",!
	D assertEquals(1,1)
	W "after ok",!
	D assertEquals(1,2,"not eq")
	W "after fail",!
	Q
assertEquals(expected,actual,msg)
	I expected'=actual G fail
	Q
fail
	S $ECODE=$S($D(msg)=1:msg_": ",1:"")_expected_" != "_actual
	;