#!/bin/bash

uname
if [ `uname` = "SunOS" ] ; then
   echo "Solaris: FIX ME"
   exit 77
fi

./syslog_caller -fsyslog_inject-l -m0 > /dev/null 2>&1
no_liblogging_stdlog=$?
if [ $no_liblogging_stdlog -ne 0 ];then
  echo "liblogging-stdlog not available - skipping test"
  exit 77
fi
. $srcdir/diag.sh init
startup imuxsock_traillf_syssock.conf
# send a message with trailing LF
./syslog_caller -fsyslog_inject-l -m1 -C "uxsock:testbench_socket"
# the sleep below is needed to prevent too-early termination of rsyslogd
./msleep 100
shutdown_when_empty # shut down rsyslogd when done processing messages
wait_shutdown	# we need to wait until rsyslogd is finished!
cmp rsyslog.out.log $srcdir/resultdata/imuxsock_traillf.log
if [ ! $? -eq 0 ]; then
  echo "imuxsock_traillf_syssock failed"
  echo contents of rsyslog.out.log:
  echo \"`cat rsyslog.out.log`\"
  echo expected:
  echo \"`cat $srcdir/resultdata/imuxsock_traillf.log`\"
  exit 1
fi;
exit_test
