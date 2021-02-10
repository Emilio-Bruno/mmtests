#!/bin/bash
sigterm_pending=1

install-depends lttng-modules lttng-modules-kmp-default lttng-tools lttng-ust-devel babeltrace2

if ! command -v lttng &> /dev/null
then
	echo "LTTng could not be found"
	exit -1
fi

if ! command -v babeltrace2 &> /dev/null
then
	echo "babeltrace2 could not be found"
	exit -1
fi

trap 'sigterm_pending=0' SIGTERM

tmp=$(mktemp --dry-run mmtests-lttng-XXXXXX)
lttng create $tmp --output=/tmp/$tmp/ &> /dev/null

for EVENT in $MONITOR_LTTNG_EVENTS; do
	lttng enable-event --kernel $EVENT &> /dev/null
done

for SYSCALL in $MONITOR_LTTNG_SYSCALLS; do
	lttng enable-event --kernel --syscall $SYSCALL &> /dev/null
done

lttng start &> /dev/null

while [ $sigterm_pending -eq 1 ]; do 
	sleep infinity &
	wait $!
	kill $!
	wait $! 2>/dev/null
done

lttng destroy $tmp &> /dev/null

babeltrace2 /tmp/$tmp/*
