#!/bin/bash
# This file is part of the rsyslog project, released under GPLv3

. $srcdir/diag.sh init

psql -h localhost -U postgres -f testsuites/pgsql-basic.sql

startup pgsql-template.conf
. $srcdir/diag.sh injectmsg  0 5000
shutdown_when_empty
wait_shutdown 

# we actually put the message in the SysLogTag field, so we know it doesn't use the default
# template, like in pgsql-basic
psql -h localhost -U postgres -d syslogtest -f testsuites/pgsql-select-syslogtag.sql -t -A > rsyslog.out.log 

seq_check  0 4999

echo cleaning up test database
psql -h localhost -U postgres -c 'DROP DATABASE IF EXISTS syslogtest;'

exit_test
