#!/bin/bash
# add 2018-04-16 by Pascal Withopf, released under ASL 2.0
. $srcdir/diag.sh init
generate_conf
add_conf '
template(name="outfmt" type="string" string="%$!cim!msgnum%\n")

module(load="../plugins/mmjsonparse/.libs/mmjsonparse")
module(load="../plugins/imptcp/.libs/imptcp")
input(type="imptcp" port="13514")

action(type="mmjsonparse" cookie="@cim:" container="$!cim")
if $parsesuccess == "OK" then {
	action(type="omfile" file="./rsyslog.out.log" template="outfmt")
}
'
startup
. $srcdir/diag.sh tcpflood -m 5000 -j "@cim: "
shutdown_when_empty
wait_shutdown
seq_check  0 4999
exit_test

