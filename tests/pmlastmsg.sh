#!/bin/bash
# add 2018-06-29 by Pascal Withopf, released under ASL 2.0
. $srcdir/diag.sh init
generate_conf
add_conf '
module(load="../plugins/pmlastmsg/.libs/pmlastmsg")
module(load="../plugins/imtcp/.libs/imtcp")
input(type="imtcp" port="13514" ruleset="ruleset1")

template(name="outfmt" type="string" string="%msg%\n")

ruleset(name="ruleset1" parser=["rsyslog.lastline","rsyslog.rfc5424","rsyslog.rfc3164"]) {
	action(type="omfile" file="rsyslog.out.log"
	       template="outfmt")
}

'
startup
. $srcdir/diag.sh tcpflood -m1 -M "\"<13>last message repeated 5 times\""
. $srcdir/diag.sh tcpflood -m1 -M "\"<13>last message repeated 0090909787348927349875 times\""
. $srcdir/diag.sh tcpflood -m1 -M "\"<13>last message  repeated 5 times\""
. $srcdir/diag.sh tcpflood -m1 -M "\"<13>last message repeated 5 times -- more data\""
. $srcdir/diag.sh tcpflood -m1 -M "\"<13>last message repeated 5.2 times\""
. $srcdir/diag.sh tcpflood -m1 -M "\"<167>Mar  6 16:57:54 172.20.245.8 TAG: Rest of message...\""
. $srcdir/diag.sh tcpflood -m1 -M "\"<167>Mar  6 16:57:54 172.20.245.8 TAG long message ================================================================================\""
. $srcdir/diag.sh tcpflood -m1 -M "\"<34>1 2003-11-11T22:14:15.003Z mymachine.example.com su - ID47 last message repeated 5 times\""
shutdown_when_empty
wait_shutdown

echo 'last message repeated 5 times
last message repeated 0090909787348927349875 times
  repeated 5 times
 repeated 5 times -- more data
 repeated 5.2 times
 Rest of message...
 long message ================================================================================
last message repeated 5 times' | cmp - rsyslog.out.log
if [ ! $? -eq 0 ]; then
  echo "invalid response generated, rsyslog.out.log is:"
  cat rsyslog.out.log
  error_exit  1
fi;

exit_test
