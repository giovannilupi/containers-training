#!/bin/bash

CGDIR=/sys/fs/cgroup
CPU=0

# PID of the containerized shell
CPID=$(lsns -t pid | grep "/bin/sh" | awk '{print $4}')

echo ""
echo "PID of the containerized shell inside the host and inside the container:"
cat /proc/$CPID/status | grep NSpid
echo ""
sleep 5

echo "The containerized shell is currently in the following cgroup:"
cat /proc/$CPID/cgroup
echo ""
sleep 5

echo "Let's create a new cgroup to manage the processes inside the container..."
echo ""
mkdir $CGDIR/contgroup
echo $CPID > $CGDIR/contgroup/cgroup.procs
sleep 2

echo "Now the containerized shell is in cgroup:"
cat /proc/$CPID/cgroup
echo ""
sleep 5

echo "Let's activate the cpu controller inside the cgroup and limit the cpu consumption to 50%"
if grep cpu $CGDIR/cgroup.subtree_control > /dev/null 2>&1; then
    echo "cpu already in subtree_control"
else
    # enable the cpu controller in the children cgroups of the root
    echo "+cpu" > $CGDIR/cgroup.subtree_control
    CPU=1
    echo "Added cpu to subtree_control"
fi
echo '50000 100000' > $CGDIR/contgroup/cpu.max
echo ""
sleep 5

echo "Done! Now try to run the burner program inside the container and observe its behavior"
echo ""
sleep 5

top

# command line interface to the inotify subsystem
# listens for modify events on the cgroup.events file

echo ""
echo "Waiting for the container to terminate"

if grep "populated 1" $CGDIR/contgroup/cgroup.events > /dev/null 2>&1; then
    while inotifywait -q -e modify $CGDIR/contgroup/cgroup.events ; do
        #echo "[Listener]" `grep populated $CGDIR/contgroup/cgroup.events`
        # when the cgroup becomes empty, exit the loop
        if grep "populated 0" $CGDIR/contgroup/cgroup.events > /dev/null 2>&1; then
            break
        fi
    done
fi

echo ""
echo "Cleaning up"

rmdir $CGDIR/contgroup
if [ $CPU = "1" ]; then
    echo "-cpu" > $CGDIR/cgroup.subtree_control
    echo "Remove cpu from subtree_control"
fi