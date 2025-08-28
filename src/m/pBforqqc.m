	D usage Q
usage
	W "Export pB by qqc from qMS",!
	W "Usage:",!
	W " export to current device: d main(""qqc"")^"_$ZSOURCE,!
	Q
main(qqc)
	N pBref,pB
	S pBref=$G(^Q(1,153,qqc,"pB"))
	S pB=$G(^Q(1,"CpB",pBref))
	W pB,!
	Q