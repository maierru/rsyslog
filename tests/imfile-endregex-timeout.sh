#!/bin/bash
# This is part of the rsyslog testbench, licensed under ASL 2.0
echo ======================================================================
echo [imfile-endregex-timeout.sh]
. $srcdir/diag.sh check-inotify-only
. $srcdir/diag.sh init
generate_conf
add_conf '
module(load="../plugins/imfile/.libs/imfile"
       timeoutGranularity="5"
      )
input(type="imfile"
      File="./rsyslog.input"
      Tag="file:"
      PersistStateInterval="1"
      readTimeout="2"
      startmsg.regex="^[^ ]")
template(name="outfmt" type="list") {
  constant(value="HEADER ")
  property(name="msg" format="json")
  constant(value="\n")
}
if $msg contains "msgnum:" then
 action(
   type="omfile"
   file="rsyslog.out.log"
   template="outfmt"
 )
'
startup

# we need to sleep a bit between writes to give imfile a chance
# to pick up the data (IN MULTIPLE ITERATIONS!)
echo 'msgnum:0
 msgnum:1' > rsyslog.input
./msleep 10000
echo ' msgnum:2
 msgnum:3' >> rsyslog.input
# the next line terminates our test. It is NOT written to the output file,
# as imfile waits whether or not there is a follow-up line that it needs
# to combine.
echo 'END OF TEST' >> rsyslog.input
./msleep 2000

shutdown_when_empty # shut down rsyslogd when done processing messages
wait_shutdown    # we need to wait until rsyslogd is finished!

printf 'HEADER msgnum:0\\\\n msgnum:1
HEADER  msgnum:2\\\\n msgnum:3\n' | cmp - rsyslog.out.log
if [ ! $? -eq 0 ]; then
  echo "invalid multiline message generated, rsyslog.out.log is:"
  cat rsyslog.out.log
  exit 1
fi;

exit_test
