#!/bin/bash
# addd 2016-03-22 by RGerhards, released under ASL 2.0
. ${srcdir:=.}/diag.sh init
generate_conf
add_conf '
module(load="../plugins/imtcp/.libs/imtcp")
input(type="imtcp" port="0" listenPortFileName="'$RSYSLOG_DYNNAME'.tcpflood_port")

template(name="outfmt" type="string"
	 string="%timereported:::date-rfc3339,date-utc%\n")
:msg, contains, "msgnum:" action(type="omfile" template="outfmt"
			         file=`echo $RSYSLOG_OUT_LOG`)
'

echo "*** SUBTEST 2003 ****"
startup
tcpflood -m1 -M"\"<165>1 2003-08-24T05:14:15.000003-07:00 192.0.2.1 tcpflood 8710 - - msgnum:0000000\""
tcpflood -m1 -M"\"<165>1 2016-03-01T12:00:00-02:00 192.0.2.1 tcpflood 8710 - - msgnum:0000000\""
tcpflood -m1 -M"\"<165>1 2016-03-01T12:00:00Z 192.0.2.1 tcpflood 8710 - - msgnum:0000000\""
shutdown_when_empty
wait_shutdown
export EXPECTED="2003-08-24T12:14:15.000003+00:00
2016-03-01T14:00:00.000000+00:00
2016-03-01T12:00:00.000000+00:00"
cmp_exact

exit_test
