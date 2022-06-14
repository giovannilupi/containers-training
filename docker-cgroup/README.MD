# Docker cgroup interaction example

Exploring the interaction between Docker containers and cgroup.

## Description
This folder contains three bash scripts:
- `container_runner.sh` : this is the script to invoke to run the example. It must necessarily be executed from `tmux`. It first runs `htop` in a new window and then launches `container_manager.sh` as superuser.
- `container_manager.sh` : this script runs three containers using docker. First, two containers are created using the `--cgroup-parent` flag to change their cgroup base folder. A cpu burner script is run in each container and some cpu related limits are activated by manipulating directly the cgroup filesystem. Then, the last container is created using the  `--cpuset-cpus` flag to bind its execution to processor number 3. This time, the container base cgroup folder is the default one. The burner script is run in this last container, and later some cpu limits are set through the `docker update` command. This last example shows that the docker CLI commands manipulate the cgroup hierarchy identically to what one could do manually, as with the first two containers. Lastly, the script kills all three containers and performs a cleanup.

---

## Instructions

First, the docker tool must be installed. This can be done using:
```
sudo apt-get install docker
```

Then, the <em>tmux</em> and <em>htop</em> packages must be installed through the following commands:
```
sudo apt install tmux
```
```
sudo apt install htop
```

The `container_runner.sh` script must be run inside this folder using `tmux` **without** root privileges:
```
sudo ./container_runner.sh
``` 
