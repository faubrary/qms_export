	D usage Q
usage
	W "Export tempCode (lk) by email from qMS",!
	W "Usage:",!
	W " export to current device: d main(""email"")^"_$ZSOURCE,!
	Q
main(email)
	w ^FeSAEMP(email)