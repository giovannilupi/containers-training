#!/bin/bash

CGDIR=/sys/fs/cgroup
CPUSET=0
CPU=0

echo ""
echo "Creating two new containers, running alpine and debian..."

#run two containers and save their full IDs into variables
ALPLONGID=$(docker run -t -d --cgroup-parent="ctr_user.slice" alpine /bin/sh)
DEBLONGID=$(docker run -t -d --cgroup-parent="ctr_user.slice" debian /bin/sh)

# fetch the short ID of the container running alpine 
ALPID=$(docker container ps | grep alpine | awk '{print $1}')
# fetch the PID of the shell running inside the container 
ALPSHPID=$(docker top $ALPID | grep root | awk '{print $2}')

# fetch the short ID of the container running debian
DEBID=$(docker container ps | grep debian | awk '{print $1}')
# fetch the PID of the shell running inside the container 
DEBSHPID=$(docker top $DEBID | grep root | awk '{print $2}')

echo ""
docker container ps
sleep 6

echo ""
echo "The container running alpine is in the following cgroup:"
cat /proc/$ALPSHPID/cgroup

echo ""
echo "The container running debian is in the following cgroup:"
cat /proc/$DEBSHPID/cgroup

sleep 10

echo ""
echo "Let's run a burner process in both containers"
docker exec $ALPID sh -c "while true ; do : ; done &"
docker exec $DEBID sh -c "while true ; do : ; done &"

sleep 15

# the root cgroup is exercising resource limitation on the directory, which contains both containers
echo "Now let's bind the parent cgroup of both containers to cpu #2"
if grep cpuset $CGDIR/cgroup.subtree_control > /dev/null 2>&1; then
    echo "cpuset already in subtree_control"
else
    # enable the cpu controller in the children cgroups of the root
    echo "+cpuset" > $CGDIR/cgroup.subtree_control
    CPUSET=1
    echo "Added cpuset to subtree_control"
fi
echo 2 > $CGDIR/ctr_user.slice/cpuset.cpus 
sleep 18

echo ""
echo "Let's now activate the cpu controller as well to limit CPU 2 consumption to 50%"
if grep "cpu\b" $CGDIR/cgroup.subtree_control > /dev/null 2>&1; then
    echo "cpu already in subtree_control"
else
    # enable the cpu controller in the children cgroups of the root
    echo "+cpu" > $CGDIR/cgroup.subtree_control
    CPU=1
    echo "Added cpu to subtree_control"
fi
echo '50000 100000' > $CGDIR/ctr_user.slice/cpu.max
sleep 20

echo ""
echo "It's also possible to limit a single container without affecting the other..."
sleep 1
# here control is exercised on a single container
echo "Let's further limit the cpu consumption of the alpine container to 10%"
echo "+cpu" > $CGDIR/ctr_user.slice/cgroup.subtree_control
#concatenate strings
FNAME="docker-$ALPLONGID.scope"
echo '10000 100000' > $CGDIR/ctr_user.slice/$FNAME/cpu.max
sleep 20

echo ""
echo "Now let's try to run ubuntu in another container, binding it to cpu 3 using a docker run flag"
echo "This time we use the default cgroup location for a docker container"

#run the container and save its full ID into a variable
UBLONGID=$(docker run -t -d --cpuset-cpus=3 ubuntu /bin/sh)

# fetch the PID of the shell running inside the container 
UBSHPID=$(docker top $UBLONGID | grep root | awk '{print $2}')

echo ""
docker container ps
sleep 6

echo ""
echo "The container running ubuntu is in the following cgroup:"
cat /proc/$UBSHPID/cgroup
sleep 8

echo ""
echo "Let's run the burner process inside the new container"
docker exec $UBLONGID sh -c "while true ; do : ; done &"
sleep 15

echo ""
echo "Let's now limit the cpu consumption of the container to 30% by using the docker update command"
docker update --cpu-quota=30000 --cpu-period=100000 $UBLONGID
sleep 2
echo "Under the hood, the command modified the cpu.max file of the container's cgroup which now contains:"
UFNAME="docker-$UBLONGID.scope"
cat $CGDIR/system.slice/$UFNAME/cpu.max
sleep 20

#clean up
echo ""
echo "Cleaning up..."
docker kill $ALPID $DEBID $UBLONGID
sleep 2
rmdir $CGDIR/ctr_user.slice

if [ $CPUSET = "1" ]; then
    echo "-cpuset" > $CGDIR/cgroup.subtree_control
    echo "Remove cpuset from subtree_control"
fi

if [ $CPU = "1" ]; then
    echo "-cpu" > $CGDIR/cgroup.subtree_control
    echo "Remove cpu from subtree_control"
fi

exit
