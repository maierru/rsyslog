#!/bin/bash
# This test simulates the case where the OS force-terminates rsyslog
# before it completely finishes persisting the queue to disk. Obviously,
# there is some data loss involved, but rsyslog should try to limit it.
# Most importantly, a .qi file needs to be written at "save" places, so that
# at least the queue is kind of readable.
# To simulate the error condition, we create a DA queue with a large memory
# part and fill it via injectmsg (do NOT use tcpflood, as this would add
# complexity of TCP window etc to the reception of messages - injecmsg is
# synchronous, so we do not have anything in flight after it terminates).
# We have a blocking action which prevents actual processing of any of the
# injected messages. We then inject a large number of messages, but only
# few above the number the memory part of the disk can hold. So the disk queue
# begins to get used. Once injection is done, we terminate rsyslog in the
# regular way, which will cause the memory part of the queue to be written
# out. After a relatively short period, we kill -9 rsyslogd, so that it
# does not have any chance to fully persists its state (this actually is
# what happens when force-terminated by the OS).
# Then, we check that at a minimum the .qi file exists.
# Copyright (C) 2016 by Rainer Gerhards
# Released under ASL 2.0
echo ===============================================================================

#uncomment the following if you want a log for step 1 of this test
#export RSYSLOG_DEBUG="debug nologfuncflow noprintmutexaction nostdout"
#export RSYSLOG_DEBUGLOG="log"

. $srcdir/diag.sh init
generate_conf
add_conf '
module(load="../plugins/omtesting/.libs/omtesting")

# set spool locations and switch queue to disk-only mode
$WorkDirectory test-spool
main_queue(queue.filename="mainq" queue.saveonshutdown="on"
           queue.timeoutshutdown="1" queue.maxfilesize="1m"
	   queue.timeoutworkerthreadshutdown="500" queue.size="200000"
	   )

$template outfmt,"%msg:F,58:2%\n"
$template dynfile,"rsyslog.out.log" # trick to use relative path names!
#:msg, contains, "msgnum:" ?dynfile;outfmt
:msg, contains, "msgnum:" :omtesting:sleep 10 0
'
startup
$srcdir/diag.sh injectmsg  0 210000
echo spool files immediately before shutdown:
ls test-spool
. $srcdir/diag.sh shutdown-immediate # shut down without the ability to fully persist state
./msleep 750	# simulate an os timeout (let it run a *very short* bit, else it's done ;))
echo spool files immediately after shutdown \(but before kill\):
ls test-spool


. $srcdir/diag.sh kill-immediate   # do not give it sufficient time to shutdown
wait_shutdown
echo spool files after kill:
ls test-spool

if [ ! -f test-spool/mainq.qi ]; then
    echo "FAIL: .qi file does not exist!"
    error_exit 1
fi

echo .qi file contents:
cat test-spool/mainq.qi


# We now restart rsyslog and make sure it'll clean up the disk queue.
# So far, we cannot reliably detect if the data is properly shuffled
# over, but that's a moot point anyhow because we expect to loss
# (large) amounts of the data. In later stages, we however may verify

#uncomment the following if you want a log for step 2 of this test
#export RSYSLOG_DEBUG="debug nologfuncflow noprintmutexaction nostdout"
#export RSYSLOG_DEBUGLOG="log2"

echo RSYSLOG RESTART
generate_conf
add_conf '
module(load="../plugins/omtesting/.libs/omtesting")

# set spool locations and switch queue to disk-only mode
$WorkDirectory test-spool
main_queue(queue.filename="mainq" queue.saveonshutdown="on"
           queue.timeoutshutdown="1" queue.maxfilesize="1m"
	   queue.timeoutworkerthreadshutdown="500" queue.size="200000"
	   )

$template outfmt,"%msg:F,58:2%\n"
$template dynfile,"rsyslog.out.log" # trick to use relative path names!
:msg, contains, "msgnum:" ?dynfile;outfmt
'
startup
#. $srcdir/diag.sh wait-queueempty
#echo existing queue empty, injecting new data
#$srcdir/diag.sh injectmsg  1000000 1000
shutdown_when_empty 
wait_shutdown

# now the spool directory must be empty
spoolFiles=`ls test-spool/`

if [[ ! -z $spoolFiles ]]; then
    echo "FAIL: spool directory is not empty!"
    ls -l test-spool
    error_exit 1
fi

# check if we got at least some data
if [ ! -f rsyslog.out.log ]; then
    echo "FAIL: no output data gathered (no rsyslog.out.log)!"
    error_exit 1
fi

#seq_check 0 19999 # so far this does not look doable (see comment above)

exit_test
